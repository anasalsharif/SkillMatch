const { Storage } = require('@google-cloud/storage');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { Readable } = require('stream');

const configuredKeyFile = process.env.GCS_KEY_FILE || process.env.GOOGLE_APPLICATION_CREDENTIALS;
const keyFilename = configuredKeyFile && !configuredKeyFile.includes('absolute\\path')
  ? configuredKeyFile
  : undefined;
const bucketName = process.env.GCS_BUCKET;
const storage = keyFilename ? new Storage({ keyFilename }) : new Storage();
const bucket = bucketName ? storage.bucket(bucketName) : null;

const saveLocalUpload = async (file, folder) => {
  const uploadRoot = path.join(__dirname, '..', 'uploads', folder);
  await fs.promises.mkdir(uploadRoot, { recursive: true });

  const ext = path.extname(file.originalname || '') || '';
  const fileName = `${crypto.randomUUID()}${ext}`;
  const localPath = path.join(uploadRoot, fileName);
  const fileBuffer = file.buffer || await fs.promises.readFile(file.path);
  await fs.promises.writeFile(localPath, fileBuffer);

  const baseUrl = process.env.PUBLIC_BASE_URL || `http://localhost:${process.env.PORT || 5000}`;
  return `${baseUrl}/uploads/${folder}/${fileName}`;
};

const uploadToGCS = (file, folder = "avatars") => {
  return new Promise((resolve, reject) => {
    if (!bucket) {
      saveLocalUpload(file, folder).then(resolve).catch(reject);
      return;
    }

    const ext = path.extname(file.originalname);
    const gcsFileName = `${folder}/${crypto.randomUUID()}${ext}`;
    const blob = bucket.file(gcsFileName);
    const blobStream = blob.createWriteStream({
      resumable: false,
      contentType: file.mimetype,
    });

    blobStream.on('error', (err) => reject(err));

    blobStream.on('finish', () => {
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`;
      resolve(publicUrl);
    });

    const bufferStream = new Readable();
    bufferStream.push(file.buffer);
    bufferStream.push(null);
    bufferStream.pipe(blobStream);
  });
};

module.exports = {uploadToGCS, bucket};
