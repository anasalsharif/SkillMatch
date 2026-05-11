
const admin = require('firebase-admin');

let firebaseReady = false;
let warnedFirebaseDisabled = false;

try {
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (credentialsPath && !credentialsPath.includes('absolute\\path')) {
    admin.initializeApp({
      credential: admin.credential.cert(require(credentialsPath)),
    });
    firebaseReady = true;
    console.log('Firebase Admin initialized.');
  } else {
    console.warn('Firebase Admin disabled: GOOGLE_APPLICATION_CREDENTIALS is not set.');
  }
} catch (error) {
  console.warn(`Firebase Admin disabled: ${error.message}`);
}

function canSendNotifications() {
  if (!firebaseReady) {
    if (!warnedFirebaseDisabled) {
      console.warn('Push notifications disabled: Firebase Admin is not configured.');
      warnedFirebaseDisabled = true;
    }
    return false;
  }
  return true;
}

async function sendNotification(tokens, title, body, data) {
  if (!canSendNotifications()) return;
  if (!Array.isArray(tokens) || tokens.length === 0) {
    console.error("❌ Error: Tokens must be a non-empty array.");
    return;
  }

  for (const token of tokens) {
    const message = {
      notification: { title, body },
      data: data,
      token: token,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Notification sent:', response);
    } catch (error) {
      console.error(`❌ Error sending notification to ${token}:`, error.message);
    }
  }
}
async function sendJobNotification(tokens, title, company,jobId) {
  if (!canSendNotifications()) return;
  tokens = tokens.flat().filter((token) => typeof token === 'string' && token.length > 0);

  if (tokens.length === 0) {
    console.error("❌ Error: No valid tokens provided.");
    return;
  }

  for (const token of tokens) {
    const message = {
      notification: { title, body: `New job from ${company}` },
     data: { 
        type: 'job', 
        title: String(title), 
        company: String(company), 
        jobId: String(jobId)  // Convert jobId to a string
      },
      token: token,  
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Job notification sent successfully:', response);
    } catch (error) {
      console.error(`❌ Error sending job notification to ${token}:`, error.message);
    }
  }
}



async function sendMeetingNotification(token, meetingData) {
  if (!canSendNotifications()) return;
  if (typeof token !== 'string' || !token.trim()) {
    console.error('❌ Invalid FCM token provided');
    return;
  }

  const {senderName, title, scheduledDateTime, meetingId, meetingLink, organizationId } = meetingData;

  const message = {
    token, // ✅ must be a string
    notification: {
      title: 'Meeting Scheduled',
      body: `Your meeting with ${senderName} is scheduled for ${scheduledDateTime}`,
    },
    data: {
      type: 'meeting',
      meetingId: String(meetingId),
      meetingLink: String(meetingLink),
      scheduledDateTime: String(scheduledDateTime),
      organizationId: String(organizationId),
      title: String(title),
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Meeting notification sent:', response);
  } catch (error) {
    console.error('❌ Error sending meeting notification:', error.message);
  }
}

async function sendApplicantNotification(tokens, applicantData) {
  if (!canSendNotifications()) return;
  tokens = tokens.flat().filter(token => typeof token === 'string' && token.length > 0);

  if (tokens.length === 0) {
    console.error('❌ No valid FCM tokens provided for applicant notification.');
    return;
  }

  const { jobId, jobTitle, applicantName, applicantUsername, organizationId } = applicantData;

  for (const token of tokens) {
    const message = {
      token,
      notification: {
        title: `New Applicant for ${jobTitle}`,
        body: `${applicantName} has applied for your job.`,
      },
      data: {
        type: 'application',
        jobId: jobId,
        jobTitle: jobTitle,
        applicantName: applicantName,
        applicantUsername: applicantUsername,
        organizationId: organizationId
      }
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Applicant notification sent:', response);
    } catch (error) {
      console.error('❌ Error sending applicant notification:', error.message);
    }
  }
}

module.exports = { sendNotification,sendJobNotification,sendMeetingNotification,sendApplicantNotification };
