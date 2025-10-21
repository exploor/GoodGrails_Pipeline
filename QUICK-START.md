# Quick Start Guide - Book Ingestion Pipeline

## What You Just Built

A complete book ingestion pipeline that:
1. Takes an ISBN
2. Fetches metadata from Open Library + Google Books
3. Enriches with AI-generated vibe tags
4. Uploads cover images to R2
5. Stores everything in D1 database
6. Returns a fully enriched book ready for approval

---

## Setup (5 minutes)

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Local Development

```bash
wrangler dev
```

This starts the Worker at `http://localhost:8787`

### 3. Verify Database Connection

```bash
curl http://localhost:8787/api/health
```

Expected response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "database": "connected",
    "timestamp": "..."
  }
}
```

---

## Test the Complete Pipeline

### Example 1: Ingest "The Secret History"

```bash
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "9780375757853",
    "condition": "very_good",
    "cost_price": 5.00
  }'
```

**What happens:**
1. ✅ Validates ISBN format
2. ✅ Checks for duplicates
3. ✅ Fetches metadata from Open Library
4. ✅ Fetches metadata from Google Books
5. ✅ Merges title, author, description, cover URL
6. ✅ Generates AI enrichment (vibe tags, themes, tone)
7. ✅ Calculates suggested price (£12.99)
8. ✅ Creates book record with status `pending_review`
9. ✅ Downloads cover image
10. ✅ Uploads cover to R2 bucket
11. ✅ Returns complete book data

**Response:**
```json
{
  "success": true,
  "data": {
    "book_id": "550e8400-e29b-41d4-a716-446655440000",
    "book": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "isbn": "9780375757853",
      "title": "The Secret History",
      "author": "Donna Tartt",
      "description": "Under the influence of their charismatic classics professor...",
      "cover_url": "/assets/covers/550e8400-e29b-41d4-a716-446655440000.jpg",
      "condition": "very_good",
      "cost_price": 500,
      "sell_price": 1299,
      "status": "pending_review",
      "vibe_tags": "dark academia, obsession, Greek tragedy",
      "ai_enrichment": {
        "emotional_tone": ["dark", "intense"],
        "shock_factor": 7,
        "pace": "slow_burn",
        "atmosphere": ["dark", "atmospheric"],
        "themes": ["betrayal", "murder", "friendship"]
      }
    },
    "suggested_price": 12.99
  }
}
```

### Example 2: Approve the Book

```bash
# Use the book_id from previous response
curl -X PATCH http://localhost:8787/api/admin/books/550e8400-e29b-41d4-a716-446655440000/approve \
  -H "Content-Type: application/json" \
  -d '{
    "final_price": 14.99
  }'
```

**What happens:**
1. ✅ Updates sell price to £14.99
2. ✅ Changes status from `pending_review` → `live`
3. ✅ Book is now visible to customers

### Example 3: View the Live Book (Public API)

```bash
curl http://localhost:8787/api/books/550e8400-e29b-41d4-a716-446655440000
```

Now customers can see this book!

---

## More Test ISBNs

```bash
# The Catcher in the Rye
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{"isbn": "9780316769174", "condition": "good", "cost_price": 3.50}'

# Pride and Prejudice
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{"isbn": "9780141439518", "condition": "very_good", "cost_price": 4.00}'

# The Hobbit
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{"isbn": "9780547928227", "condition": "like_new", "cost_price": 6.00}'
```

---

## Check Your Database

```bash
# See all books
wrangler d1 execute bookstore-db --command "SELECT id, title, author, status, sell_price FROM books"

# See pending books
wrangler d1 execute bookstore-db --command "SELECT * FROM books WHERE status = 'pending_review'"

# See live books
wrangler d1 execute bookstore-db --command "SELECT * FROM books WHERE status = 'live'"
```

---

## API Endpoints You Can Use Now

### Admin Endpoints

```bash
# Ingest book
POST /api/admin/books/ingest

# List all books (any status)
GET /api/admin/books?status=pending_review

# Get single book
GET /api/admin/books/:id

# Approve book
PATCH /api/admin/books/:id/approve

# Update book
PATCH /api/admin/books/:id

# Reject/delete book
DELETE /api/admin/books/:id
```

### Public Endpoints

```bash
# List live books
GET /api/books

# Get single book (must be live)
GET /api/books/:id

# Search books
GET /api/search?q=dark+academia

# Health check
GET /api/health
```

---

## Architecture Diagram

```
ISBN: "9780375757853"
    ↓
POST /api/admin/books/ingest
    ↓
IngestionService.ingestBook()
    ↓
    ├─→ MetadataService.fetchMetadata()
    │   ├─→ Open Library API
    │   └─→ Google Books API
    │
    ├─→ EnrichmentService.enrichBook()
    │   └─→ AI vibe tagging (heuristic or GPT-4o-mini)
    │
    ├─→ DatabaseService.createBook()
    │   └─→ D1: INSERT INTO books
    │
    └─→ StorageService.uploadBookCover()
        └─→ R2: PUT /covers/{book_id}.jpg
    ↓
Book created with status: "pending_review"
    ↓
Admin reviews in dashboard
    ↓
PATCH /api/admin/books/:id/approve
    ↓
Book status → "live"
    ↓
Visible on GET /api/books
```

---

## What's Working Right Now

✅ **ISBN → Metadata Fetching**
- Open Library API integration
- Google Books API integration
- Automatic fallback between sources

✅ **AI Enrichment**
- Vibe keyword extraction
- Emotional tone detection
- Shock factor calculation
- Theme extraction

✅ **Database Operations**
- Create, read, update books
- Status management (draft → pending → live → sold)
- Full-text search support

✅ **Image Storage**
- Download covers from external APIs
- Upload to R2 bucket
- Generate public URLs

✅ **Admin Workflow**
- Ingest books
- Review pending books
- Approve/reject books
- Edit book details

✅ **Public API**
- Browse all live books
- Search by keyword
- Get individual book details

---

## What's NOT Done Yet

❌ **Vectorize Index** (for semantic search)
```bash
wrangler vectorize create book-embeddings --dimensions=768 --metric=cosine
```

❌ **Authentication** (admin endpoints are open)

❌ **Stripe Integration** (payment flow)

❌ **Blockchain Recording** (Base contract)

❌ **Frontend** (web interface)

---

## Next Steps

### Immediate (15 minutes)
1. ✅ Test ingestion with 3-5 books
2. ✅ Verify data in D1 database
3. ✅ Test approval workflow
4. ✅ Test public API endpoints

### Short-term (1-2 hours)
1. Create Vectorize index for semantic search
2. Add JWT authentication to admin endpoints
3. Build simple admin UI (HTML form for ISBN input)

### Medium-term (1-2 days)
1. Build customer-facing frontend (Next.js)
2. Integrate Stripe checkout
3. Deploy to production

### Long-term (1-2 weeks)
1. Add blockchain transparency
2. Build donation workflow
3. Polish and launch

---

## Debugging

### Check Worker Logs

```bash
wrangler tail
```

Then make a request and watch real-time logs.

### Common Issues

**"Book not found for ISBN"**
- Try a different ISBN
- Check if the book exists in Open Library/Google Books
- Some ISBNs are only in one API, not both

**"Database error"**
- Verify D1 database exists: `wrangler d1 list`
- Check database ID in wrangler.toml matches

**"R2 upload failed"**
- Verify R2 bucket exists: `wrangler r2 bucket list`
- Check bucket name in wrangler.toml

---

## File Structure

```
ggrails/
├── wrangler.toml           # Cloudflare config
├── package.json            # Dependencies
├── tsconfig.json           # TypeScript config
├── src/
│   ├── index.ts           # Main Worker entry
│   ├── types/
│   │   └── index.ts       # TypeScript types
│   ├── utils/
│   │   ├── helpers.ts     # Utilities
│   │   └── router.ts      # Request router
│   ├── services/
│   │   ├── database.ts    # D1 operations
│   │   ├── metadata.ts    # API fetching
│   │   ├── enrichment.ts  # AI tagging
│   │   ├── storage.ts     # R2 uploads
│   │   └── ingestion.ts   # Main orchestrator
│   └── routes/
│       ├── admin.ts       # Admin endpoints
│       └── public.ts      # Public endpoints
└── docs/
    ├── TECHNICAL-ARCHITECTURE.md
    ├── API-DOCUMENTATION.md
    └── QUICK-START.md (this file)
```

---

## Support

**Something not working?**

1. Check `wrangler tail` for logs
2. Verify database: `wrangler d1 execute bookstore-db --command "SELECT COUNT(*) FROM books"`
3. Check API-DOCUMENTATION.md for endpoint details
4. Review TECHNICAL-ARCHITECTURE.md for system design

**Ready to deploy?**

```bash
npm run deploy
```

Your API will be live at: `https://bookstore-api.<your-subdomain>.workers.dev`

---

## You're Ready! 🚀

You now have a fully functional book ingestion pipeline. Add an ISBN, get a complete, searchable book record with metadata, AI enrichment, and cover images.

Start testing with real ISBNs and build your inventory!
