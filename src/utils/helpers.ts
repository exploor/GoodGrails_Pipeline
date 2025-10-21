import { APIResponse } from '../types';

// Response helpers
export function jsonResponse<T>(
  data: T,
  status: number = 200,
  headers: Record<string, string> = {}
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      ...headers
    }
  });
}

export function successResponse<T>(data: T, status: number = 200): Response {
  return jsonResponse<APIResponse<T>>({ success: true, data }, status);
}

export function errorResponse(error: string, status: number = 400): Response {
  return jsonResponse<APIResponse>({ success: false, error }, status);
}

// UUID generator
export function generateUUID(): string {
  return crypto.randomUUID();
}

// Price conversion helpers
export function poundsToPence(pounds: number): number {
  return Math.round(pounds * 100);
}

export function penceToPounds(pence: number): number {
  return pence / 100;
}

export function formatPrice(pence: number): string {
  return `£${(pence / 100).toFixed(2)}`;
}

// ISBN validation and normalization
export function normalizeISBN(isbn: string): string {
  // Remove all non-digit characters except 'X'
  return isbn.replace(/[^0-9X]/gi, '').toUpperCase();
}

export function isValidISBN(isbn: string): boolean {
  const normalized = normalizeISBN(isbn);
  return normalized.length === 10 || normalized.length === 13;
}

// Date helpers
export function getCurrentTimestamp(): string {
  return new Date().toISOString();
}

export function getMonthBatch(date: Date = new Date()): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

// Text processing
export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength - 3) + '...';
}

export function cleanText(text: string): string {
  return text
    .replace(/\s+/g, ' ')
    .replace(/\n+/g, '\n')
    .trim();
}

// Error handling
export class BookstoreError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = 'BookstoreError';
  }
}

export function handleError(error: unknown): Response {
  console.error('Error:', error);

  if (error instanceof BookstoreError) {
    return errorResponse(error.message, error.statusCode);
  }

  if (error instanceof Error) {
    return errorResponse(error.message, 500);
  }

  return errorResponse('An unexpected error occurred', 500);
}

// Request parsing
export async function parseJSON<T>(request: Request): Promise<T> {
  try {
    return await request.json();
  } catch (error) {
    throw new BookstoreError('Invalid JSON in request body', 400);
  }
}

// URL helpers
export function getPathname(url: string): string {
  return new URL(url).pathname;
}

export function getSearchParams(url: string): URLSearchParams {
  return new URL(url).searchParams;
}
