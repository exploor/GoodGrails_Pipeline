import { Env } from '../types';
import { BookstoreError } from '../utils/helpers';

/**
 * R2 Storage Service
 * Handles image and file uploads to Cloudflare R2
 */
export class StorageService {
  constructor(private env: Env) {}

  /**
   * Download and upload book cover image to R2
   */
  async uploadBookCover(
    bookId: string,
    imageUrl: string
  ): Promise<string> {
    try {
      // Download image
      const response = await fetch(imageUrl);

      if (!response.ok) {
        throw new BookstoreError(
          `Failed to download image from ${imageUrl}`,
          400
        );
      }

      const contentType = response.headers.get('content-type') || 'image/jpeg';
      const imageData = await response.arrayBuffer();

      // Generate R2 key
      const fileExtension = this.getFileExtension(contentType);
      const key = `covers/${bookId}${fileExtension}`;

      // Upload to R2
      await this.env.ASSETS.put(key, imageData, {
        httpMetadata: {
          contentType
        }
      });

      // Return public URL (you'll need to configure R2 public access or use a custom domain)
      return this.getPublicUrl(key);
    } catch (error) {
      console.error('Cover upload error:', error);
      // Don't fail the entire process if cover upload fails
      // Return the original URL as fallback
      return imageUrl;
    }
  }

  /**
   * Upload a file from request (for receipts, etc.)
   */
  async uploadFile(
    file: File | ArrayBuffer,
    fileName: string,
    folder: string = 'uploads'
  ): Promise<string> {
    try {
      const key = `${folder}/${Date.now()}-${fileName}`;

      let data: ArrayBuffer;
      let contentType = 'application/octet-stream';

      if (file instanceof File) {
        data = await file.arrayBuffer();
        contentType = file.type;
      } else {
        data = file;
      }

      await this.env.ASSETS.put(key, data, {
        httpMetadata: {
          contentType
        }
      });

      return this.getPublicUrl(key);
    } catch (error) {
      console.error('File upload error:', error);
      throw new BookstoreError('Failed to upload file', 500);
    }
  }

  /**
   * Get a file from R2
   */
  async getFile(key: string): Promise<ArrayBuffer | null> {
    try {
      const object = await this.env.ASSETS.get(key);
      if (!object) return null;
      return await object.arrayBuffer();
    } catch (error) {
      console.error('File retrieval error:', error);
      return null;
    }
  }

  /**
   * Delete a file from R2
   */
  async deleteFile(key: string): Promise<void> {
    try {
      await this.env.ASSETS.delete(key);
    } catch (error) {
      console.error('File deletion error:', error);
      // Don't throw - deletion failures are non-critical
    }
  }

  // ========== HELPER METHODS ==========

  private getFileExtension(contentType: string): string {
    const extensions: Record<string, string> = {
      'image/jpeg': '.jpg',
      'image/jpg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
      'application/pdf': '.pdf'
    };

    return extensions[contentType] || '.jpg';
  }

  private getPublicUrl(key: string): string {
    // Option 1: Use R2 public bucket domain (requires R2 public access)
    // return `https://bookstore-assets.your-account.r2.cloudflarestorage.com/${key}`;

    // Option 2: Use custom domain mapped to R2
    // return `https://cdn.yourdomain.com/${key}`;

    // Option 3: Serve through Worker (recommended for access control)
    return `/assets/${key}`;
  }
}
