import { Test, TestingModule } from '@nestjs/testing';
import { CloudinaryService } from './cloudinary.service';
import { v2 as cloudinary } from 'cloudinary';

jest.mock('cloudinary', () => ({
  v2: {
    uploader: {
      destroy: jest.fn(),
    },
  },
}));

describe('CloudinaryService', () => {
  let service: CloudinaryService;
  const destroyMock = cloudinary.uploader.destroy as jest.Mock;

  beforeEach(async () => {
    destroyMock.mockReset();

    const module: TestingModule = await Test.createTestingModule({
      providers: [CloudinaryService],
    }).compile();

    service = module.get<CloudinaryService>(CloudinaryService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('extracts the public ID from a Cloudinary URL', () => {
    expect(
      service.extractPublicIdFromUrl(
        'https://res.cloudinary.com/demo/image/upload/v1234567890/avatars/user-image.jpg',
      ),
    ).toBe('avatars/user-image');
  });

  it('extracts the public ID from a transformed Cloudinary URL', () => {
    expect(
      service.extractPublicIdFromUrl(
        'https://res.cloudinary.com/demo/image/upload/c_fill,w_300/v1234567890/banners/cover-image.png',
      ),
    ).toBe('banners/cover-image');
  });

  it('returns null for non-Cloudinary URLs', () => {
    expect(
      service.extractPublicIdFromUrl('https://example.com/images/avatar.jpg'),
    ).toBeNull();
  });

  it('deletes an image using the public ID parsed from its URL', async () => {
    destroyMock.mockImplementation(
      (
        publicId: string,
        callback: (error: unknown, result: { result: string }) => void,
      ) => callback(null, { result: 'ok' }),
    );

    await expect(
      service.deleteImageByUrl(
        'https://res.cloudinary.com/demo/image/upload/v1234567890/banners/cover-image.png',
      ),
    ).resolves.toBe(true);

    expect(destroyMock).toHaveBeenCalledWith(
      'banners/cover-image',
      expect.any(Function),
    );
  });
});
