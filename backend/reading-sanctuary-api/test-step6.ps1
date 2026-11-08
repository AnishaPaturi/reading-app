# =====================================================================
# Reading Sanctuary API - Step 6 Complete Verification Script
# =====================================================================

$ErrorActionPreference = "Stop"
$baseUrl = "http://localhost:8080"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   READING SANCTUARY API: STEP 6 VERIFICATION TEST" -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# Session Setup: Log in User A
# ---------------------------------------------------------------------
Write-Host "[Setup] Logging in as reader@example.com..." -ForegroundColor Cyan
$loginBody = @{
    email    = "reader@example.com"
    password = "Reader@123"
} | ConvertTo-Json

$login = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/auth/login" -ContentType "application/json" -Body $loginBody
$headers = @{
    Authorization = "Bearer $($login.accessToken)"
}
Write-Host "PASS: User A logged in." -ForegroundColor Green

# Create test book for Step 6
$bookBody = @{
    title       = "The Silent Patient - Step 6 Test"
    description = "Testing Reading Sanctuary progress tracking."
} | ConvertTo-Json

$book = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/books" -Headers $headers -ContentType "application/json" -Body $bookBody
$bookId = $book.id
Write-Host "Created test book: $bookId" -ForegroundColor Green

# =====================================================================
# Step 6.31 — Reading Progress Tests (Tests 1 - 8)
# =====================================================================

Write-Host "`n--- STEP 6.31: READING PROGRESS TESTS ---" -ForegroundColor Yellow

# Test 1: Mark as Currently Reading
Write-Host "`n[Test 1] Marking book as CURRENTLY_READING (page 50 of 336)..." -ForegroundColor Cyan
$readingBody = @{
    status      = "CURRENTLY_READING"
    currentPage = 50
    totalPages  = 336
} | ConvertTo-Json

$reading = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body $readingBody
if ($reading.status -ne "CURRENTLY_READING" -or $reading.currentPage -ne 50 -or $reading.progressPercentage -ne 14.88) {
    throw "Test 1 failed: Unexpected values $($reading | ConvertTo-Json)"
}
Write-Host "PASS: status=CURRENTLY_READING, currentPage=50, progressPercentage=14.88%, startedAt=$($reading.startedAt)" -ForegroundColor Green

# Test 2: Update reading progress
Write-Host "`n[Test 2] Updating progress to page 173..." -ForegroundColor Cyan
$progressBody = @{
    currentPage = 173
} | ConvertTo-Json

$reading = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body $progressBody
if ($reading.currentPage -ne 173 -or $reading.progressPercentage -ne 51.49) {
    throw "Test 2 failed: Unexpected values $($reading | ConvertTo-Json)"
}
Write-Host "PASS: currentPage=173, progressPercentage=51.49%" -ForegroundColor Green

# Test 3: Retrieve reading details
Write-Host "`n[Test 3] Retrieving reading details..." -ForegroundColor Cyan
$readingDetails = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers
if ($readingDetails.currentPage -ne 173) {
    throw "Test 3 failed!"
}
Write-Host "PASS: Reading details verified." -ForegroundColor Green

# Test 4: Mark as DNF
Write-Host "`n[Test 4] Marking book as DNF..." -ForegroundColor Cyan
$dnfBody = @{
    status = "DNF"
} | ConvertTo-Json

$reading = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body $dnfBody
if ($reading.status -ne "DNF" -or $reading.currentPage -ne 173 -or $reading.totalPages -ne 336) {
    throw "Test 4 failed: Progress or pages were erased on DNF!"
}
Write-Host "PASS: Status marked DNF while preserving currentPage=173 and totalPages=336." -ForegroundColor Green

# Test 5: Resume reading
Write-Host "`n[Test 5] Resuming reading (CURRENTLY_READING)..." -ForegroundColor Cyan
$resumeBody = @{
    status = "CURRENTLY_READING"
} | ConvertTo-Json

$reading = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body $resumeBody
if ($reading.status -ne "CURRENTLY_READING") {
    throw "Test 5 failed!"
}
Write-Host "PASS: Resumed CURRENTLY_READING." -ForegroundColor Green

# Test 6: Mark as completed
Write-Host "`n[Test 6] Marking book as COMPLETED..." -ForegroundColor Cyan
$completeBody = @{
    status = "COMPLETED"
} | ConvertTo-Json

$reading = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body $completeBody
if ($reading.status -ne "COMPLETED" -or $reading.currentPage -ne 336 -or $reading.progressPercentage -ne 100.0 -or [string]::IsNullOrEmpty($reading.completedAt)) {
    throw "Test 6 failed: Completion did not advance page or record date!"
}
Write-Host "PASS: Status COMPLETED, currentPage=336, progress=100%, completedAt=$($reading.completedAt)" -ForegroundColor Green

# Test 7: Retrieve reading history
Write-Host "`n[Test 7] Retrieving reading history..." -ForegroundColor Cyan
$history = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/history" -Headers $headers
Write-Host "History entries count: $($history.Count)"
$history | Format-Table previousStatus, newStatus, currentPage, changedAt
if ($history.Count -lt 4) {
    throw "Test 7 failed: Expected at least 4 transitions in history!"
}
Write-Host "PASS: Reading history verified." -ForegroundColor Green

# Test 8: Filter books by status
Write-Host "`n[Test 8] Filtering books by status..." -ForegroundColor Cyan
$completedList = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/reading?status=COMPLETED" -Headers $headers
$tbrList = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/reading?status=TO_READ" -Headers $headers
Write-Host "PASS: Filtered queries succeeded. Completed books: $($completedList.Count), TBR: $($tbrList.Count)" -ForegroundColor Green

# =====================================================================
# Step 6.32 — Bookshelf Tests (Tests 9 - 13)
# =====================================================================

Write-Host "`n--- STEP 6.32: BOOKSHELF TESTS ---" -ForegroundColor Yellow

# Test 9: Create bookshelf
Write-Host "`n[Test 9] Creating bookshelf 'Dark Academia'..." -ForegroundColor Cyan
$shelfBody = @{
    name        = "Dark Academia"
    description = "Books with dark academia themes."
    color       = "#5B4636"
} | ConvertTo-Json

$shelf = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/shelves" -Headers $headers -ContentType "application/json" -Body $shelfBody
$shelfId = $shelf.id
Write-Host "PASS: Bookshelf created. ID: $shelfId" -ForegroundColor Green

# Test 10: Add book to shelf
Write-Host "`n[Test 10] Adding book to shelf..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/shelves/$shelfId/books/$bookId" -Headers $headers
Write-Host "PASS: Book added to shelf (204 No Content)." -ForegroundColor Green

# Test 11: Retrieve shelves
Write-Host "`n[Test 11] Retrieving shelves..." -ForegroundColor Cyan
$shelves = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/shelves" -Headers $headers
$targetShelf = $shelves | Where-Object { $_.id -eq $shelfId }
if ($targetShelf.name -ne "Dark Academia" -or $targetShelf.bookCount -ne 1 -or -not ($targetShelf.bookIds -contains $bookId)) {
    throw "Test 11 failed: Shelf contents mismatch!"
}
Write-Host "PASS: Shelf retrieved: name='$($targetShelf.name)', bookCount=$($targetShelf.bookCount), bookIds contains $bookId" -ForegroundColor Green

# Test 12: Update bookshelf
Write-Host "`n[Test 12] Updating bookshelf description..." -ForegroundColor Cyan
$updateShelfBody = @{
    description = "My favourite dark academia and psychological thriller books."
} | ConvertTo-Json

$updatedShelf = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/shelves/$shelfId" -Headers $headers -ContentType "application/json" -Body $updateShelfBody
if ($updatedShelf.description -ne "My favourite dark academia and psychological thriller books.") {
    throw "Test 12 failed!"
}
Write-Host "PASS: Shelf description updated." -ForegroundColor Green

# Test 13: Remove book from shelf
Write-Host "`n[Test 13] Removing book from shelf..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/shelves/$shelfId/books/$bookId" -Headers $headers
$shelvesAfter = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/shelves" -Headers $headers
$targetAfter = $shelvesAfter | Where-Object { $_.id -eq $shelfId }
if ($targetAfter.bookCount -ne 0) {
    throw "Test 13 failed: Book was not removed from shelf!"
}
Write-Host "PASS: Book removed from shelf. Book count: $($targetAfter.bookCount)" -ForegroundColor Green

# =====================================================================
# Step 6.33 — Collection Tests (Tests 14 - 18)
# =====================================================================

Write-Host "`n--- STEP 6.33: COLLECTION & FOLDER TESTS ---" -ForegroundColor Yellow

# Test 14: Create parent collection
Write-Host "`n[Test 14] Creating parent collection 'Fiction'..." -ForegroundColor Cyan
$collectionBody = @{
    name        = "Fiction"
    description = "My fiction library."
} | ConvertTo-Json

$parentCollection = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/collections" -Headers $headers -ContentType "application/json" -Body $collectionBody
$parentId = $parentCollection.id
Write-Host "PASS: Parent collection created. ID: $parentId" -ForegroundColor Green

# Test 15: Create nested collection
Write-Host "`n[Test 15] Creating nested collection 'Psychological Thrillers'..." -ForegroundColor Cyan
$childBody = @{
    name        = "Psychological Thrillers"
    description = "Psychological thriller books."
    parentId    = $parentId
} | ConvertTo-Json

$childCollection = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/collections" -Headers $headers -ContentType "application/json" -Body $childBody
$childId = $childCollection.id
if ($childCollection.parentId -ne $parentId) {
    throw "Test 15 failed: Parent ID not set on child collection!"
}
Write-Host "PASS: Nested collection created under parent $parentId. Child ID: $childId" -ForegroundColor Green

# Test 16: Add book to collection
Write-Host "`n[Test 16] Adding book to child collection..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/collections/$childId/books/$bookId" -Headers $headers
Write-Host "PASS: Book added to collection (204 No Content)." -ForegroundColor Green

# Test 17: Retrieve collections
Write-Host "`n[Test 17] Retrieving collections and verifying hierarchy..." -ForegroundColor Cyan
$collections = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/collections" -Headers $headers
$retrievedChild = $collections | Where-Object { $_.id -eq $childId }
if ($retrievedChild.bookCount -ne 1 -or -not ($retrievedChild.bookIds -contains $bookId)) {
    throw "Test 17 failed: Child collection book mismatch!"
}
Write-Host "PASS: Collections hierarchy verified. Child collection has book $bookId" -ForegroundColor Green

# Test 18: Remove book from collection
Write-Host "`n[Test 18] Removing book from collection..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/collections/$childId/books/$bookId" -Headers $headers
$collectionsAfter = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/collections" -Headers $headers
$retrievedChildAfter = $collectionsAfter | Where-Object { $_.id -eq $childId }
if ($retrievedChildAfter.bookCount -ne 0) {
    throw "Test 18 failed: Book was not removed from collection!"
}
Write-Host "PASS: Book removed from collection. Book count: 0" -ForegroundColor Green

# =====================================================================
# Step 6.34 — Ratings and Reviews Tests (Tests 19 - 22)
# =====================================================================

Write-Host "`n--- STEP 6.34: RATINGS & REVIEWS TESTS ---" -ForegroundColor Yellow

# Test 19: Create review
Write-Host "`n[Test 19] Creating book review..." -ForegroundColor Cyan
$reviewBody = @{
    rating = 5
    review = "An engaging psychological thriller with a brilliant twist."
} | ConvertTo-Json

$review = Invoke-RestMethod -Method Put -Uri "$baseUrl/api/v1/books/$bookId/review" -Headers $headers -ContentType "application/json" -Body $reviewBody
if ($review.rating -ne 5 -or $review.review -ne "An engaging psychological thriller with a brilliant twist.") {
    throw "Test 19 failed!"
}
Write-Host "PASS: Review created. Rating: $($review.rating), Review: '$($review.review)'" -ForegroundColor Green

# Test 20: Retrieve review
Write-Host "`n[Test 20] Retrieving review..." -ForegroundColor Cyan
$retrievedReview = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/review" -Headers $headers
if ($retrievedReview.rating -ne 5) {
    throw "Test 20 failed!"
}
Write-Host "PASS: Review retrieved successfully." -ForegroundColor Green

# Test 21: Update review
Write-Host "`n[Test 21] Updating review to 4 stars..." -ForegroundColor Cyan
$updatedReviewBody = @{
    rating = 4
    review = "A great book, although I wanted more from the ending."
} | ConvertTo-Json

$updatedReview = Invoke-RestMethod -Method Put -Uri "$baseUrl/api/v1/books/$bookId/review" -Headers $headers -ContentType "application/json" -Body $updatedReviewBody
if ($updatedReview.rating -ne 4) {
    throw "Test 21 failed!"
}
Write-Host "PASS: Review updated. Rating: 4" -ForegroundColor Green

# Test 22: Delete review
Write-Host "`n[Test 22] Deleting review..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/books/$bookId/review" -Headers $headers
try {
    $null = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/review" -Headers $headers
    throw "Test 22 failed: Expected 404 on deleted review!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "PASS: Review deleted and verified 404 Not Found." -ForegroundColor Green
    } else {
        throw $_
    }
}

# =====================================================================
# Part H — Security and Data-Integrity Tests
# =====================================================================

Write-Host "`n--- PART H: SECURITY & DATA-INTEGRITY TESTS ---" -ForegroundColor Yellow

# Register User B
Write-Host "`n[Security Setup] Registering and logging in User B..." -ForegroundColor Cyan
$regUserBBody = @{
    email    = "reader2@example.com"
    password = "Reader@456"
} | ConvertTo-Json

try {
    $null = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/users/register" -ContentType "application/json" -Body $regUserBBody
} catch {
    # Ignore 409 if already registered
}

$loginBBody = @{
    email    = "reader2@example.com"
    password = "Reader@456"
} | ConvertTo-Json

$loginB = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/auth/login" -ContentType "application/json" -Body $loginBBody
$headersB = @{
    Authorization = "Bearer $($loginB.accessToken)"
}
Write-Host "User B authenticated." -ForegroundColor Green

# 1. User B accesses User A's reading progress -> 404
Write-Host "Test: User B accesses User A's reading progress -> Expected 404"
try {
    $null = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headersB
    throw "Security breach: User B accessed User A's reading progress!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "PASS: 404 Not Found as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 2. User B creates shelf then adds User A's book -> 404
Write-Host "Test: User B adds User A's book to User B's shelf -> Expected 404"
$shelfB = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/shelves" -Headers $headersB -ContentType "application/json" -Body (@{ name = "User B Shelf" } | ConvertTo-Json)
try {
    $null = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/shelves/$($shelfB.id)/books/$bookId" -Headers $headersB
    throw "Security breach: User B added User A's book to shelf!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "PASS: 404 Not Found as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 3. User B accesses User A's shelf -> 404 (by attempting to delete or access)
Write-Host "Test: User B accesses User A's shelf -> Expected 404"
try {
    $null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/shelves/$shelfId" -Headers $headersB
    throw "Security breach: User B manipulated User A's shelf!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "PASS: 404 Not Found as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 4. User B adds User A's book to their collection -> 404
Write-Host "Test: User B adds User A's book to collection -> Expected 404"
$collB = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/collections" -Headers $headersB -ContentType "application/json" -Body (@{ name = "User B Collection" } | ConvertTo-Json)
try {
    $null = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/collections/$($collB.id)/books/$bookId" -Headers $headersB
    throw "Security breach: User B added User A's book to collection!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Host "PASS: 404 Not Found as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 5. Invalid reading status -> 400
Write-Host "Test: Invalid reading status -> Expected 400"
try {
    $null = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body (@{ status = "INVALID_STATUS" } | ConvertTo-Json)
    throw "Validation failed: Invalid status accepted!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "PASS: 400 Bad Request as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 6. Negative current page -> 400
Write-Host "Test: Negative current page -> Expected 400"
try {
    $null = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body (@{ currentPage = -5 } | ConvertTo-Json)
    throw "Validation failed: Negative page accepted!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "PASS: 400 Bad Request as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 7. Current page exceeds total pages -> 400
Write-Host "Test: Current page exceeds total pages -> Expected 400"
try {
    $null = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/reading" -Headers $headers -ContentType "application/json" -Body (@{ currentPage = 400; totalPages = 300 } | ConvertTo-Json)
    throw "Validation failed: Page exceeding total pages accepted!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "PASS: 400 Bad Request as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 8. Rating greater than 5 -> 400
Write-Host "Test: Rating greater than 5 -> Expected 400"
try {
    $null = Invoke-RestMethod -Method Put -Uri "$baseUrl/api/v1/books/$bookId/review" -Headers $headers -ContentType "application/json" -Body (@{ rating = 6; review = "Way too high" } | ConvertTo-Json)
    throw "Validation failed: Rating 6 accepted!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "PASS: 400 Bad Request as expected." -ForegroundColor Green
    } else { throw $_ }
}

# 9. Duplicate shelf name for same user -> 409
Write-Host "Test: Duplicate shelf name for same user -> Expected 409"
try {
    $null = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/shelves" -Headers $headers -ContentType "application/json" -Body (@{ name = "Dark Academia" } | ConvertTo-Json)
    throw "Conflict failed: Duplicate shelf name allowed!"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host "PASS: 409 Conflict as expected." -ForegroundColor Green
    } else { throw $_ }
}

# =====================================================================
# Cleanup Test Data
# =====================================================================
Write-Host "`n--- CLEANUP TEST DATA ---" -ForegroundColor Yellow
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/books/$bookId" -Headers $headers
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/shelves/$shelfId" -Headers $headers
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/shelves/$($shelfB.id)" -Headers $headersB
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/collections/$childId" -Headers $headers
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/collections/$parentId" -Headers $headers
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/collections/$($collB.id)" -Headers $headersB
Write-Host "PASS: Cleaned up test book, shelves, and collections." -ForegroundColor Green

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host "   ALL STEP 6 TESTS PASSED SUCCESSFULLY! (100% PASS)" -ForegroundColor Green
Write-Host "=======================================================`n" -ForegroundColor Green
