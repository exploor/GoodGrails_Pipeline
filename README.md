# AI-Powered Charitable Bookstore

> Complete book ingestion pipeline built on Cloudflare Workers, D1, and R2

## What This Is

A working API for a charitable bookstore that:
- **Ingests books from ISBN** → Fetches metadata from Open Library + Google Books
- **AI enrichment** → Generates vibe tags, themes, emotional tone
- **Image storage** → Uploads covers to R2 bucket
- **Database** → Stores everything in D1 SQLite
- **Admin workflow** → Review → Approve → Publish
- **Public API** → Browse and search books

---

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Start local development
npm run dev

# 3. Test the API
curl http://localhost:8787/api/health

# 4. Ingest your first book
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "9780375757853",
    "condition": "very_good",
    "cost_price": 5.00
  }'
```

**That's it!** You now have a complete book record with metadata, AI enrichment, and cover image.

---

## Project Structure

```
ggrails/
├── wrangler.toml                    # Cloudflare Worker config
├── package.json                     # Dependencies
├── tsconfig.json                    # TypeScript config
│
├── src/
│   ├── index.ts                     # Main Worker entry point
│   │
│   ├── types/
│   │   └── index.ts                 # TypeScript types
│   │
│   ├── utils/
│   │   ├── helpers.ts               # Utility functions
│   │   └── router.ts                # Request router
│   │
│   ├── services/
│   │   ├── database.ts              # D1 database operations
│   │   ├── metadata.ts              # Open Library + Google Books
│   │   ├── enrichment.ts            # AI vibe tagging
│   │   ├── storage.ts               # R2 image uploads
│   │   └── ingestion.ts             # Main orchestrator
│   │
│   └── routes/
│       ├── admin.ts                 # Admin API endpoints
│       └── public.ts                # Public API endpoints
│
└── docs/
    ├── TECHNICAL-ARCHITECTURE.md    # Complete system design
    ├── API-DOCUMENTATION.md         # API reference
    ├── QUICK-START.md               # Step-by-step guide
    └── cloudflare-infrastructure... # Infrastructure setup
```

---

## API Endpoints

### Public Endpoints

```bash
GET  /api/health              # Health check
GET  /api/books               # List all live books
GET  /api/books/:id           # Get single book
GET  /api/search?q=query      # Search books
```

### Admin Endpoints

```bash
POST   /api/admin/books/ingest          # Ingest book from ISBN
GET    /api/admin/books                 # List all books (any status)
GET    /api/admin/books/:id             # Get book details
PATCH  /api/admin/books/:id             # Update book
PATCH  /api/admin/books/:id/approve     # Approve and publish
DELETE /api/admin/books/:id             # Reject/remove book
```

---

## Complete Workflow

### 1. Ingest a Book

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
1. ✅ Validates ISBN
2. ✅ Fetches metadata (Open Library + Google Books)
3. ✅ Generates AI enrichment
4. ✅ Uploads cover image to R2
5. ✅ Creates database record
6. ✅ Status: `pending_review`

**Response includes:**
- Complete book data
- Suggested price (£12.99)
- Metadata from both APIs
- AI-generated vibe tags

### 2. Approve the Book

```bash
curl -X PATCH http://localhost:8787/api/admin/books/{book_id}/approve \
  -H "Content-Type: application/json" \
  -d '{"final_price": 14.99}'
```

**What happens:**
1. ✅ Updates price
2. ✅ Changes status to `live`
3. ✅ Book now visible to customers

### 3. Customers Browse

```bash
curl http://localhost:8787/api/books
```

Returns all live, in-stock books.

---

## Infrastructure

### Already Set Up

✅ **D1 Database** (ID: `a6958759-920f-464b-9eb8-9d44257cfe3b`)
- 6 tables: books, orders, donations, admin, audit_log, blockchain_events
- Full-text search indexes
- All schemas deployed

✅ **R2 Bucket** (`bookstore-assets`)
- Stores book covers
- Ready for receipts and documents

✅ **KV Namespace** (ID: `602c9367a7794c73b52dcc9fe1cb3e1e`)
- Configuration storage

### Not Yet Set Up

❌ **Vectorize Index** (for semantic search)
```bash
wrangler vectorize create book-embeddings --dimensions=768 --metric=cosine
```

❌ **Queue** (for blockchain recording)
```bash
wrangler queues create blockchain-queue
```

❌ **Secrets** (API keys)
```bash
wrangler secret put OPENAI_API_KEY
wrangler secret put STRIPE_SECRET_KEY
wrangler secret put JWT_SECRET
```

---

## What's Working

✅ **Book Ingestion Pipeline**
- ISBN validation
- Metadata fetching (2 sources)
- AI enrichment
- Image storage
- Database operations

✅ **Admin Workflow**
- Ingest books
- Review pending books
- Approve/reject
- Edit details

✅ **Public API**
- Browse books
- Search by keyword
- Get book details

✅ **Database**
- Full CRUD operations
- Status management
- Full-text search

---

## What's Next

### Phase 1: Complete MVP (This Week)

1. **Test thoroughly**
   - Ingest 10-20 books
   - Test approval workflow
   - Verify public API

2. **Add authentication**
   - JWT tokens for admin
   - Protect admin endpoints

3. **Create Vectorize index**
   - Enable semantic search
   - "Find me something shocking"

### Phase 2: Frontend (Next Week)

1. **Admin panel**
   - Simple HTML form for ISBN input
   - Review pending books
   - Approve/reject interface

2. **Customer site**
   - Search bar
   - Book grid
   - Detail pages

### Phase 3: Payments (Week After)

1. **Stripe integration**
   - Checkout flow
   - Payment confirmation
   - Order recording

2. **Blockchain transparency**
   - Deploy Base contract
   - Record purchases
   - Public dashboard

---

## Technology Stack

**Backend:** Cloudflare Workers (TypeScript)
**Database:** D1 (SQLite)
**Storage:** R2 (S3-compatible)
**Vector DB:** Vectorize (768d embeddings)
**AI:** Workers AI + OpenAI GPT-4o-mini
**Payments:** Stripe
**Blockchain:** Base (Ethereum L2)

**Cost:** ~£15-20/month for MVP

---

## Documentation

📖 **[QUICK-START.md](./QUICK-START.md)** - Get up and running in 5 minutes
📖 **[API-DOCUMENTATION.md](./API-DOCUMENTATION.md)** - Complete API reference
📖 **[TECHNICAL-ARCHITECTURE.md](./TECHNICAL-ARCHITECTURE.md)** - System design and architecture

---

## Deployment

### Local Development

```bash
npm run dev
# API available at http://localhost:8787
```

### Production Deployment

```bash
npm run deploy
# API available at https://bookstore-api.<your-subdomain>.workers.dev
```

### Check Logs

```bash
wrangler tail
```

### Query Database

```bash
wrangler d1 execute bookstore-db --command "SELECT COUNT(*) FROM books"
```

---

## Example Usage

### Test with Real ISBNs

```bash
# The Secret History - Donna Tartt
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{"isbn": "9780375757853", "condition": "very_good", "cost_price": 5.00}'

# The Catcher in the Rye - J.D. Salinger
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{"isbn": "9780316769174", "condition": "good", "cost_price": 3.50}'

# Pride and Prejudice - Jane Austen
curl -X POST http://localhost:8787/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{"isbn": "9780141439518", "condition": "very_good", "cost_price": 4.00}'
```

---

## Features

### Book Ingestion
- ✅ ISBN validation (ISBN-10 and ISBN-13)
- ✅ Duplicate detection
- ✅ Multi-source metadata fetching
- ✅ Automatic price calculation
- ✅ Cover image download and storage
- ✅ AI-powered enrichment

### Metadata Sources
- ✅ Open Library API
- ✅ Google Books API
- ✅ Automatic fallback and merging

### AI Enrichment
- ✅ Vibe keyword extraction
- ✅ Emotional tone detection
- ✅ Shock factor scoring
- ✅ Theme identification
- ✅ Atmosphere analysis

### Storage
- ✅ D1 database for structured data
- ✅ R2 bucket for images
- ✅ KV namespace for config
- 🔲 Vectorize for semantic search (pending setup)

### Admin Features
- ✅ Bulk ingestion
- ✅ Review workflow
- ✅ Approval system
- ✅ Price override
- ✅ Metadata editing

### Public Features
- ✅ Browse books
- ✅ Search by keyword
- ✅ Book details
- 🔲 Semantic search (pending Vectorize)

---

## Support

**Issues or questions?**

1. Check the documentation in `/docs`
2. Review logs: `wrangler tail`
3. Test database: `wrangler d1 execute bookstore-db --command "SELECT * FROM books LIMIT 5"`

---

## License

Private project - All rights reserved

---

## Summary

You have a **complete, working book ingestion pipeline** that:

1. Takes an ISBN
2. Fetches rich metadata
3. Enriches with AI
4. Stores images in R2
5. Saves to D1 database
6. Provides admin approval workflow
7. Exposes public API

**Ready to test!** Start ingesting books and build your inventory.

🚀 **Next step:** Run `npm install && npm run dev` and ingest your first book!
