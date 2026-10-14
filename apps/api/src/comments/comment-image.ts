import { BadRequestException } from '@nestjs/common';
import sharp from 'sharp';

// Decode/resize before any bytes reach Cloudinary. Filename/MIME are untrusted.
export async function compressCommentImage(file: Express.Multer.File): Promise<Express.Multer.File> {
  if (file.buffer.length > 5 * 1024 * 1024) throw new BadRequestException('Image is too large');
  try {
    const image = sharp(file.buffer, { limitInputPixels: 40_000_000 });
    const metadata = await image.metadata();
    if (!['jpeg', 'png', 'webp'].includes(metadata.format || '') || (metadata.pages || 1) > 1) {
      throw new Error('Unsupported image');
    }
    const buffer = await image.rotate().resize(2048, 2048, { fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 82, effort: 4 }).toBuffer();
    return { ...file, buffer, size: buffer.length, mimetype: 'image/webp', originalname: 'comment.webp' };
  } catch (_) {
    throw new BadRequestException('Choose a valid JPEG, PNG or WebP image');
  }
}
