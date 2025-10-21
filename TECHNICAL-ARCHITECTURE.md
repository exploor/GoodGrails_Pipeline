# Technical Architecture Document
## AI-Powered Charitable Bookstore with Blockchain Transparency

**Version:** 1.0  
**Last Updated:** October 21, 2025  
**Project Status:** Infrastructure Created - Ready for Development

---

## Quick Start Guide

### What We Just Built
✅ **D1 Database** with full schema (books, orders, donations, admin, audit log)  
✅ **R2 Bucket** for asset storage (covers, receipts)  
✅ **KV Namespace** for configuration  
🔲 **Vectorize Index** - requires CLI setup (see infrastructure doc)  
🔲 **Smart Contract** - requires deployment to Base

### Your Cloudflare Resources
- **Database ID**: `a6958759-920f-464b-9eb8-9d44257cfe3b`
- **R2 Bucket**: `bookstore-assets`
- **KV Namespace**: `602c9367a7794c73b52dcc9fe1cb3e1e`

Full details in: `cloudflare-infrastructure-setup.md`

---

## System Architecture Overview

### The Big Picture
```
USER
  ↓ types: "something shocking"
CLOUDFLARE WORKER (Edge)
  ↓ generates embedding (Workers AI)
  ↓ hybrid search:
    ├─ Vectorize (semantic: 70%)
    └─ D1 FTS (keyword: 30%)
  ↓ merge results
RETURN: ranked books

USER clicks "Buy"
  ↓ Stripe payment
  ↓ Record in D1
  ↓ Record on Base blockchain (instant)
  ↓ Email receipt with Base link

END OF MONTH
  ↓ Admin sends to GiveWell
  ↓ Upload receipt
  ↓ Record on Base with proof
  ↓ Email all customers
```

### Technology Stack

**Backend**: Cloudflare Workers (TypeScript)  
**Database**: D1 (SQLite)  
**Vector DB**: Vectorize (768d embeddings)  
**Storage**: R2 (images, receipts)  
**AI**: Workers AI + OpenAI GPT-4o-mini  
**Payments**: Stripe (UK)  
**Blockchain**: Base (Ethereum L2)  
**Frontend**: Next.js 14 + Tailwind

**Cost**: ~£15-20/month for MVP

---

## Core Workflows

### 1. Book Ingestion Pipeline

**Input**: ISBN + condition + cost  
**Output**: Fully enriched, searchable book listing

```typescript
// Admin enters:
{
  isbn: "9780375757853",
  condition: "very_good",
  cost_price: 5.00
}

// System does (parallel):
1. Fetch Open Library metadata
2. Fetch Google Books (backup)
3. Scrape Goodreads reviews (100)
4. Scrape BookFinder pricing

// AI enrichment (GPT-4o-mini):
{
  emotional_tone: ["melancholic", "bittersweet"],
  shock_factor: 7,
  pace: "slow_burn",
  atmosphere: ["dark", "atmospheric"],
  vibe_keywords: "dark academia, obsession, Greek tragedy"
}

// Generate embedding (Workers AI):
searchText = title + author + description + vibe_tags
embedding = bge-base-en-v1.5(searchText) // 768 dimensions

// Human reviews preview, approves

// Store:
- D1: full book record
- Vectorize: embedding + book_id
- Status: 'live'
```

**Key Files to Build:**
- `services/metadata.ts` - ISBN API fetching
- `services/scraper.ts` - Goodreads + BookFinder
- `services/enrichment.ts` - GPT-4 tagging
- `routes/admin/books.ts` - Admin endpoints

### 2. Hybrid Search Architecture

**User Query**: "something that will shock me"

**Process**:
```typescript
// 1. Generate query embedding (50ms)
const embedding = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
  text: query
});

// 2. Vector search (30ms)
const vectorResults = await env.VECTORIZE_INDEX.query(
  embedding.data[0],
  { topK: 50 }
);

// 3. Keyword search (10ms)
const keywordResults = await env.DB.prepare(`
  SELECT book_id, bm25(books_fts) as score
  FROM books_fts
  WHERE books_fts MATCH ?
  LIMIT 50
`).bind(query).all();

// 4. Merge scores (70% vector, 30% keyword)
const merged = mergeResults(vectorResults, keywordResults);

// 5. Fetch full details (20ms)
const books = await fetchBooks(merged.slice(0, 20));

// Total: ~100ms
```

**Why Hybrid?**
- Semantic catches concepts ("shocking" → surprising, disturbing)
- Keyword catches exact tags ("shock_factor: 9")
- Together: best of both worlds

**Key Files to Build:**
- `services/search.ts` - Hybrid search logic
- `routes/search.ts` - API endpoint

### 3. Purchase & Payment Flow

**Customer clicks "Buy Now" (£15 book)**

```typescript
// 1. Create Stripe Payment Intent
const intent = await stripe.paymentIntents.create({
  amount: 1500, // pence
  currency: 'gbp',
  metadata: {
    book_id: 'uuid-123',
    profit_amount: '10.00', // £15 - £5 cost
    charity: 'GiveWell UK'
  }
});

// 2. Customer completes payment (Stripe.js frontend)

// 3. Webhook receives confirmation
POST /api/webhooks/stripe
{
  type: 'payment_intent.succeeded',
  data: { ... }
}

// 4. Create order record in D1
INSERT INTO orders (
  id, book_id, book_price, profit_amount,
  charity_name, stripe_payment_id,
  payment_status, month_batch
) VALUES (...)

// 5. Mark book as sold
UPDATE books SET in_stock = FALSE, status = 'sold'

// 6. Queue blockchain recording (async)
await env.BLOCKCHAIN_QUEUE.send({
  type: 'record_purchase',
  order_id: 'order-uuid'
});

// 7. Send receipt email with Base tx link
```

**Key Files to Build:**
- `routes/checkout.ts` - Stripe intent creation
- `routes/webhooks.ts` - Payment confirmation
- `services/blockchain.ts` - Base recording
- `workers/blockchain-recorder.ts` - Queue worker

### 4. Monthly Donation Process

**Automated (1st of each month):**

```typescript
// Scheduled worker runs
export default {
  async scheduled(event, env) {
    // 1. Get donation totals per charity
    const batches = await env.DB.prepare(`
      SELECT charity_name, SUM(profit_amount) as total
      FROM orders
      WHERE month_batch = ?
      AND donation_status = 'pending'
      GROUP BY charity_name
    `).bind('2025-01').all();
    
    // 2. Create donation records
    for (const batch of batches) {
      await createDonationBatch(batch);
    }
    
    // 3. Email admin: "Time to send donations!"
    await sendAdminNotification();
  }
};
```

**Manual (Admin Dashboard):**

```typescript
// Admin visits /admin/donations/january-2025

1. Sees: "Send £4,500 to GiveWell UK"
2. Instructions: "Go to givewell.org, send via wire"
3. Upload receipt PDF
4. System:
   - Uploads to IPFS/R2
   - Updates D1 with receipt URL
   - Queues blockchain recording
   - Emails all customers in batch

// Customer email:
"Your £10 was sent to GiveWell UK!
Transaction: [Base link]
Receipt: [Download PDF]"
```

**Key Files to Build:**
- `workers/monthly-donations.ts` - Scheduled job
- `routes/admin/donations.ts` - Admin endpoints
- `services/email.ts` - Customer notifications

---

## Database Schema (Already Created)

### Key Tables

**books**
```sql
id, isbn, title, author, description, cover_url,
condition, cost_price, sell_price, in_stock,
metadata, vibe_tags, ai_enrichment, review_summary,
vector_id, status, created_at, updated_at, sold_at
```

**orders**
```sql
id, book_id, customer_email, book_price, profit_amount,
charity_name, stripe_payment_id, payment_status,
base_tx_hash, blockchain_status, month_batch,
donation_status, created_at, paid_at
```

**monthly_donations**
```sql
id, month, charity_name, total_amount, order_count,
receipt_url, bank_statement_url, base_tx_hash,
blockchain_status, created_at, sent_at, recorded_at
```

**Full schema in database - all tables and indexes created!**

---

## Smart Contract (Base Network)

### BookstoreTransparency.sol

**Key Functions:**

```solidity
// Record individual purchase (called after payment)
function recordPurchase(
    string orderId,
    uint256 bookPrice,      // in pence
    uint256 profitAmount,
    string charityName
) public onlyOwner

// Record monthly donation (called after bank transfer)
function recordDonation(
    string donationId,
    string month,
    string charityName,
    uint256 totalAmount,
    uint256 orderCount,
    string receiptIPFS,
    string bankStatementIPFS
) public onlyOwner

// Public view functions
function getTotalRaised() public view returns (uint256)
function getCharityTotal(string charityName) public view returns (uint256)
function getPurchase(string orderId) public view returns (Purchase)
function getDonation(string donationId) public view returns (MonthlyDonation)
```

**Deployment:**
```bash
# 1. Compile contract
npx hardhat compile

# 2. Deploy to Base
npx hardhat run scripts/deploy.ts --network base

# 3. Save contract address
# Add to wrangler secrets: CONTRACT_ADDRESS
```

**Gas Costs:**
- Per purchase: ~£0.02
- Per donation: ~£0.03
- Monthly total: ~£2-5

**Key Files to Create:**
- `contracts/BookstoreTransparency.sol`
- `scripts/deploy.ts`
- `hardhat.config.ts`

---

## API Endpoints

### Public Endpoints

```typescript
// Search
GET /api/search?q=shocking&limit=20
Response: { results: Book[], total: number }

// Get book
GET /api/books/:id
Response: { book: Book, related: Book[] }

// Checkout
POST /api/checkout
Body: { book_id, customer_email?, charity? }
Response: { client_secret, order_id }

// Transparency
GET /api/transparency/stats
Response: { total_raised, total_orders, charities[], recent_orders[] }

GET /api/transparency/order/:id
Response: { order, base_tx_hash, donation_batch? }
```

### Admin Endpoints (Auth Required)

```typescript
// Book ingestion
POST /api/admin/books/ingest
Body: { isbn, condition, cost_price, custom_title? }
Response: { book_id, metadata, enrichment, suggested_price }

POST /api/admin/books/:id/approve
Body: { final_price?, edits? }
Response: { success: true }

// Donations
GET /api/admin/donations
Response: { pending_batches[], sent_batches[] }

POST /api/admin/donations/:id/confirm
Body: FormData (receipt PDF, bank statement, confirmation)
Response: { success: true }

// Analytics
GET /api/admin/analytics
Response: { revenue, inventory, charity_stats }
```

### Webhooks

```typescript
// Stripe payment confirmation
POST /api/webhooks/stripe
Headers: { 'stripe-signature': '...' }
Body: Stripe Event

// Verify signature, process payment_intent.succeeded
```

---

## Frontend Architecture

### Public Site (Next.js)

**Key Pages:**
```
/                    → Chatbar search interface
/book/[id]           → Book detail page
/checkout            → Stripe payment flow
/transparency        → Public dashboard
/transparency/[id]   → Order lookup
```

**Components:**
```typescript
// ChatBar.tsx - Main search interface
<ChatBar onSearch={handleSearch} />

// BookCard.tsx - Search result card
<BookCard book={book} />

// CheckoutForm.tsx - Stripe Elements
<CheckoutForm book={book} />

// TransparencyDashboard.tsx - Impact tracker
<TransparencyDashboard stats={stats} />
```

### Admin Dashboard (Next.js)

**Key Pages:**
```
/admin               → Overview stats
/admin/books/add     → ISBN ingestion form
/admin/books         → Inventory management
/admin/orders        → Order list
/admin/donations     → Monthly batches
/admin/analytics     → Charts & metrics
```

**Auth:**
- JWT-based authentication
- Login page at `/admin/login`
- Protected routes with middleware

---

## Development Phases

### Phase 1: Core Pipeline (Week 1-2)
**Goal**: Admin can add books via ISBN

✅ Infrastructure setup (DONE)
- [ ] Create Vectorize index
- [ ] Set up Worker project structure
- [ ] Build metadata fetching service
- [ ] Build web scraping (Goodreads, BookFinder)
- [ ] Build AI enrichment service
- [ ] Build admin ingestion UI
- [ ] Build human review interface
- [ ] Test end-to-end: ISBN → live book

**Deliverable**: Admin panel where you enter ISBN and get a searchable book

### Phase 2: Search & Shop (Week 2-3)
**Goal**: Users can find and buy books

- [ ] Build hybrid search service
- [ ] Build chatbar frontend
- [ ] Build book detail pages
- [ ] Integrate Stripe checkout
- [ ] Build order confirmation flow
- [ ] Test: search → buy → receipt

**Deliverable**: Functional bookstore (no blockchain yet)

### Phase 3: Blockchain Transparency (Week 3-4)
**Goal**: Every transaction recorded on-chain

- [ ] Deploy smart contract to Base
- [ ] Build blockchain recording service
- [ ] Build queue worker for async recording
- [ ] Build public transparency dashboard
- [ ] Build order lookup page
- [ ] Test: purchase → Base recording → public view

**Deliverable**: Transparent purchase tracking

### Phase 4: Charity Integration (Week 4-5)
**Goal**: Monthly donations with proof

- [ ] Build scheduled donation job
- [ ] Build admin donation workflow
- [ ] Build receipt upload (IPFS/R2)
- [ ] Build customer notification emails
- [ ] Test: batch → send → record → notify

**Deliverable**: Complete charity flow with receipts

### Phase 5: Polish & Launch (Week 5-6)
**Goal**: Production-ready MVP

- [ ] Mobile responsive design
- [ ] Performance optimization
- [ ] Error handling & monitoring
- [ ] Admin analytics dashboard
- [ ] Documentation
- [ ] Security audit
- [ ] Launch! 🚀

---

## Critical Implementation Notes

### 1. Embedding Generation
```typescript
// ALWAYS use Workers AI for embeddings (free, fast)
const embedding = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
  text: searchableText
});

// Result is: { data: [Float32Array of 768 dimensions] }
// Use: embedding.data[0]
```

### 2. Hybrid Search Score Merging
```typescript
// Normalize both scores to 0-1 range
// Then apply weights (70% vector, 30% keyword)
// Combine by summing scores for same book_id
// Sort descending by combined score
```

### 3. Blockchain Recording
```typescript
// NEVER block user flow waiting for blockchain
// Queue async, record in background
// Update D1 with tx_hash once confirmed
// User sees instant "recorded" message, actual tx processes async
```

### 4. Price Calculations
```typescript
// Store ALL prices in pence to avoid float errors
// Convert for display: (priceInPence / 100).toFixed(2)
// Stripe also uses pence
```

### 5. Security
```typescript
// JWT tokens expire in 24h
// Admin routes require: Authorization: Bearer <token>
// Stripe webhooks MUST verify signature
// Input validation on ALL endpoints
// Rate limit: 100 req/min per IP
```

### 6. Error Handling
```typescript
// Graceful degradation:
// - Reviews fail? Proceed without
// - Enrichment fails? Use generic tags
// - Blockchain fails? Retry later
// NEVER block core flow for optional features
```

---

## Testing Strategy

### Unit Tests
```typescript
// Test each service independently
describe('MetadataService', () => {
  it('fetches Open Library data', async () => {
    const data = await fetchOpenLibrary('9780375757853');
    expect(data.title).toBeDefined();
  });
});
```

### Integration Tests
```typescript
// Test full workflows
describe('Book Ingestion', () => {
  it('creates book from ISBN', async () => {
    const result = await ingestBook({
      isbn: '9780375757853',
      condition: 'very_good',
      cost_price: 5
    });
    expect(result.book_id).toBeDefined();
  });
});
```

### E2E Tests
```typescript
// Test user flows with Playwright
test('user can search and buy book', async ({ page }) => {
  await page.goto('/');
  await page.fill('input[name="search"]', 'shocking');
  await page.click('text=Buy Now');
  // ... complete checkout
  await expect(page).toHaveURL(/\/success/);
});
```

---

## Monitoring & Observability

### Cloudflare Analytics
- Worker invocation count
- Response time (p50, p95, p99)
- Error rate
- D1 query performance
- Vectorize latency

### External Monitoring
- **Sentry**: Error tracking
- **Datadog**: Custom metrics
- **UptimeRobot**: Availability monitoring

### Key Metrics to Track
- Search latency (<100ms target)
- Book ingestion time (<30s target)
- Blockchain recording success rate (>99%)
- Stripe webhook processing time
- Monthly donation completion rate

---

## Cost Optimization Tips

1. **Use Workers AI for embeddings** (free tier) not OpenAI
2. **Batch blockchain recordings** to save gas
3. **Cache search results** in KV for popular queries
4. **Compress images** before uploading to R2
5. **Use D1 prepared statements** (faster, cheaper)
6. **Rate limit admin endpoints** to prevent abuse

---

## Security Checklist

- [ ] All secrets in wrangler secret (never in code)
- [ ] HTTPS only (automatic with Workers)
- [ ] CORS configured properly
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] Stripe webhook signature verification
- [ ] JWT authentication for admin
- [ ] Rate limiting enabled
- [ ] Activity logging for admin actions
- [ ] Regular D1 backups
- [ ] Private key stored securely (env var only)
- [ ] Customer emails encrypted in D1
- [ ] GDPR compliance (data deletion support)

---

## Deployment Checklist

### Prerequisites
- [ ] Wrangler CLI installed
- [ ] Cloudflare account active
- [ ] Node.js 18+ installed
- [ ] Git repository initialized

### Infrastructure
- [x] D1 database created
- [x] R2 bucket created
- [x] KV namespace created
- [ ] Vectorize index created (CLI)
- [ ] Smart contract deployed (Base)

### Configuration
- [ ] wrangler.toml configured
- [ ] All secrets set via wrangler secret
- [ ] Environment variables configured
- [ ] Stripe webhook endpoint registered
- [ ] Domain DNS configured

### Code
- [ ] All services implemented
- [ ] All routes implemented
- [ ] Frontend built and tested
- [ ] Admin panel built and tested
- [ ] Tests passing
- [ ] Documentation complete

### Launch
- [ ] Deploy Worker: `wrangler deploy`
- [ ] Deploy frontend: `vercel --prod`
- [ ] Test end-to-end in production
- [ ] Monitor for errors
- [ ] Announce launch! 🎉

---

## Quick Reference

### Important IDs
```
D1 Database: a6958759-920f-464b-9eb8-9d44257cfe3b
R2 Bucket: bookstore-assets
KV Namespace: 602c9367a7794c73b52dcc9fe1cb3e1e
Account ID: 954612afb5a97bb15dddcdc70176813d
```

### Useful Commands
```bash
# Local dev
wrangler dev

# Deploy
wrangler deploy

# Database query
wrangler d1 execute bookstore-db --command "SELECT COUNT(*) FROM books"

# Tail logs
wrangler tail

# Set secret
wrangler secret put OPENAI_API_KEY
```

### External Services
- Stripe Dashboard: https://dashboard.stripe.com
- Base Explorer: https://basescan.org
- OpenAI API: https://platform.openai.com
- Pinata (IPFS): https://pinata.cloud
- GiveWell UK: https://www.givewell.org/gwuk/about

---

## Support & Resources

### Documentation
- Cloudflare Workers: https://developers.cloudflare.com/workers/
- D1 Database: https://developers.cloudflare.com/d1/
- Vectorize: https://developers.cloudflare.com/vectorize/
- Workers AI: https://developers.cloudflare.com/workers-ai/
- Base Network: https://docs.base.org

### Getting Help
- Cloudflare Discord: https://discord.gg/cloudflaredev
- Stack Overflow: Tag `cloudflare-workers`
- GitHub Issues: For code problems

---

## Next Steps

1. **Create Vectorize Index**
   ```bash
   wrangler vectorize create book-embeddings --dimensions=768 --metric=cosine
   ```

2. **Initialize Worker Project**
   ```bash
   npm create cloudflare@latest bookstore-api
   cd bookstore-api
   # Copy wrangler.toml from infrastructure doc
   ```

3. **Set Up Frontend**
   ```bash
   npx create-next-app@latest bookstore-frontend
   cd bookstore-frontend
   ```

4. **Start Building**
   - Begin with metadata fetching service
   - Test with real ISBNs
   - Build incrementally following phases

5. **Deploy Smart Contract**
   - Set up Hardhat project
   - Deploy to Base testnet first
   - Test thoroughly before mainnet

---

## This is Your Blueprint

Everything is documented. Infrastructure is ready. Database is created. Schema is deployed.

**You now have:**
- ✅ Complete technical specification
- ✅ Working Cloudflare infrastructure
- ✅ Database schema with indexes
- ✅ Clear development phases
- ✅ Implementation details for every component

**Hand this to a developer and they can build it exactly as specified.**

Good luck building something genuinely innovative! 🚀📚
