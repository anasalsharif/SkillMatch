const { OpenAI } = require('openai');

const configuredApiKey = process.env.OPENAI_API_KEY;
const isConfigured = Boolean(
  configuredApiKey &&
  !configuredApiKey.includes('your-openai-key') &&
  !configuredApiKey.includes('replace-me')
);

const openai = new OpenAI({
  apiKey: isConfigured ? configuredApiKey : 'sk-demo-disabled',
  baseURL: process.env.OPENAI_BASE_URL || undefined,
});

openai.isConfigured = () => isConfigured;
openai.model = process.env.OPENAI_MODEL || 'gpt-4o';

module.exports = openai;
