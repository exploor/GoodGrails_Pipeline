#!/bin/bash

# Complete Book Ingestion Workflow Test
# Run this after starting wrangler dev

BASE_URL="http://localhost:8787"

echo "========================================="
echo "Testing Book Ingestion Workflow"
echo "========================================="
echo ""

# 1. Health Check
echo "1. Testing health check..."
curl -s $BASE_URL/api/health | jq '.'
echo ""

# 2. Ingest a book
echo "2. Ingesting The Catcher in the Rye..."
RESPONSE=$(curl -s -X POST $BASE_URL/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "9780316769174",
    "condition": "good",
    "cost_price": 3.50
  }')

echo "$RESPONSE" | jq '.'
BOOK_ID=$(echo "$RESPONSE" | jq -r '.data.book_id')
echo ""
echo "Created book ID: $BOOK_ID"
echo ""

# 3. List pending books
echo "3. Listing pending books..."
curl -s "$BASE_URL/api/admin/books?status=pending_review" | jq '.data.books[0] | {id, title, author, status}'
echo ""

# 4. Approve the book
echo "4. Approving the book..."
curl -s -X PATCH "$BASE_URL/api/admin/books/$BOOK_ID/approve" \
  -H "Content-Type: application/json" \
  -d '{"final_price": 9.99}' | jq '.'
echo ""

# 5. Check if it's live
echo "5. Checking live books..."
curl -s $BASE_URL/api/books | jq '.data.books[0] | {id, title, author, status, sell_price}'
echo ""

# 6. Search for it
echo "6. Searching for 'catcher'..."
curl -s "$BASE_URL/api/search?q=catcher" | jq '.data | {query, total, results: .results[0].title}'
echo ""

# 7. Ingest another book
echo "7. Ingesting Pride and Prejudice..."
curl -s -X POST $BASE_URL/api/admin/books/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "isbn": "9780141439518",
    "condition": "very_good",
    "cost_price": 4.00
  }' | jq '.data | {book_id, title: .book.title, suggested_price}'
echo ""

echo "========================================="
echo "Workflow test complete!"
echo "========================================="
