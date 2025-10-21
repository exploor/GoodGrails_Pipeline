/**
 * Cloudflare Worker - AI-Powered Charitable Bookstore
 * Main entry point for the API
 */

import { Env } from './types';
import { Router } from './utils/router';
import * as admin from './routes/admin';
import * as publicRoutes from './routes/public';

// Create router
const router = new Router();

// ========== PUBLIC ROUTES ==========

// Health check
router.get('/api/health', publicRoutes.healthCheck);

// Browse books
router.get('/api/books', publicRoutes.listPublicBooks);
router.get('/api/books/:id', (req, env, params) =>
  publicRoutes.getPublicBook(req, env, params!.id)
);

// Search
router.get('/api/search', publicRoutes.searchBooks);

// Serve images from R2
router.get('/assets/:path', async (req, env, params) => {
  try {
    const key = `covers/${params!.path}`;
    const object = await env.ASSETS.get(key);

    if (!object) {
      return new Response('Image not found', { status: 404 });
    }

    return new Response(object.body, {
      headers: {
        'Content-Type': object.httpMetadata?.contentType || 'image/jpeg',
        'Cache-Control': 'public, max-age=31536000',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    console.error('R2 fetch error:', error);
    return new Response('Error fetching image', { status: 500 });
  }
});

// ========== ADMIN ROUTES ==========
// TODO: Add authentication middleware

// Book ingestion
router.post('/api/admin/books/ingest', admin.ingestBook);

// Book management
router.get('/api/admin/books', admin.listBooks);
router.get('/api/admin/books/:id', (req, env, params) =>
  admin.getBook(req, env, params!.id)
);
router.patch('/api/admin/books/:id', (req, env, params) =>
  admin.updateBook(req, env, params!.id)
);
router.delete('/api/admin/books/:id', (req, env, params) =>
  admin.rejectBook(req, env, params!.id)
);

// Book approval workflow
router.patch('/api/admin/books/:id/approve', (req, env, params) =>
  admin.approveBook(req, env, params!.id)
);

// ========== WORKER EXPORT ==========

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    try {
      return await router.route(request, env);
    } catch (error) {
      console.error('Worker error:', error);

      return new Response(
        JSON.stringify({
          success: false,
          error: 'Internal server error',
          message: error instanceof Error ? error.message : 'Unknown error'
        }),
        {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      );
    }
  }
};
