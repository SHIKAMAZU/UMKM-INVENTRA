import 'dotenv/config';
import { v2 as cloudinary } from 'cloudinary';

const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
const apiKey = process.env.CLOUDINARY_API_KEY;
const apiSecret = process.env.CLOUDINARY_API_SECRET;

export const cloudinaryEnabled = Boolean(cloudName && apiKey && apiSecret);

if (cloudinaryEnabled) {
  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
    secure: true,
  });
}

export function uploadImageBuffer(buffer, folder = 'stok-toko') {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder, resource_type: 'image' },
      (error, result) => (error ? reject(error) : resolve(result))
    );
    stream.end(buffer);
  });
}

export function publicIdFromUrl(url) {
  if (!url || !url.includes('/upload/')) return null;
  const afterUpload = url.split('/upload/')[1];
  const withoutVersion = afterUpload.replace(/^v\d+\//, '');
  return withoutVersion.replace(/\.[^./]+$/, '');
}

export { cloudinary };
