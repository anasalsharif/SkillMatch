const vision = require('@google-cloud/vision');
const { Storage } = require('@google-cloud/storage');
const { v4: uuidv4 } = require('uuid');

const configuredKeyFile = process.env.GCS_KEY_FILE || process.env.GOOGLE_APPLICATION_CREDENTIALS;
const keyFilename = configuredKeyFile && !configuredKeyFile.includes('absolute\\path')
  ? configuredKeyFile
  : undefined;
const bucketName = process.env.GCS_BUCKET;

// Auth clients
const visionClient = keyFilename
  ? new vision.ImageAnnotatorClient({ keyFilename, fallback: true })
  : new vision.ImageAnnotatorClient({ fallback: true });

const storage = keyFilename ? new Storage({ keyFilename }) : new Storage();

// OCR function
const extractTextFromGCS = async (gcsUri) => {
  try {
    console.log("Starting OCR for URI:", gcsUri);

    const outputPrefix = `ocr-results/${uuidv4()}/`;
    if (!bucketName) {
      throw new Error('GCS_BUCKET is not configured.');
    }

    const outputUri = `gs://${bucketName}/${outputPrefix}`;

    const request = {
      requests: [
        {
          inputConfig: {
            gcsSource: {
              uri: gcsUri,
            },
            mimeType: 'application/pdf',
          },
          features: [{ type: 'DOCUMENT_TEXT_DETECTION' }],
          outputConfig: {
            gcsDestination: {
              uri: outputUri,
            },
            batchSize: 2,
          },
        },
      ],
    };

    // Start OCR job
    const [operation] = await visionClient.asyncBatchAnnotateFiles(request);
    console.log("Processing OCR...");
    const [filesResponse] = await operation.promise();

    // Locate output JSON file in GCS
    const [files] = await storage.bucket(bucketName).getFiles({
      prefix: outputPrefix,
    });

    const jsonFile = files.find(file => file.name.endsWith('.json'));
    if (!jsonFile) {
      throw new Error("OCR output file not found in GCS.");
    }

    // Download and parse OCR result
    const contents = await jsonFile.download();
    const ocrData = JSON.parse(contents[0]);

    const pages = ocrData.responses || [];
    const fullText = pages.map(p => p.fullTextAnnotation?.text || '').join('\n').trim();

    await Promise.all(files.map(file => file.delete().catch(() => null)));

    return fullText || "No text found in the document.";

  } catch (error) {
    console.error("OCR Error:", error);
    throw error;
  }
};

module.exports = extractTextFromGCS;
