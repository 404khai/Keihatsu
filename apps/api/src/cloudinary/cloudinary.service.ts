import { Injectable } from '@nestjs/common';
import { v2 as cloudinary } from 'cloudinary';
import { UploadApiResponse, UploadApiErrorResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
  async uploadImage(
    file: Express.Multer.File,
    folder?: string,
  ): Promise<UploadApiResponse> {
    return new Promise((resolve, reject) => {
      const options = folder ? { folder } : undefined;
      const uploadStream = cloudinary.uploader.upload_stream(
        options,
        (
          error: UploadApiErrorResponse | undefined,
          result?: UploadApiResponse,
        ) => {
          if (error) {
            const message = (() => {
              try {
                return JSON.stringify(error);
              } catch {
                return 'Cloudinary upload failed';
              }
            })();

            return reject(new Error(message));
          }
          if (!result) {
            return reject(new Error('Cloudinary upload returned no result'));
          }
          resolve(result);
        },
      );

      const readStream = streamifier.createReadStream(file.buffer);
      readStream.pipe(uploadStream);
    });
  }

  extractPublicIdFromUrl(imageUrl: string): string | null {
    try {
      const parsedUrl = new URL(imageUrl);
      if (!parsedUrl.hostname.includes('cloudinary.com')) {
        return null;
      }

      const uploadMarker = '/upload/';
      const uploadIndex = parsedUrl.pathname.indexOf(uploadMarker);
      if (uploadIndex === -1) {
        return null;
      }

      const afterUploadPath = parsedUrl.pathname.slice(
        uploadIndex + uploadMarker.length,
      );

      const pathSegments = afterUploadPath.split('/').filter(Boolean);
      if (pathSegments.length === 0) {
        return null;
      }

      const versionSegmentIndex = pathSegments.findIndex((segment) =>
        /^v\d+$/.test(segment),
      );

      const publicIdSegments =
        versionSegmentIndex >= 0
          ? pathSegments.slice(versionSegmentIndex + 1)
          : pathSegments;

      if (publicIdSegments.length === 0) {
        return null;
      }

      const publicIdPath = publicIdSegments.join('/');
      return publicIdPath.replace(/\.[^.]+$/, '');
    } catch {
      return null;
    }
  }

  async deleteImage(publicId: string): Promise<void> {
    type DestroyResult = { result?: string } | undefined;

    await new Promise<void>((resolve, reject) => {
      void cloudinary.uploader.destroy(
        publicId,
        (error: unknown, result: DestroyResult) => {
          if (error) {
            const message =
              error instanceof Error
                ? error.message
                : (() => {
                    try {
                      return JSON.stringify(error);
                    } catch {
                      return 'Cloudinary delete failed';
                    }
                  })();

            return reject(new Error(message));
          }

          if (!result) {
            return reject(new Error('Cloudinary destroy returned no result'));
          }

          if (result.result === 'not found') {
            return resolve();
          }

          resolve();
        },
      );
    });
  }

  async deleteImageByUrl(imageUrl?: string | null): Promise<boolean> {
    if (!imageUrl) {
      return false;
    }

    const publicId = this.extractPublicIdFromUrl(imageUrl);
    if (!publicId) {
      return false;
    }

    await this.deleteImage(publicId);
    return true;
  }
}
