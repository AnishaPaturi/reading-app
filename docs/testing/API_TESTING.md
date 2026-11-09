# Reading Sanctuary — API Manual Testing & cURL Reference

This guide provides practical cURL commands to test each core API domain in Reading Sanctuary against a local or staging server (`http://localhost:8080`).

---

## 1. Authentication Flows

### 1.1 Register New User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "scholar_alice",
    "email": "alice@sanctuary.org",
    "password": "Password123!"
  }'
```

### 1.2 Login & Extract JWT
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@sanctuary.org",
    "password": "Password123!"
  }'
```
*Save the returned `token` to an environment variable:*
```bash
export TOKEN="eyJhbGciOiJIUzI1NiJ9..."
```

### 1.3 Fetch Current Profile
```bash
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

---

## 2. Books & Library Management

### 2.1 Create a Book Record
```bash
curl -X POST http://localhost:8080/api/books \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "The Secret History",
    "author": "Donna Tartt",
    "genre": "Dark Academia",
    "description": "A story of classics students at a Vermont college."
  }'
```
*Note the returned `bookId`:*
```bash
export BOOK_ID="<returned-uuid>"
```

### 2.2 List User's Books
```bash
curl -X GET "http://localhost:8080/api/books?page=0&size=20" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 3. Format-Aware Reading Positions

### 3.1 Update Reading Position (EPUB CFI)
```bash
curl -X PUT "http://localhost:8080/api/books/$BOOK_ID/reading-position" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "format": "EPUB",
    "locator": "epubcfi(/6/4[chap01]!/4/2/10/1:0)",
    "progressPercentage": 14.5,
    "lastReadAt": "2026-11-09T10:00:00Z"
  }'
```

### 3.2 Retrieve Reading Position
```bash
curl -X GET "http://localhost:8080/api/books/$BOOK_ID/reading-position" \
  -H "Authorization: Bearer $TOKEN"
```

---

## 4. Bookmarks, Highlights & Notes

### 4.1 Create a Bookmark
```bash
curl -X POST "http://localhost:8080/api/books/$BOOK_ID/bookmarks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Greek Tragedy Discussion",
    "locator": "epubcfi(/6/6[chap02]!/4/2/4:0)",
    "pageNumber": 42
  }'
```

### 4.2 Create a Highlight
```bash
curl -X POST "http://localhost:8080/api/books/$BOOK_ID/highlights" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "highlightedText": "Beauty is terror. Whatever we call beautiful, we quiver before it.",
    "locator": "epubcfi(/6/6[chap02]!/4/2/18:12)",
    "color": "YELLOW",
    "annotationNote": "Julian Morrow philosophy"
  }'
```

---

## 5. Cloud Storage Presigned URLs

### 5.1 Request Upload Intent (S3 Presigned PUT)
```bash
curl -X POST http://localhost:8080/api/storage/upload-intent \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookId": "'"$BOOK_ID"'",
    "fileName": "secret_history.epub",
    "contentType": "application/epub+zip",
    "fileSize": 2048576,
    "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }'
```

### 5.2 Complete Upload Registration
```bash
curl -X POST http://localhost:8080/api/storage/complete-upload \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fileId": "<returned-file-uuid>",
    "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }'
```

---

## 6. Bidirectional Sync

### 6.1 Register Device
```bash
curl -X POST http://localhost:8080/api/sync/devices \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceName": "Scholar Workstation",
    "platform": "DESKTOP"
  }'
```

### 6.2 Pull Delta Changes
```bash
curl -X POST http://localhost:8080/api/sync/pull \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "cursor": 0,
    "batchSize": 50
  }'
```

---

## 7. System Health Check

```bash
curl -X GET http://localhost:8080/actuator/health
```
Expected response:
```json
{
  "status": "UP"
}
```
