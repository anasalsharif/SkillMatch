const { OpenAI } = require('openai');

const GEMINI_OPENAI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/openai/';

function hasUsableValue(value) {
  return Boolean(
    value &&
    !value.includes('your-openai-key') &&
    !value.includes('replace-me') &&
    !value.includes('your-gemini-key') &&
    !value.includes('<')
  );
}

const provider = (process.env.AI_PROVIDER || '').toLowerCase();
const geminiApiKey =
  process.env.GEMINI_API_KEY ||
  process.env.GeminiApikey ||
  process.env.GEMINI_APIKEY ||
  process.env.GEMINI_KEY;
const openAiApiKey = process.env.OPENAI_API_KEY;
const modelFromEnv = process.env.OPENAI_MODEL || process.env.GEMINI_MODEL;
const openAiKeyLooksLikeGemini = (openAiApiKey || '').startsWith('AIza');
const shouldUseGemini =
  provider === 'gemini' ||
  hasUsableValue(geminiApiKey) ||
  openAiKeyLooksLikeGemini ||
  (modelFromEnv || '').toLowerCase().startsWith('gemini');

const configuredApiKey = shouldUseGemini && hasUsableValue(geminiApiKey)
  ? geminiApiKey
  : openAiApiKey;

const isConfigured = Boolean(
  hasUsableValue(configuredApiKey)
);

const openai = new OpenAI({
  apiKey: isConfigured ? configuredApiKey : 'sk-demo-disabled',
  baseURL: shouldUseGemini
    ? (process.env.GEMINI_BASE_URL || GEMINI_OPENAI_BASE_URL)
    : (process.env.OPENAI_BASE_URL || undefined),
});

openai.isConfigured = () => isConfigured;
openai.model = shouldUseGemini
  ? (process.env.GEMINI_MODEL || (modelFromEnv || '').startsWith('gemini') && modelFromEnv || 'gemini-2.5-flash')
  : (modelFromEnv || 'gpt-4o');
openai.provider = shouldUseGemini ? 'gemini' : 'openai-compatible';

module.exports = openai;
