# Bookstore API Documentation

## Overview

Complete RESTful API for the AI-powered charitable bookstore built on Cloudflare Workers.

**Base URL (local dev):** `http://localhost:8787`
**Base URL (production):** `https://bookstore-api.<your-subdomain>.workers.dev`

---

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Run Local Development Server

```bash
npm run dev
# or
wrangler dev
```

### 3. Test the API

```bash
# Health check
curl http://localhost:8787/api/health

# Expected response:
{
  "success": true,
  "data": {
    "status": "healthy",
    "database": "connected",
    "timestamp": "2025-10-21T12:00:00.000Z"
  }
}
```

---

## API Endpoints

### Public Endpoints

#### Health Check
```http
GET /api/health
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "database": "connected",
    "timestamp": "2025-10-21T12:00:00.000Z"
  }
}
```

---

#### List Books
```http
GET /api/books?limit=20&offset=0
```

**Query Parameters:**
- `limit` (optional): Number of books to return (default: 20)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "data": {
    "books": [
      {
        "id": "uuid-here",
        "isbn": "9780375757853",
        "title": "The Secret History",
        "author": "Donna Tartt",
        "description": "...",
        "cover_url": "https://...",
        "condition": "very_good",
        "sell_price": 1299,
        "in_stock": true,
        "vibe_tags": "dark academia, obsession, Greek tragedy",
        "status": "live"
      }
    ],
    "total": 100,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

---

#### Get Single Book
```http
GET /api/books/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "book": {
      "id": "uuid-here",
      "isbn": "9780375757853",
      "title": "The Secret History",
      ...
    }
  }
}
```

---

#### Search Books
```http
GET /api/search?q=shocking&limit=20
```

**Query Parameters:**
- `q` (required): Search query
- `limit` (optional): Number of results (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "query": "shocking",
    "results": [...],
    "total": 5
  }
}
```

---

### Admin Endpoints

#### Ingest Book from ISBN

```http
POST /api/admin/books/ingest
Content-Type: application/json

{
  "isbn": "9780375757853",
  "condition": "very_good",
  "cost_price": 5.00,
  "custom_title": "Optional custom title",
  "custom_author": "Optional custom author"
}
```

**Request Body:**
- `isbn` (required): ISBN-10 or ISBN-13
- `condition` (required): `like_new`, `very_good`, `good`, or `acceptable`
- `cost_price` (required): Cost in pounds (e.g., 5.00)
- `custom_title` (optional): Override fetched title
- `custom_author` (optional): Override fetched author

**Response:**
```json
{
  "success": true,
  "data": {
    "book_id": "uuid-here",
    "book": {
      "id": "uuid-here",
      "isbn": "9780375757853",
      "title": "The Secret History",
      "author": "Donna Tartt",
      "description": "Under the influence of their charismatic classics professor...",
      "cover_url": "/assets/covers/uuid-here.jpg",
      "condition": "very_good",
      "cost_price": 500,
      "sell_price": 1299,
      "in_stock": true,
      "status": "pending_review",
      "metadata": {
        "publisher": "Vintage",
        "publish_date": "2004",
        "page_count": 559,
        "categories": ["Fiction", "Mystery"]
      },
      "vibe_tags": "dark academia, obsession, Greek tragedy",
      "ai_enrichment": {
        "emotional_tone": ["dark", "intense"],
        "shock_factor": 7,
        "pace": "slow_burn",
        "atmosphere": ["dark", "atmospheric"]
      }
    },
    "metadata": {
      "open_library": {...},
      "google_books": {...}
    },
    "suggested_price": 12.99,
    "errors": []
  }
}
```

---

#### Approve Book

```http
PATCH /api/admin/books/:id/approve
Content-Type: application/json

{
  "final_price": 14.99,
  "title": "Edited title",
  "description": "Edited description",
  "vibe_tags": "dark, mysterious, gripping"
}
```

**Request Body (all optional):**
- `final_price`: Final selling price in pounds
- `title`: Edit the title
- `author`: Edit the author
- `description`: Edit the description
- `vibe_tags`: Edit the vibe tags

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "book": {
      "id": "uuid-here",
      "status": "live",
      ...
    }
  }
}
```

---

#### List All Books (Admin)

```http
GET /api/admin/books?status=pending_review&in_stock=true&limit=50&offset=0
```

**Query Parameters:**
- `status` (optional): `draft`, `pending_review`, `live`, `sold`, `removed`
- `in_stock` (optional): `true` or `false`
- `limit` (optional): Number of books (default: 50)
- `offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "data": {
    "books": [...],
    "total": 100,
    "limit": 50,
    "offset": 0,
    "has_more": true
  }
}
```

---

#### Get Book (Admin)

```http
GET /api/admin/books/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "book": {...}
  }
}
```

---

#### Update Book

```http
PATCH /api/admin/books/:id
Content-Type: application/json

{
  "title": "Updated title",
  "sell_price": 1599,
  "vibe_tags": "new tags"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "book": {...}
  }
}
```

---

#### Reject Book

```http
DELETE /api/admin/books/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "message": "Book rejected and removed"
  }
}
```

---

## Complete Workflow Example

### Book Ingestion Flow

```bash
# 1. Ingest a book
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "9780375757853",
    "condition": "very_good",
    "cost_price": 5.00
  }'

# Response includes book_id: "abc-123"

# 2. Review the book (check metadata, enrichment)
curl http://localhost:8787/api/admin/books/abc-123

# 3. Approve the book (set to live)
curl -X PATCH http://localhost:8787/api/admin/books/abc-123/approve \
  -H "Content-Type: application/json" \
  -d '{
    "final_price": 14.99
  }'

# 4. Book is now live and visible to customers
curl http://localhost:8787/api/books/abc-123

# 5. Customers can search for it
curl http://localhost:8787/api/search?q=shocking
```

---

## Error Handling

All endpoints return errors in this format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created (for POST requests)
- `400` - Bad request (validation error)
- `404` - Not found
- `409` - Conflict (e.g., duplicate ISBN)
- `500` - Internal server error

---

## Data Types

### Book Conditions

- `like_new` - Almost new, minimal wear
- `very_good` - Minor wear, fully readable
- `good` - Moderate wear, pages intact
- `acceptable` - Significant wear but complete

### Book Status

- `draft` - Initial state
- `pending_review` - Awaiting admin approval
- `live` - Available for purchase
- `sold` - Already purchased
- `removed` - Rejected/deleted

### Prices

All prices are stored in **pence** in the database:
- `500` = £5.00
- `1299` = £12.99

API accepts prices in pounds (e.g., `5.00`) and converts internally.

---

## Testing ISBNs

Here are some ISBNs to test with:

```
9780375757853 - The Secret History (Donna Tartt)
9780316769174 - The Catcher in the Rye (J.D. Salinger)
9780141439518 - Pride and Prejudice (Jane Austen)
9780547928227 - The Hobbit (J.R.R. Tolkien)
9780062316097 - Sapiens (Yuval Noah Harari)
```

---

## Next Steps

1. **Deploy to Cloudflare:**
   ```bash
   npm run deploy
   ```

2. **Set up secrets:**
   ```bash
   wrangler secret put OPENAI_API_KEY
   wrangler secret put JWT_SECRET
   ```

3. **Create Vectorize index:**
   ```bash
   wrangler vectorize create book-embeddings --dimensions=768 --metric=cosine
   ```

4. **Build frontend** to consume this API

5. **Add authentication** to admin endpoints

---

## Architecture Overview

```
CLIENT REQUEST
    ↓
src/index.ts (Router)
    ↓
routes/admin.ts or routes/public.ts
    ↓
services/ingestion.ts (Orchestrator)
    ├─→ services/metadata.ts (Open Library + Google Books)
    ├─→ services/enrichment.ts (AI tagging)
    ├─→ services/storage.ts (R2 image upload)
    └─→ services/database.ts (D1 storage)
    ↓
RESPONSE
```

---

## Support

For issues or questions:
- Check the TECHNICAL-ARCHITECTURE.md
- Review the database schema in DATABASE-SCHEMA.md
- Check Cloudflare D1 status: `wrangler d1 execute bookstore-db --command "SELECT COUNT(*) FROM books"`
