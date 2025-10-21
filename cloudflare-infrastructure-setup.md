# Cloudflare Infrastructure Setup - Complete

## ✅ Created Resources

### 1. D1 Database: `bookstore-db`
- **Database ID**: `a6958759-920f-464b-9eb8-9d44257cfe3b`
- **Region**: Western Europe (WEUR)
- **Status**: ✅ Created and Schema Deployed

#### Tables Created:
- ✅ `books` - Core book inventory with metadata
- ✅ `books_fts` - Full-text search virtual table
- ✅ `orders` - Purchase records
- ✅ `monthly_donations` - Charity donation tracking
- ✅ `admin_users` - Admin authentication
- ✅ `activity_log` - Audit trail

#### Indexes Created:
- Books: isbn, status, in_stock, author
- Orders: book_id, charity, month_batch, donation_status, payment_status
- Donations: month, charity_name
- Activity Log: user_id, entity_type/id, created_at

### 2. R2 Bucket: `bookstore-assets`
- **Bucket Name**: `bookstore-assets`
- **Region**: Eastern North America (ENAM)
- **Storage Class**: Standard
- **Created**: 2025-10-21

**Purpose**: Store book covers, receipts, bank statements

### 3. KV Namespace: `bookstore-config`
- **Namespace ID**: `602c9367a7794c73b52dcc9fe1cb3e1e`
- **Purpose**: Configuration storage (API keys, settings)

---

## 🔧 Next Steps: Manual Setup Required

### 1. Create Vectorize Index
**Run this command locally:**
```bash
wrangler vectorize create book-embeddings \
  --dimensions=768 \
  --metric=cosine
```

This creates the vector database for semantic search.

### 2. Create Worker Project
Create a new `wrangler.toml` file with the following configuration:

```toml
name = "bookstore-api"
main = "src/index.ts"
compatibility_date = "2024-10-01"
node_compat = true

# D1 Database binding
[[d1_databases]]
binding = "DB"
database_name = "bookstore-db"
database_id = "a6958759-920f-464b-9eb8-9d44257cfe3b"

# Vectorize binding (after creating index)
[[vectorize]]
binding = "VECTORIZE_INDEX"
index_name = "book-embeddings"

# Workers AI binding
[ai]
binding = "AI"

# R2 bucket binding
[[r2_buckets]]
binding = "ASSETS"
bucket_name = "bookstore-assets"

# KV namespace binding
[[kv_namespaces]]
binding = "CONFIG"
id = "602c9367a7794c73b52dcc9fe1cb3e1e"

# Environment variables (public)
[vars]
FRONTEND_URL = "https://yourdomain.com"
ADMIN_URL = "https://admin.yourdomain.com"

# Secret environment variables (set via wrangler secret)
# Run: wrangler secret put <name>
# - OPENAI_API_KEY
# - STRIPE_SECRET_KEY
# - STRIPE_WEBHOOK_SECRET
# - BLOCKCHAIN_PRIVATE_KEY
# - PINATA_JWT
# - ADMIN_EMAIL
# - JWT_SECRET
# - CONTRACT_ADDRESS
```

### 3. Set Environment Secrets
Run these commands to set sensitive values:

```bash
# OpenAI API key (for metadata enrichment)
wrangler secret put OPENAI_API_KEY

# Stripe keys (for payments)
wrangler secret put STRIPE_SECRET_KEY
wrangler secret put STRIPE_WEBHOOK_SECRET

# Blockchain wallet private key (for Base recording)
wrangler secret put BLOCKCHAIN_PRIVATE_KEY

# IPFS/Pinata JWT (for receipt storage)
wrangler secret put PINATA_JWT

# Admin email (for notifications)
wrangler secret put ADMIN_EMAIL

# JWT secret (for admin authentication)
wrangler secret put JWT_SECRET

# Smart contract address on Base (after deployment)
wrangler secret put CONTRACT_ADDRESS
```

### 4. Deploy Smart Contract to Base
See the technical documentation for full contract code and deployment script.

Contract needs to be deployed to Base mainnet and address added to secrets.

### 5. Project Structure
Create this directory structure:

```
bookstore/
├── workers/
│   ├── src/
│   │   ├── index.ts              # Main API worker
│   │   ├── routes/
│   │   │   ├── search.ts         # Search endpoints
│   │   │   ├── books.ts          # Book endpoints
│   │   │   ├── checkout.ts       # Payment endpoints
│   │   │   ├── admin.ts          # Admin endpoints
│   │   │   └── webhooks.ts       # Stripe webhooks
│   │   ├── services/
│   │   │   ├── metadata.ts       # ISBN fetching
│   │   │   ├── scraper.ts        # Review scraping
│   │   │   ├── enrichment.ts     # AI enrichment
│   │   │   ├── search.ts         # Hybrid search
│   │   │   └── blockchain.ts     # Base integration
│   │   └── utils/
│   │       ├── db.ts             # D1 helpers
│   │       ├── auth.ts           # JWT auth
│   │       └── validation.ts     # Input validation
│   ├── wrangler.toml
│   └── package.json
├── frontend/
│   ├── app/                       # Next.js app directory
│   ├── components/
│   ├── lib/
│   └── package.json
├── admin/
│   ├── app/                       # Admin Next.js app
│   └── package.json
└── contracts/
    ├── BookstoreTransparency.sol
    ├── deploy.ts
    └── hardhat.config.ts
```

---

## 📊 Database Verification

To verify the database structure:

```bash
# List all tables
wrangler d1 execute bookstore-db --command "SELECT name FROM sqlite_master WHERE type='table'"

# Check books table structure
wrangler d1 execute bookstore-db --command "PRAGMA table_info(books)"

# Check FTS table
wrangler d1 execute bookstore-db --command "PRAGMA table_info(books_fts)"
```

---

## 🎯 Development Workflow

### Local Development
```bash
# Install dependencies
npm install

# Run local dev server (with local D1 replica)
wrangler dev

# Access at http://localhost:8787
```

### Database Operations
```bash
# Run SQL queries
wrangler d1 execute bookstore-db --command "SELECT COUNT(*) FROM books"

# Import data from file
wrangler d1 execute bookstore-db --file=./migrations/seed-data.sql

# Backup database
wrangler d1 export bookstore-db --output=backup.sql
```

### Deployment
```bash
# Deploy to production
wrangler deploy

# Check deployment status
wrangler deployments list

# Tail logs
wrangler tail
```

---

## 💰 Cost Estimates

**Free Tier Includes:**
- D1: 5GB storage, 25B row reads/month
- Vectorize: 10M queries/month
- Workers AI: 10k neurons/day (embeddings)
- R2: 10GB storage, 1M Class A ops
- KV: 100k reads/day
- Workers: 100k requests/day

**Paid Plan ($5/mo):**
- All above limits significantly increased
- Required for production traffic

**Additional Costs:**
- OpenAI API: ~$10/mo (metadata enrichment)
- Stripe: 1.4% + 20p per transaction
- Base gas: ~£2/mo (blockchain recording)

**Total estimated: £15-20/mo for MVP**

---

## 🔐 Security Checklist

- [ ] Set all environment secrets via `wrangler secret put`
- [ ] Enable HTTPS only (automatic with Workers)
- [ ] Set up CORS properly in Worker
- [ ] Implement rate limiting (100 req/min)
- [ ] Add input validation on all endpoints
- [ ] Set up Stripe webhook signature verification
- [ ] Restrict admin routes with JWT auth
- [ ] Enable D1 point-in-time recovery
- [ ] Set up monitoring (Sentry/Datadog)
- [ ] Configure proper CORS origins
- [ ] Implement CSRF protection for admin panel

---

## 📝 Important Notes

1. **Vectorize Index**: Must be created manually via CLI (not available via API yet)
2. **Smart Contract**: Deploy to Base mainnet separately
3. **Secrets**: Never commit secrets to git - use wrangler secret
4. **Testing**: Use `wrangler dev --local` for local D1 database
5. **Backups**: Schedule regular D1 exports
6. **Monitoring**: Set up alerts for API errors and high latency

---

## 🚀 Ready to Build!

Your Cloudflare infrastructure is now set up. The database schema is deployed and ready for data.

**Next immediate steps:**
1. Create Vectorize index (via CLI)
2. Set up Worker project with wrangler.toml
3. Deploy smart contract to Base
4. Start building the book ingestion pipeline
5. Test locally with `wrangler dev`

All infrastructure IDs and configuration are documented above for easy reference.
