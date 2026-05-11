const Job = require('../models/Job');
const Organaization = require('../models/Organization');
const User = require('../models/User');
const Skills = require('../models/Skills');
const JobMatch = require('../models/jobMatch');
const extractTextFromGCS = require('../utils/extractTextFromGCS');
const { uploadToGCS, bucket } = require('../utils/gcsUploader');
const openai = require('../utils/openaiClient');
const path = require('path');
const fs = require("fs");
const { UserNotification, GlobalNotification } = require("../models/Notifications");
const { sendJobNotification } = require('../services/firebaseAdmin');

const VALID_JOB_TYPES = ["Full-Time", "Part-Time", "Remote", "Internship", "Contract"];
const COMMON_WORDS = new Set([
  "and", "or", "the", "a", "an", "to", "of", "in", "for", "with", "on", "at", "by",
  "from", "is", "are", "be", "as", "this", "that", "you", "your", "our", "we"
]);

const normalizeList = (value) => {
  if (!value) return [];
  if (Array.isArray(value)) return value.filter(Boolean).map(String);
  return String(value).split(/[,;\n]/).map((item) => item.trim()).filter(Boolean);
};

const cleanTerms = (values) => normalizeList(values)
  .flatMap((value) => value.toLowerCase().split(/[^a-z0-9+#.]+/))
  .map((term) => term.trim())
  .filter((term) => term.length > 1 && !COMMON_WORDS.has(term));

const localMatchScore = (userSkills, job) => {
  const candidateTerms = new Set(cleanTerms([
    ...(userSkills.skills || []),
    ...(userSkills.experience || []),
    ...(userSkills.education || []),
    ...(userSkills.certifications || []),
    ...(userSkills.languages || []),
    userSkills.summary || ""
  ]));

  if (!candidateTerms.size) return 0;

  const requiredTerms = cleanTerms(job.requirements || []);
  const jobTerms = cleanTerms([
    job.title,
    job.description,
    job.category,
    ...(job.responsibilities || [])
  ]);

  const scoreTerms = [...new Set([...requiredTerms, ...jobTerms])];
  if (!scoreTerms.length) return 45;

  const requiredMatches = requiredTerms.filter((term) => candidateTerms.has(term)).length;
  const overallMatches = scoreTerms.filter((term) => candidateTerms.has(term)).length;
  const requiredScore = requiredTerms.length ? (requiredMatches / requiredTerms.length) * 60 : 20;
  const overallScore = (overallMatches / scoreTerms.length) * 35;
  const profileCompleteness = Math.min(candidateTerms.size / 12, 1) * 5;

  return Math.max(0, Math.min(100, Math.round(requiredScore + overallScore + profileCompleteness)));
};

const getSectionLines = (text, labels) => {
  const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  const labelPattern = labels.join("|");
  const result = [];

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const inlineMatch = line.match(new RegExp(`^(${labelPattern})\\s*[:\\-]\\s*(.+)$`, "i"));
    if (inlineMatch) {
      result.push(...normalizeList(inlineMatch[2]));
      continue;
    }

    if (new RegExp(`^(${labelPattern})\\s*[:\\-]?$`, "i").test(line)) {
      for (let next = index + 1; next < lines.length; next += 1) {
        if (/^[A-Za-z ]{3,25}\s*[:\-]?$/.test(lines[next]) && !/^[-*]/.test(lines[next])) break;
        result.push(lines[next].replace(/^[-*]\s*/, ""));
      }
    }
  }

  return result;
};

const firstMatch = (text, regex, fallback = "") => {
  const match = text.match(regex);
  return match ? match[1].trim() : fallback;
};

const inferJobType = (text) => {
  const lower = text.toLowerCase();
  if (lower.includes("part-time") || lower.includes("part time")) return "Part-Time";
  if (lower.includes("remote")) return "Remote";
  if (lower.includes("intern")) return "Internship";
  if (lower.includes("contract")) return "Contract";
  return "Full-Time";
};

const normalizeJobData = (jobData, sourceText = "") => {
  const fallbackTitle = sourceText.split(/\r?\n/).map((line) => line.trim()).find(Boolean) || "Untitled Job";
  const deadline = jobData.deadline ? new Date(jobData.deadline) : null;

  return {
    title: jobData.title || firstMatch(sourceText, /(?:job title|title)\s*[:\-]\s*(.+)/i, fallbackTitle),
    description: jobData.description || firstMatch(sourceText, /(?:description|overview)\s*[:\-]\s*(.+)/i, sourceText.slice(0, 500)),
    location: jobData.location || firstMatch(sourceText, /(?:location)\s*[:\-]\s*(.+)/i, "Not specified"),
    salary: jobData.salary || firstMatch(sourceText, /(?:salary|compensation)\s*[:\-]\s*(.+)/i, "Not specified"),
    jobType: VALID_JOB_TYPES.includes(jobData.jobType) ? jobData.jobType : inferJobType(sourceText),
    category: jobData.category || firstMatch(sourceText, /(?:category|department|field)\s*[:\-]\s*(.+)/i, "Technology"),
    deadline: deadline && !isNaN(deadline.getTime())
      ? deadline.toISOString()
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    requirements: normalizeList(jobData.requirements).length
      ? normalizeList(jobData.requirements)
      : getSectionLines(sourceText, ["requirements", "required skills", "qualifications"]).slice(0, 12),
    responsibilities: normalizeList(jobData.responsibilities).length
      ? normalizeList(jobData.responsibilities)
      : getSectionLines(sourceText, ["responsibilities", "duties", "tasks"]).slice(0, 12),
  };
};

const parseJobFromText = (text) => normalizeJobData({}, text);

const getJobById = async (req, res) => {
    try {
        const {  jobId } = req.params;

      

        const job = await Job.findOne({  _id: jobId });
        if (!job) {
            return res.status(404).json({ message: "no job found  " });
        }

        console.log("📦 Job found:", job);
        return res.status(200).json(job);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

const getOrgJobs = async (req, res) => {  
    try {
      if (!req.user) {
        return res.status(401).json({ message: "Unauthorized: No user info in token" });
      }
  
      const organaizationId = req.user.id;  
      const organaization = await Organaization.findById(organaizationId);
      if (!organaization) {
        console.log("❌ Organization not found with ID:", organaizationId);
        return res.status(404).json({ message: "Organization Not found" });
      }
  
      console.log("✅ Organization found:", organaization.name || organaization._id);
  
      const jobs = await Job.find({ companyId: organaizationId }).sort({ deadline: -1 });
      console.log("📦 Jobs found:", jobs.length);
  
      return res.status(200).json(jobs);
  
    } catch (error) {
      console.error("🔥 Server error in getOrgJobs:", error);
      return res.status(500).json({ message: 'Error fetching jobs' });
    }
  };

const getAllJobs = async (req,res) => {
    try {
        const jobs = await Job.find().sort({createdAt : -1});
        if(!jobs){
            return res.status(204).json({message: "No Available Jobs rigte Now"});
        }
        return res.status(200).json(jobs);
    } catch (error) {
        return res.status(500).json({ message: 'Error fetching jobs' });
    }
}

const getAllJobsUser = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);
    if (!user) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const userSkills = await Skills.findOne({ userId });
    const jobs = await Job.find().sort({ createdAt: -1 });

    if (!jobs.length) {
      return res.status(204).json({ message: "No Available Jobs right Now" });
    }

    if (!userSkills || !userSkills.skills.length) {
      return res.status(200).json(jobs);
    }

    const userProfileText = `
      Skills: ${userSkills.skills.join(", ")}
      Experience: ${userSkills.experience?.join(", ")}
      Education: ${userSkills.education?.join(", ")}
      Certifications: ${userSkills.certifications?.join(", ")}
      Languages: ${userSkills.languages?.join(", ")}
      Summary: ${userSkills.summary || ""}
    `;

    const scoredJobs = [];

    for (const job of jobs) {
      // 👉 First check if a match score already exists
      const existingMatch = await JobMatch.findOne({ userId, jobId: job._id });

      let matchScorePercentage = existingMatch
        ? existingMatch.matchScore
        : localMatchScore(userSkills, job);

      if (!existingMatch && openai.isConfigured()) {
        const jobText = `
          Title: ${job.title}
          Description: ${job.description}
          Requirements: ${job.requirements?.join(", ")}
          Responsibilities: ${job.responsibilities?.join(", ")}
          Category: ${job.category}
          Location: ${job.location}
          Salary: ${job.salary}
          Type: ${job.jobType}
        `;

        const prompt = `
You are an AI that matches job seekers with jobs.
Given the following candidate profile and job posting, score the match from 0 to 100, where:
- 100 means perfect fit
- 0 means no fit
Only respond with the number.

Candidate Profile:
${userProfileText}

Job Posting:
${jobText}

Match Score:
        `;

        try {
          const response = await openai.chat.completions.create({
            model: openai.model,
            messages: [
              { role: "system", content: "You are a helpful assistant that scores job fit based on provided information." },
              { role: "user", content: prompt }
            ],
            temperature: 0.2,
            max_tokens: 10,
          });

          const completionText = response.choices[0].message.content.trim();
          matchScorePercentage = parseFloat(completionText);

          if (isNaN(matchScorePercentage)) {
            matchScorePercentage = localMatchScore(userSkills, job);
          }

          // 👉 Save the new match score
        } catch (apiError) {
          console.warn("OpenAI match scoring unavailable; using local scoring:", apiError.message);
          matchScorePercentage = localMatchScore(userSkills, job);
        }
      }

      if (!existingMatch) {
        await JobMatch.findOneAndUpdate(
          { userId, jobId: job._id },
          { matchScore: matchScorePercentage, createdAt: new Date() },
          { upsert: true, new: true }
        );
      }

      scoredJobs.push({
        ...job.toObject(),
        matchScore: matchScorePercentage,
      });
    }

    scoredJobs.sort((a, b) => b.matchScore - a.matchScore);

    return res.status(200).json(scoredJobs);

  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Error fetching jobs' });
  }
};



///////////////

///here 
const addJob = async (req,res) => {
    console.log("Reach Add Job");
    try {
        const {
            title,
            description,
            location,
            salary,
            jobType,
            category,
            deadline,
            requirements,
            responsibilities,
          } = req.body;
        const organaizationId = req.user.id;
        const organaization = await Organaization.findById(organaizationId);
        if(!organaization){
            return res.status(404).json({ message: "Organization Not found"});
        }
        const newJob = new Job({
            title,
            description,
            location,
            salary,
            jobType,
            category,
            deadline,
            requirements,
            responsibilities,
            companyId: organaizationId
          });
          console.log(newJob);
          await newJob.save();

        const users = await User.find({},'fcmTokens');
        const tokens = users.map(user => user.fcmTokens).filter(Boolean);

        // Save notification to database
        const notification = new GlobalNotification({
            
            title: `New Job: ${title}`,
            body: `Posted by ${organaization.name}`,
            companyId: organaizationId,
            jobId: newJob._id
        });
        await notification.save();

        // Send job notification
        sendJobNotification(tokens, title, organaization.name,newJob._id);

///////////////////////////////
          
          return res.status(201).json({message:"Job Created Successfully", job: newJob});
    } catch (error) {
        console.log("Server Error: " + error)
        return res.status(500).json({ message: 'Server error while adding job'});
    }
}

const deleteJob = async (req, res) => {
    try {
      const jobId = req.query.jobId;
      const organizationId = req.user.id;
  
      if (!jobId) {
        return res.status(400).json({ message: "Job ID is required in query parameters." });
      }
  
      const job = await Job.findOneAndDelete({
        _id: jobId,
        companyId: organizationId,
      });
  
      if (!job) {
        return res.status(404).json({ message: "Job not found or you're not authorized to delete it." });
      }
  
      return res.status(200).json({ message: "Job deleted successfully", deletedJob: job });
    } catch (error) {
      console.error("❌ Error deleting job:", error);
      return res.status(500).json({ message: "Server error while deleting job" });
    }
  };


const updateJob = async (req, res) => {
    try {
        const jobId = req.query.jobId;
        const organaizationId = req.user.id;

        const job = await Job.findOneAndUpdate(
            { _id: jobId, companyId: organaizationId },
            req.body,
            { new: true }
        );

        if (!job) {
            return res.status(404).json({ message: "Job not found or unauthorized" });
        }

        return res.status(200).json({ message: "Job updated successfully", job });
    } catch (error) {
        return res.status(500).json({ message: "Error updating job" });
    }
};
/////////////////////here also // make unreadcount // notfications / //logOut->saadeh// save sign in 
const smartAddJobLegacy = async (req, res) => {
  try {
    const organaizationId = req.user.id;
    const file = req.file;
    const rawText = req.body?.text;

    let extractedText = '';

    if (rawText) {
      extractedText = rawText;
    } else if (file) {
      const ext = path.extname(file.originalname).toLowerCase();

      if (ext === '.txt') {
        extractedText = file.buffer
          ? file.buffer.toString('utf-8')
          : fs.readFileSync(file.path, 'utf-8');
      } else if (ext === '.pdf') {
        if (!bucket) {
          return res.status(400).json({
            message: "PDF smart extraction needs Google Cloud OCR. Paste the job text or upload a .txt file for demo mode.",
          });
        }

        const gcsUrl = await uploadToGCS(file, "job-files");
        const gcsUri = `gs://${bucket.name}/${gcsUrl.split(`https://storage.googleapis.com/${bucket.name}/`)[1]}`;
        extractedText = await extractTextFromGCS(gcsUri);
        if (!extractedText) throw new Error("OCR failed to extract any text.");
      } else {
        return res.status(400).json({ message: "Unsupported file format. Only .txt or .pdf allowed." });
      }
    } else {
      return res.status(400).json({ message: "No text or file provided" });
    }

    // Create prompt for AI
    const prompt = `
Extract job information from the following text and return ONLY a valid JSON object. Do not include any explanatory text, comments, or markdown formatting. Return only the raw JSON.

Required JSON structure:
{
  "title": "string",
  "description": "string",
  "location": "string",
  "salary": "string",
  "jobType": "Full-Time",
  "category": "string",
  "deadline": "2024-12-31T23:59:59.000Z",
  "requirements": ["requirement1", "requirement2"],
  "responsibilities": ["responsibility1", "responsibility2"]
}

Rules:
- jobType must be one of: "Full-Time", "Part-Time", "Remote", "Internship", "Contract"
- deadline must be a valid ISO date string
- If information is missing, make reasonable assumptions
- Return ONLY valid JSON, no other text

Job description text:
${extractedText}
`;

    const completion = await openai.chat.completions.create({
      model: openai.model,
      messages: [
        { 
          role: "system", 
          content: "You are a JSON extraction tool. You must return only valid JSON objects with no additional text, explanations, or formatting." 
        },
        { 
          role: "user", 
          content: prompt 
        }
      ],
      temperature: 0.1,
    });

    let responseContent = completion.choices[0].message.content.trim();
    
    // Try to extract JSON if the response contains extra text
    let jobData;
    try {
      // First try direct parsing
      jobData = JSON.parse(responseContent);
    } catch (firstError) {
      try {
        // Try to find JSON within the response
        const jsonMatch = responseContent.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          jobData = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error("No JSON object found in response");
        }
      } catch (secondError) {
        console.error("❌ Failed to parse AI response:", responseContent);
        return res.status(500).json({ 
          message: "AI returned invalid response format", 
          error: "Could not extract valid job data from AI response" 
        });
      }
    }

    // Validate required fields
    const requiredFields = ['title', 'description', 'location', 'salary', 'jobType', 'category'];
    const missingFields = requiredFields.filter(field => !jobData[field]);
    
    if (missingFields.length > 0) {
      return res.status(400).json({ 
        message: "AI extraction incomplete", 
        error: `Missing required fields: ${missingFields.join(', ')}` 
      });
    }

    // Validate jobType
    const validJobTypes = ["Full-Time", "Part-Time", "Remote", "Internship", "Contract"];
    if (!validJobTypes.includes(jobData.jobType)) {
      jobData.jobType = "Full-Time"; // Default fallback
    }

    // Ensure arrays exist
    if (!Array.isArray(jobData.requirements)) {
      jobData.requirements = [];
    }
    if (!Array.isArray(jobData.responsibilities)) {
      jobData.responsibilities = [];
    }

    // Validate/fix deadline
    if (jobData.deadline) {
      const deadlineDate = new Date(jobData.deadline);
      if (isNaN(deadlineDate.getTime())) {
        // If invalid date, set to 30 days from now
        jobData.deadline = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      }
    } else {
      // Set default deadline to 30 days from now
      jobData.deadline = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    }

    const newJob = new Job({ ...jobData, companyId: organaizationId });
    await newJob.save();

    return res.status(201).json({ message: "Job created via AI", job: newJob });
  } catch (err) {
    console.error("Smart Add Job Error:", err);
    return res.status(500).json({ message: "Error creating job via AI", error: err.message });
  }
};

const smartAddJob = async (req, res) => {
  try {
    const organaizationId = req.user.id;
    const file = req.file;
    const rawText = req.body?.text;
    let extractedText = '';

    if (rawText && rawText.trim()) {
      extractedText = rawText.trim();
    } else if (file) {
      const ext = path.extname(file.originalname || '').toLowerCase();

      if (ext === '.txt') {
        extractedText = file.buffer
          ? file.buffer.toString('utf-8')
          : fs.readFileSync(file.path, 'utf-8');
      } else if (ext === '.pdf') {
        if (!bucket) {
          return res.status(400).json({
            message: "PDF smart extraction needs Google Cloud OCR. Paste the job text or upload a .txt file for demo mode.",
          });
        }

        const gcsUrl = await uploadToGCS(file, "job-files");
        const filePath = gcsUrl.split(`https://storage.googleapis.com/${bucket.name}/`)[1];
        extractedText = await extractTextFromGCS(`gs://${bucket.name}/${filePath}`);
      } else {
        return res.status(400).json({ message: "Unsupported file format. Only .txt or .pdf allowed." });
      }
    } else {
      return res.status(400).json({ message: "No text or file provided" });
    }

    if (!extractedText.trim()) {
      return res.status(400).json({ message: "No readable job text found." });
    }

    let jobData = parseJobFromText(extractedText);

    if (openai.isConfigured()) {
      const prompt = `
Extract job information from the following text and return only a valid JSON object:
{
  "title": "string",
  "description": "string",
  "location": "string",
  "salary": "string",
  "jobType": "Full-Time",
  "category": "string",
  "deadline": "2024-12-31T23:59:59.000Z",
  "requirements": ["requirement1"],
  "responsibilities": ["responsibility1"]
}

Job description text:
${extractedText}
`;

      try {
        const completion = await openai.chat.completions.create({
          model: openai.model,
          messages: [
            {
              role: "system",
              content: "You extract job postings into strict JSON. Return only a JSON object."
            },
            { role: "user", content: prompt }
          ],
          temperature: 0.1,
        });

        const responseContent = completion.choices[0].message.content.trim();
        const jsonMatch = responseContent.match(/\{[\s\S]*\}/);
        jobData = JSON.parse(jsonMatch ? jsonMatch[0] : responseContent);
      } catch (apiError) {
        console.warn("OpenAI job extraction unavailable; using local parser:", apiError.message);
      }
    }

    jobData = normalizeJobData(jobData, extractedText);
    const newJob = new Job({ ...jobData, companyId: organaizationId });
    await newJob.save();

    return res.status(201).json({ message: "Job created successfully", job: newJob });
  } catch (err) {
    console.error("Smart Add Job Error:", err.message);
    return res.status(500).json({ message: "Error creating job", error: err.message });
  }
};

module.exports = {getOrgJobs,getAllJobs,addJob,deleteJob,updateJob,smartAddJob, getAllJobsUser,getJobById}
