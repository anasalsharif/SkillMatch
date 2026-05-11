require('dotenv').config();

const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');

const Application = require('../models/Application');
const FreelancePost = require('../models/FreeLance');
const Job = require('../models/Job');
const JobMatch = require('../models/jobMatch');
const Location = require('../models/Location');
const Message = require('../models/Message');
const Organization = require('../models/Organization');
const Post = require('../models/posts');
const Rating = require('../models/rating');
const Skills = require('../models/Skills');
const User = require('../models/User');
const {
  AllPrivateUserNotification,
  GlobalNotification,
  orgNotification,
} = require('../models/Notifications');

const password = '123456';
const demoEmails = [
  'admin@admin.com',
  'jobseeker@demo.com',
  'freelancer@demo.com',
  'designer@demo.com',
  'developer@demo.com',
  'organization@demo.com',
  'healthorg@demo.com',
];

const avatar = (name, background, color = 'ffffff') =>
  `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=${background}&color=${color}&bold=true`;

function setUpdate(doc) {
  return { $set: doc };
}

async function upsertUser(doc) {
  return User.findOneAndUpdate(
    { email: doc.email },
    setUpdate(doc),
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

async function upsertOrganization(doc) {
  return Organization.findOneAndUpdate(
    { email: doc.email },
    setUpdate(doc),
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

async function resetDemoContent() {
  const demoUsernames = ['admin', 'jobseeker', 'freelancer', 'designer', 'developer', 'demoorg', 'healthorg'];

  await Promise.all([
    Job.deleteMany({
      $or: [
        { category: /^Demo:/ },
        { title: /^Capstone Demo/ },
      ],
    }),
    Post.deleteMany({ username: { $in: demoUsernames } }),
    FreelancePost.deleteMany({ username: { $in: demoUsernames } }),
    Application.deleteMany({ username: { $in: demoUsernames } }),
    JobMatch.deleteMany({}),
    Message.deleteMany({ message: /^Demo:/ }),
    GlobalNotification.deleteMany({ title: /^Demo:/ }),
    AllPrivateUserNotification.deleteMany({ title: /^Demo:/ }),
    orgNotification.deleteMany({ title: /^Demo:/ }),
  ]);
}

async function main() {
  if (!process.env.MONGO_URI || process.env.MONGO_URI.includes('<')) {
    throw new Error('Set MONGO_URI in .env before seeding demo data.');
  }

  await mongoose.connect(process.env.MONGO_URI);
  const hashedPassword = await bcrypt.hash(password, 10);

  await resetDemoContent();

  const admin = await upsertUser({
    name: 'Admin User',
    username: 'admin',
    email: 'admin@admin.com',
    phone: '0000000000',
    password: hashedPassword,
    role: 'admin',
    isVerified: true,
    date: new Date('2000-01-01'),
    country: 'United States',
    city: 'Dallas',
    gender: 'Other',
    online: false,
    lastSeen: new Date(),
    socketIds: [],
    fcmTokens: [],
    notificationSettings: { chat: true, calls: true },
    avatarUrl: avatar('Admin User', '2f3a4a'),
  });

  const jobSeeker = await upsertUser({
    name: 'Maya Johnson',
    username: 'jobseeker',
    email: 'jobseeker@demo.com',
    phone: '1111111111',
    password: hashedPassword,
    role: 'Job Seeker',
    isVerified: true,
    date: new Date('2001-01-01'),
    country: 'United States',
    city: 'Dallas',
    gender: 'Other',
    online: false,
    lastSeen: new Date(),
    socketIds: [],
    fcmTokens: [],
    notificationSettings: { chat: true, calls: true },
    avatarUrl: avatar('Maya Johnson', '2563eb'),
    cvUrl: 'https://storage.googleapis.com/skillmatch-bucket/demo/maya-johnson-cv.pdf',
    analyzedCV: 'https://storage.googleapis.com/skillmatch-bucket/demo/maya-johnson-analysis.json',
    followers: ['demoorg'],
    following: ['freelancer', 'demoorg'],
  });

  const freelancer = await upsertUser({
    name: 'Omar Haddad',
    username: 'freelancer',
    email: 'freelancer@demo.com',
    phone: '2222222222',
    password: hashedPassword,
    role: 'Freelancer',
    isVerified: true,
    date: new Date('1999-04-12'),
    country: 'United States',
    city: 'Austin',
    gender: 'Other',
    online: false,
    lastSeen: new Date(),
    socketIds: [],
    fcmTokens: [],
    notificationSettings: { chat: true, calls: true },
    avatarUrl: avatar('Omar Haddad', '0f766e'),
    followers: ['jobseeker', 'demoorg'],
    following: ['developer'],
  });

  const designer = await upsertUser({
    name: 'Lina Patel',
    username: 'designer',
    email: 'designer@demo.com',
    phone: '3333333333',
    password: hashedPassword,
    role: 'Freelancer',
    isVerified: true,
    date: new Date('1998-08-20'),
    country: 'United States',
    city: 'Seattle',
    gender: 'Other',
    online: false,
    lastSeen: new Date(),
    socketIds: [],
    fcmTokens: [],
    notificationSettings: { chat: true, calls: true },
    avatarUrl: avatar('Lina Patel', '9333ea'),
    followers: ['jobseeker'],
    following: ['demoorg'],
  });

  const developer = await upsertUser({
    name: 'Noah Smith',
    username: 'developer',
    email: 'developer@demo.com',
    phone: '4444444444',
    password: hashedPassword,
    role: 'Job Seeker',
    isVerified: true,
    date: new Date('1997-03-18'),
    country: 'United States',
    city: 'Chicago',
    gender: 'Other',
    online: false,
    lastSeen: new Date(),
    socketIds: [],
    fcmTokens: [],
    notificationSettings: { chat: true, calls: true },
    avatarUrl: avatar('Noah Smith', 'ea580c'),
    followers: ['freelancer'],
    following: ['demoorg', 'healthorg'],
  });

  const org = await upsertOrganization({
    name: 'SkillMatch Demo Organization',
    username: 'demoorg',
    industry: 'Technology',
    websiteURL: 'https://example.com',
    country: 'United States',
    address1: '123 Demo Street',
    address2: 'Suite 400',
    email: 'organization@demo.com',
    password: hashedPassword,
    isVerified: true,
    role: 'Organization',
    fcmTokens: [],
    avatarUrl: avatar('SkillMatch Demo Organization', '111827'),
    followers: ['jobseeker', 'freelancer', 'developer'],
    following: ['jobseeker'],
  });

  const healthOrg = await upsertOrganization({
    name: 'CareBridge Health',
    username: 'healthorg',
    industry: 'Healthcare',
    websiteURL: 'https://carebridge.example.com',
    country: 'United States',
    address1: '88 Wellness Avenue',
    address2: '',
    email: 'healthorg@demo.com',
    password: hashedPassword,
    isVerified: true,
    role: 'Organization',
    fcmTokens: [],
    avatarUrl: avatar('CareBridge Health', '047857'),
    followers: ['developer'],
    following: [],
  });

  await Skills.deleteMany({ userId: { $in: [jobSeeker._id, freelancer._id, designer._id, developer._id] } });
  await Skills.insertMany([
    {
      userId: jobSeeker._id,
      education: ['B.S. Information Systems'],
      skills: ['JavaScript', 'React', 'Flutter', 'MongoDB', 'UI Testing'],
      experience: ['Built student marketplace prototype', 'Completed mobile app QA internship'],
      certifications: ['Google UX Design Foundations'],
      languages: ['English', 'Arabic'],
      summary: 'Entry-level product-minded developer looking for frontend and QA roles.',
    },
    {
      userId: freelancer._id,
      education: ['B.A. Digital Media'],
      skills: ['Brand Design', 'Figma', 'Landing Pages', 'Copywriting', 'Client Communication'],
      experience: ['Delivered 20+ freelance landing pages', 'Designed pitch decks for startups'],
      certifications: ['Figma UI Design'],
      languages: ['English'],
      summary: 'Freelance designer focused on clean conversion-oriented web experiences.',
    },
    {
      userId: designer._id,
      education: ['M.S. Human-Computer Interaction'],
      skills: ['UX Research', 'Wireframes', 'Design Systems', 'Accessibility', 'Prototyping'],
      experience: ['Led redesign for nonprofit portal', 'Created accessible design system'],
      certifications: ['WCAG Accessibility Basics'],
      languages: ['English', 'Hindi'],
      summary: 'UX designer specializing in accessible workflows for web and mobile.',
    },
    {
      userId: developer._id,
      education: ['B.S. Computer Science'],
      skills: ['Node.js', 'Express', 'MongoDB', 'REST APIs', 'Firebase'],
      experience: ['Built REST APIs for capstone projects', 'Integrated Firebase messaging'],
      certifications: ['MongoDB Node.js Developer Path'],
      languages: ['English', 'Spanish'],
      summary: 'Backend-leaning developer interested in API and cloud integrations.',
    },
  ]);

  const jobs = await Job.insertMany([
    {
      title: 'Junior Flutter Developer',
      description: 'Build and polish cross-platform screens for a growing skill-matching platform.',
      location: 'Remote',
      salary: '$65,000 - $78,000',
      jobType: 'Remote',
      category: 'Demo: Software',
      deadline: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30),
      requirements: ['Flutter', 'REST APIs', 'Git', 'UI debugging'],
      responsibilities: ['Implement app screens', 'Fix frontend bugs', 'Collaborate with backend developers'],
      companyId: org._id,
    },
    {
      title: 'Backend API Intern',
      description: 'Support Express and MongoDB APIs for job applications and matching features.',
      location: 'Dallas, TX',
      salary: '$24/hr',
      jobType: 'Internship',
      category: 'Demo: Software',
      deadline: new Date(Date.now() + 1000 * 60 * 60 * 24 * 21),
      requirements: ['Node.js', 'MongoDB', 'JWT', 'API testing'],
      responsibilities: ['Write endpoints', 'Improve schemas', 'Test auth and application flows'],
      companyId: org._id,
    },
    {
      title: 'UX Research Assistant',
      description: 'Interview users and improve onboarding for healthcare staffing workflows.',
      location: 'Seattle, WA',
      salary: '$30/hr',
      jobType: 'Part-Time',
      category: 'Demo: Design',
      deadline: new Date(Date.now() + 1000 * 60 * 60 * 24 * 45),
      requirements: ['UX Research', 'Interviewing', 'Accessibility', 'Figma'],
      responsibilities: ['Run user interviews', 'Summarize findings', 'Prototype workflow improvements'],
      companyId: healthOrg._id,
    },
  ]);

  await Location.findOneAndUpdate(
    { companyId: org._id },
    setUpdate({ companyId: org._id, lat: 32.7767, lng: -96.7970 }),
    { upsert: true, new: true },
  );
  await Location.findOneAndUpdate(
    { companyId: healthOrg._id },
    setUpdate({ companyId: healthOrg._id, lat: 47.6062, lng: -122.3321 }),
    { upsert: true, new: true },
  );

  await Application.insertMany([
    {
      userId: jobSeeker._id,
      username: jobSeeker.username,
      userName: jobSeeker.name,
      jobId: jobs[0]._id,
      jobTitle: jobs[0].title,
      organizationId: org._id,
      matchScore: 88,
    },
    {
      userId: developer._id,
      username: developer.username,
      userName: developer.name,
      jobId: jobs[1]._id,
      jobTitle: jobs[1].title,
      organizationId: org._id,
      matchScore: 94,
    },
    {
      userId: designer._id,
      username: designer.username,
      userName: designer.name,
      jobId: jobs[2]._id,
      jobTitle: jobs[2].title,
      organizationId: healthOrg._id,
      matchScore: 91,
    },
  ]);

  await JobMatch.insertMany([
    { userId: jobSeeker._id, jobId: jobs[0]._id, matchScore: 88 },
    { userId: jobSeeker._id, jobId: jobs[1]._id, matchScore: 73 },
    { userId: developer._id, jobId: jobs[1]._id, matchScore: 94 },
    { userId: designer._id, jobId: jobs[2]._id, matchScore: 91 },
  ]);

  await Post.insertMany([
    {
      author: jobSeeker.name,
      username: jobSeeker.username,
      avatarUrl: jobSeeker.avatarUrl,
      content: 'Excited to use SkillMatch Platform to find junior Flutter and QA opportunities.',
      likes: [freelancer.username, org.username],
      comments: [{ text: 'Your Flutter portfolio looks strong.', author: org.name }],
    },
    {
      author: freelancer.name,
      username: freelancer.username,
      avatarUrl: freelancer.avatarUrl,
      content: 'Available this month for landing pages, pitch decks, and quick product mockups.',
      likes: [jobSeeker.username, designer.username],
      comments: [{ text: 'Would love to collaborate on a design sprint.', author: designer.name }],
    },
    {
      author: org.name,
      username: org.username,
      avatarUrl: org.avatarUrl,
      content: 'We just opened two demo roles for developers interested in matching platforms.',
      likes: [jobSeeker.username, developer.username],
      comments: [{ text: 'Applied to the backend internship.', author: developer.name }],
    },
  ]);

  await FreelancePost.insertMany([
    {
      username: freelancer.username,
      content: 'I can design a responsive portfolio or startup landing page in one week.',
      date: new Date().toISOString(),
      userId: String(freelancer._id),
    },
    {
      username: designer.username,
      content: 'Offering UX audit packages for onboarding flows and accessibility fixes.',
      date: new Date().toISOString(),
      userId: String(designer._id),
    },
  ]);

  await Rating.deleteMany({
    userName: { $in: [freelancer.username, designer.username, org.username, healthOrg.username] },
  });
  await Rating.insertMany([
    {
      userId: String(freelancer._id),
      userName: freelancer.username,
      type: 'User',
      rating: 4.8,
      count: 5,
      users: [String(jobSeeker._id), String(developer._id)],
    },
    {
      userId: String(designer._id),
      userName: designer.username,
      type: 'User',
      rating: 4.6,
      count: 3,
      users: [String(jobSeeker._id)],
    },
    {
      userId: String(org._id),
      userName: org.username,
      type: 'Organization',
      rating: 4.7,
      count: 4,
      users: [String(jobSeeker._id), String(developer._id)],
    },
  ]);

  await Message.insertMany([
    {
      senderId: org._id,
      receiverId: jobSeeker._id,
      message: 'Demo: Hi Maya, your Flutter profile is a strong match for our junior role.',
      timestamp: new Date(Date.now() - 1000 * 60 * 45),
      isRead: true,
    },
    {
      senderId: jobSeeker._id,
      receiverId: org._id,
      message: 'Demo: Thank you. I uploaded my CV and applied through SkillMatch.',
      timestamp: new Date(Date.now() - 1000 * 60 * 38),
      isRead: true,
    },
    {
      senderId: org._id,
      receiverId: jobSeeker._id,
      message: 'Demo: Great. We can discuss Flutter, REST APIs, and UI polish in the interview.',
      timestamp: new Date(Date.now() - 1000 * 60 * 22),
      isRead: false,
    },
    {
      senderId: developer._id,
      receiverId: org._id,
      message: 'Demo: I applied for the Backend API Intern role and can discuss MongoDB integration.',
      timestamp: new Date(Date.now() - 1000 * 60 * 18),
      isRead: false,
    },
  ]);

  await Promise.all([
    GlobalNotification.create({
      senderId: org._id,
      title: 'Demo: New role posted',
      body: 'SkillMatch Demo Organization posted Junior Flutter Developer.',
      jobId: jobs[0]._id,
    }),
    AllPrivateUserNotification.create({
      userId: jobSeeker._id,
      sender: org.username,
      receiver: jobSeeker.username,
      title: 'Demo: Application received',
      body: 'Your application for Junior Flutter Developer was received.',
      jobId: jobs[0]._id,
    }),
    orgNotification.create({
      orgId: org._id,
      sender: developer.username,
      receiver: org.username,
      title: 'Demo: New applicant',
      body: 'Noah Smith applied to Backend API Intern.',
      jobId: jobs[1]._id,
    }),
  ]);

  console.log(JSON.stringify({
    password,
    accounts: demoEmails.map((email) => ({ email, password })),
    counts: {
      users: await User.countDocuments({ email: { $in: demoEmails } }),
      organizations: await Organization.countDocuments({ email: { $in: demoEmails } }),
      jobs: await Job.countDocuments({ category: /^Demo:/ }),
      applications: await Application.countDocuments({ username: { $in: ['jobseeker', 'developer', 'designer'] } }),
      posts: await Post.countDocuments({ username: { $in: ['jobseeker', 'freelancer', 'demoorg'] } }),
      freelancePosts: await FreelancePost.countDocuments({ username: { $in: ['freelancer', 'designer'] } }),
    },
    sampleJobIds: jobs.map((job) => ({ title: job.title, id: job._id })),
    adminId: admin._id,
  }, null, 2));

  await mongoose.disconnect();
}

main().catch(async (error) => {
  console.error(error);
  try {
    await mongoose.disconnect();
  } catch (_) {
    // Ignore disconnect errors during failed seeding.
  }
  process.exit(1);
});
