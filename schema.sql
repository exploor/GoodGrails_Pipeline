-- Database Schema for AI-Powered Charitable Bookstore
-- Version: 1.0

-- ==================== BOOKS TABLE ====================
-- Stores all book information, metadata, and AI enrichment
CREATE TABLE IF NOT EXISTS books (
    id TEXT PRIMARY KEY,
    isbn TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    description TEXT,
    cover_url TEXT,

    -- Physical attributes
    condition TEXT NOT NULL CHECK(condition IN ('like_new', 'very_good', 'good', 'acceptable')),
    cost_price INTEGER NOT NULL,  -- in pence
    sell_price INTEGER NOT NULL,  -- in pence
    in_stock INTEGER NOT NULL DEFAULT 1,  -- boolean (0 or 1)

    -- Metadata and enrichment (stored as JSON)
    metadata TEXT,  -- JSON: publisher, page_count, categories, etc.
    vibe_tags TEXT,
    ai_enrichment TEXT,  -- JSON: emotional_tone, shock_factor, pace, etc.
    review_summary TEXT,

    -- Search and discovery
    vector_id TEXT,  -- Reference to Vectorize embedding

    -- Status tracking
    status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'pending_review', 'live', 'sold', 'removed')),

    -- Timestamps
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sold_at TEXT
);

-- Index on ISBN for quick lookups
CREATE INDEX IF NOT EXISTS idx_books_isbn ON books(isbn);

-- Index on status and stock for filtering
CREATE INDEX IF NOT EXISTS idx_books_status_stock ON books(status, in_stock);

-- Index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at DESC);


-- ==================== FULL-TEXT SEARCH ====================
-- Virtual table for full-text search on books
-- Note: Using standalone FTS5 table (not content=books) for D1 compatibility
CREATE VIRTUAL TABLE IF NOT EXISTS books_fts USING fts5(
    book_id UNINDEXED,
    title,
    author,
    description,
    vibe_tags
);

-- Triggers to keep FTS table in sync with books table
CREATE TRIGGER IF NOT EXISTS books_fts_insert AFTER INSERT ON books BEGIN
    INSERT INTO books_fts(rowid, book_id, title, author, description, vibe_tags)
    VALUES (new.rowid, new.id, new.title, new.author, new.description, new.vibe_tags);
END;

CREATE TRIGGER IF NOT EXISTS books_fts_update AFTER UPDATE ON books BEGIN
    DELETE FROM books_fts WHERE rowid = old.rowid;
    INSERT INTO books_fts(rowid, book_id, title, author, description, vibe_tags)
    VALUES (new.rowid, new.id, new.title, new.author, new.description, new.vibe_tags);
END;

CREATE TRIGGER IF NOT EXISTS books_fts_delete AFTER DELETE ON books BEGIN
    DELETE FROM books_fts WHERE rowid = old.rowid;
END;


-- ==================== ORDERS TABLE ====================
-- Stores customer orders and payment information
CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    customer_email TEXT,

    -- Payment details
    book_price INTEGER NOT NULL,  -- in pence
    profit_amount INTEGER NOT NULL,  -- in pence (book_price - cost_price)
    charity_name TEXT NOT NULL,
    stripe_payment_id TEXT NOT NULL,
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK(payment_status IN ('pending', 'succeeded', 'failed')),

    -- Blockchain tracking
    base_tx_hash TEXT,
    blockchain_status TEXT CHECK(blockchain_status IN ('pending', 'confirmed', 'failed')),

    -- Batch tracking for monthly donations
    month_batch TEXT NOT NULL,  -- Format: YYYY-MM
    donation_status TEXT NOT NULL DEFAULT 'pending' CHECK(donation_status IN ('pending', 'sent', 'confirmed')),

    -- Timestamps
    created_at TEXT NOT NULL,
    paid_at TEXT,

    FOREIGN KEY (book_id) REFERENCES books(id)
);

-- Indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_book_id ON orders(book_id);
CREATE INDEX IF NOT EXISTS idx_orders_month_batch ON orders(month_batch);
CREATE INDEX IF NOT EXISTS idx_orders_donation_status ON orders(donation_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);


-- ==================== MONTHLY DONATIONS TABLE ====================
-- Tracks monthly donation batches to charities
CREATE TABLE IF NOT EXISTS monthly_donations (
    id TEXT PRIMARY KEY,
    month TEXT NOT NULL,  -- Format: YYYY-MM
    charity_name TEXT NOT NULL,

    -- Donation details
    total_amount INTEGER NOT NULL,  -- in pence
    order_count INTEGER NOT NULL,

    -- Proof of donation
    receipt_url TEXT,  -- R2/IPFS URL
    bank_statement_url TEXT,  -- R2/IPFS URL

    -- Blockchain tracking
    base_tx_hash TEXT,
    blockchain_status TEXT CHECK(blockchain_status IN ('pending', 'confirmed', 'failed')),

    -- Timestamps
    created_at TEXT NOT NULL,
    sent_at TEXT,  -- When donation was sent to charity
    recorded_at TEXT  -- When recorded on blockchain
);

-- Index for querying by month
CREATE INDEX IF NOT EXISTS idx_donations_month ON monthly_donations(month DESC);
CREATE INDEX IF NOT EXISTS idx_donations_charity ON monthly_donations(charity_name);


-- ==================== ADMIN USERS TABLE ====================
-- Simple admin authentication (expand as needed)
CREATE TABLE IF NOT EXISTS admin_users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    role TEXT NOT NULL DEFAULT 'admin',
    active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    last_login TEXT
);

CREATE INDEX IF NOT EXISTS idx_admin_email ON admin_users(email);


-- ==================== AUDIT LOG TABLE ====================
-- Track all admin actions for transparency
CREATE TABLE IF NOT EXISTS audit_log (
    id TEXT PRIMARY KEY,
    admin_id TEXT,
    action TEXT NOT NULL,  -- 'create_book', 'approve_book', 'send_donation', etc.
    entity_type TEXT NOT NULL,  -- 'book', 'order', 'donation'
    entity_id TEXT NOT NULL,
    details TEXT,  -- JSON with additional context
    created_at TEXT NOT NULL,

    FOREIGN KEY (admin_id) REFERENCES admin_users(id)
);

CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log(entity_type, entity_id);


-- ==================== BLOCKCHAIN EVENTS TABLE ====================
-- Track all blockchain interactions for debugging/transparency
CREATE TABLE IF NOT EXISTS blockchain_events (
    id TEXT PRIMARY KEY,
    event_type TEXT NOT NULL,  -- 'purchase', 'donation'
    reference_id TEXT NOT NULL,  -- order_id or donation_id
    tx_hash TEXT,
    status TEXT NOT NULL CHECK(status IN ('pending', 'submitted', 'confirmed', 'failed')),
    error_message TEXT,
    gas_used INTEGER,
    block_number INTEGER,
    created_at TEXT NOT NULL,
    confirmed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_blockchain_reference ON blockchain_events(reference_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_status ON blockchain_events(status);
CREATE INDEX IF NOT EXISTS idx_blockchain_created_at ON blockchain_events(created_at DESC);
