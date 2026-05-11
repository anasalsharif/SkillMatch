const nodemailer = require("nodemailer");

const hasEmailConfig = () => Boolean(
  process.env.EMAIL_USER &&
  process.env.EMAIL_PASS &&
  !process.env.EMAIL_USER.includes("your") &&
  !process.env.EMAIL_PASS.includes("your")
);

const sendEmail = async (to, subject, text) => {
  try {
    if (!hasEmailConfig()) {
      console.warn(`[Email disabled] ${subject} for ${to}. Content: ${text}`);
      return { skipped: true };
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      },
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to,
      subject,
      text,
    };

    await transporter.sendMail(mailOptions);
    console.log("Email sent successfully");
    return { sent: true };
  } catch (error) {
    console.error("Error sending email:", error);
    return { sent: false, error: error.message };
  }
};

module.exports = sendEmail;
