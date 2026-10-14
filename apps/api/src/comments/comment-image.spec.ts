import sharp from 'sharp';
import { compressCommentImage } from './comment-image';

describe('comment image upload normalization', () => {
  it('resizes before upload, compresses, and preserves alpha', async () => {
    const buffer = await sharp({create: {width: 3200, height: 1800, channels: 4, background: {r: 40, g: 80, b: 200, alpha: .5}}}).png().toBuffer();
    const file = await compressCommentImage({buffer, originalname: 'anything.png', mimetype: 'image/png', size: buffer.length} as Express.Multer.File);
    const metadata = await sharp(file.buffer).metadata();
    expect(metadata.format).toBe('webp'); expect(metadata.width).toBe(2048);
    expect(metadata.hasAlpha).toBe(true); expect(file.size).toBeLessThan(buffer.length);
  });
  it('rejects fake images without forwarding raw decoder diagnostics', async () => {
    await expect(compressCommentImage({buffer: Buffer.from('https://private-backend/secret')} as Express.Multer.File))
      .rejects.toThrow('Choose a valid JPEG, PNG or WebP image');
  });
  it('limits uploaded bytes before decoding', async () => {
    await expect(compressCommentImage({buffer: Buffer.alloc(5 * 1024 * 1024 + 1)} as Express.Multer.File))
      .rejects.toThrow('Image is too large');
  });
});
