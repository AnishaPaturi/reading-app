# =====================================================================
# Reading Sanctuary API - Step 3 Complete Verification Script
# =====================================================================

$ErrorActionPreference = "Stop"

function Get-StatusCode($ex) {
    if ($ex.Response -and $ex.Response.StatusCode) {
        return [int]$ex.Response.StatusCode
    }
    return $null
}

$results = [ordered]@{}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   READING SANCTUARY API: STEP 3 VERIFICATION TEST" -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# 1. Register User A
# ---------------------------------------------------------------------
Write-Host "[1/10] Registering User A..." -ForegroundColor Cyan
$regUserABody = @{
    email    = "reader@example.com"
    password = "Reader@123"
} | ConvertTo-Json

$regUserAParams = @{
    Uri         = "http://localhost:8080/api/v1/users/register"
    Method      = "POST"
    ContentType = "application/json"
    Body        = $regUserABody
}

try {
    $null = Invoke-RestMethod @regUserAParams
    $results["1. Register User A"] = "201 Created"
    Write-Host "PASS: User A registered (201 Created)" -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    if ($code -eq 409) {
        $results["1. Register User A"] = "409 (Already Registered)"
        Write-Host "INFO: User A already exists (409 Conflict), continuing to login." -ForegroundColor Yellow
    } else {
        $results["1. Register User A"] = "FAILED ($code)"
        Write-Host "FATAL: User A registration failed ($code): $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

# ---------------------------------------------------------------------
# 2. Login User A
# ---------------------------------------------------------------------
Write-Host "`n[2/10] Logging in as User A..." -ForegroundColor Cyan
$loginUserABody = @{
    email    = "reader@example.com"
    password = "Reader@123"
} | ConvertTo-Json

$loginUserAParams = @{
    Uri         = "http://localhost:8080/api/v1/auth/login"
    Method      = "POST"
    ContentType = "application/json"
    Body        = $loginUserABody
}

try {
    $loginUserARes = Invoke-RestMethod @loginUserAParams
    $tokenA = $loginUserARes.accessToken
    $headersA = @{ Authorization = "Bearer $tokenA" }
    $results["2. Login User A"] = "200 OK"
    Write-Host "PASS: User A login successful (200 OK). JWT stored." -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    $results["2. Login User A"] = "FAILED ($code)"
    Write-Host "FATAL: User A login failed ($code): $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

# ---------------------------------------------------------------------
# 3. Create Book as User A
# ---------------------------------------------------------------------
Write-Host "`n[3/10] Creating Book (The Silent Patient)..." -ForegroundColor Cyan
$createBookBody = @{
    title           = "The Silent Patient"
    description     = "A psychological thriller."
    language        = "English"
    publisher       = "Celadon Books"
    publicationDate = "2019-02-05"
    isbn            = "9781250301697"
} | ConvertTo-Json

$createBookParams = @{
    Uri         = "http://localhost:8080/api/v1/books"
    Method      = "POST"
    Headers     = $headersA
    ContentType = "application/json"
    Body        = $createBookBody
}

try {
    $createdBook = Invoke-RestMethod @createBookParams
    $bookId = $createdBook.id
    $results["3. Create Book"] = "201 Created (ID: $bookId)"
    Write-Host "PASS: Book created (201 Created). ID: $bookId" -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    $results["3. Create Book"] = "FAILED ($code)"
    Write-Host "FATAL: Create book failed ($code): $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

# ---------------------------------------------------------------------
# 4. Retrieve All Books for User A
# ---------------------------------------------------------------------
Write-Host "`n[4/10] Retrieving all books for User A..." -ForegroundColor Cyan
$getAllBooksParams = @{
    Uri     = "http://localhost:8080/api/v1/books"
    Method  = "GET"
    Headers = $headersA
}

try {
    $allBooks = Invoke-RestMethod @getAllBooksParams
    $count = @($allBooks).Count
    $results["4. Retrieve All Books"] = "200 OK (Count: $count)"
    Write-Host "PASS: Retrieved $count book(s) (200 OK)" -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    $results["4. Retrieve All Books"] = "FAILED ($code)"
    Write-Host "FATAL: Retrieve all books failed ($code): $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

# ---------------------------------------------------------------------
# 5. Retrieve One Book by ID for User A
# ---------------------------------------------------------------------
Write-Host "`n[5/10] Retrieving book by ID ($bookId)..." -ForegroundColor Cyan
$getOneBookParams = @{
    Uri     = "http://localhost:8080/api/v1/books/$bookId"
    Method  = "GET"
    Headers = $headersA
}

try {
    $oneBook = Invoke-RestMethod @getOneBookParams
    $results["5. Retrieve One Book"] = "200 OK"
    Write-Host "PASS: Retrieved book title '$($oneBook.title)' (200 OK)" -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    $results["5. Retrieve One Book"] = "FAILED ($code)"
    Write-Host "FATAL: Retrieve one book failed ($code): $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

# ---------------------------------------------------------------------
# 6. Update Book
# ---------------------------------------------------------------------
Write-Host "`n[6/10] Updating book details..." -ForegroundColor Cyan
$updateBookBody = @{
    title           = "The Silent Patient - Updated"
    description     = "Updated description for testing."
    language        = "English"
    publisher       = "Celadon Books"
    publicationDate = "2019-02-05"
    isbn            = "9781250301697"
} | ConvertTo-Json

$updateBookParams = @{
    Uri         = "http://localhost:8080/api/v1/books/$bookId"
    Method      = "PUT"
    Headers     = $headersA
    ContentType = "application/json"
    Body        = $updateBookBody
}

try {
    $updatedBook = Invoke-RestMethod @updateBookParams
    $results["6. Update Book"] = "200 OK"
    Write-Host "PASS: Book updated to '$($updatedBook.title)' (200 OK)" -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    $results["6. Update Book"] = "FAILED ($code)"
    Write-Host "FATAL: Update book failed ($code): $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

# ---------------------------------------------------------------------
# 7. Delete Book & Verify 404
# ---------------------------------------------------------------------
Write-Host "`n[7/10] Deleting book and verifying 404..." -ForegroundColor Cyan
$deleteBookParams = @{
    Uri     = "http://localhost:8080/api/v1/books/$bookId"
    Method  = "DELETE"
    Headers = $headersA
}

try {
    Invoke-RestMethod @deleteBookParams
    Write-Host "PASS: Delete returned 204 No Content" -ForegroundColor Green
    $results["7. Delete Book"] = "204 No Content"
} catch {
    $code = Get-StatusCode $_.Exception
    $results["7. Delete Book"] = "FAILED ($code)"
    Write-Host "FATAL: Delete book failed ($code): $($_.Exception.Message)" -ForegroundColor Red
    throw $_
}

# Verify GET returns 404
try {
    Invoke-RestMethod @getOneBookParams
    $results["8. Verify Deleted Book (404)"] = "FAILED (Still Accessible)"
    Write-Host "FAIL: Deleted book was still returned!" -ForegroundColor Red
} catch {
    $code = Get-StatusCode $_.Exception
    if ($code -eq 404) {
        $results["8. Verify Deleted Book (404)"] = "200 OK (404 Confirmed)"
        Write-Host "PASS: Verified deleted book returns 404 Not Found" -ForegroundColor Green
    } else {
        $results["8. Verify Deleted Book (404)"] = "FAILED ($code)"
        Write-Host "FAIL: Expected 404, received $code" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------
# 8. Test Unauthenticated Access (401)
# ---------------------------------------------------------------------
Write-Host "`n[8/10] Testing unauthenticated request (expecting 401)..." -ForegroundColor Cyan
$unauthParams = @{
    Uri    = "http://localhost:8080/api/v1/books"
    Method = "GET"
}

try {
    Invoke-RestMethod @unauthParams
    $results["9. Access Without JWT (401)"] = "FAILED (Permitted)"
    Write-Host "FAIL: Unauthenticated request was unexpectedly allowed!" -ForegroundColor Red
} catch {
    $code = Get-StatusCode $_.Exception
    if ($code -eq 401) {
        $results["9. Access Without JWT (401)"] = "PASS (401 Confirmed)"
        Write-Host "PASS: Unauthenticated request rejected (401 Unauthorized)" -ForegroundColor Green
    } else {
        $results["9. Access Without JWT (401)"] = "FAILED ($code)"
        Write-Host "FAIL: Expected 401, received $code" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------
# 9. Test User Isolation (User B)
# ---------------------------------------------------------------------
Write-Host "`n[9/10] Testing User Isolation..." -ForegroundColor Cyan

# Register User B
$regUserBBody = @{
    email    = "reader2@example.com"
    password = "Reader@456"
} | ConvertTo-Json

$regUserBParams = @{
    Uri         = "http://localhost:8080/api/v1/users/register"
    Method      = "POST"
    ContentType = "application/json"
    Body        = $regUserBBody
}

try {
    $null = Invoke-RestMethod @regUserBParams
    Write-Host "PASS: User B registered (201 Created)" -ForegroundColor Green
} catch {
    $code = Get-StatusCode $_.Exception
    if ($code -eq 409) {
        Write-Host "INFO: User B already registered (409 Conflict), continuing to login." -ForegroundColor Yellow
    } else {
        Write-Host "FATAL: User B registration failed ($code): $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

# Login User B
$loginUserBBody = @{
    email    = "reader2@example.com"
    password = "Reader@456"
} | ConvertTo-Json

$loginUserBParams = @{
    Uri         = "http://localhost:8080/api/v1/auth/login"
    Method      = "POST"
    ContentType = "application/json"
    Body        = $loginUserBBody
}

$loginUserBRes = Invoke-RestMethod @loginUserBParams
$tokenB = $loginUserBRes.accessToken
$headersB = @{ Authorization = "Bearer $tokenB" }
Write-Host "PASS: User B login successful (200 OK)" -ForegroundColor Green

# Create fresh test book under User A
$isolationBookBody = @{
    title    = "User Isolation Test"
    language = "English"
} | ConvertTo-Json

$createIsolationParams = @{
    Uri         = "http://localhost:8080/api/v1/books"
    Method      = "POST"
    Headers     = $headersA
    ContentType = "application/json"
    Body        = $isolationBookBody
}

$userABook = Invoke-RestMethod @createIsolationParams
$userABookId = $userABook.id
Write-Host "PASS: Created test book under User A (ID: $userABookId)" -ForegroundColor Green

# User B attempts to access User A's book (Expect 404)
$userBAccessParams = @{
    Uri     = "http://localhost:8080/api/v1/books/$userABookId"
    Method  = "GET"
    Headers = $headersB
}

try {
    Invoke-RestMethod @userBAccessParams
    $results["10. User B Accesses User A Book (404)"] = "FAILED (Breach)"
    Write-Host "FAIL: User B was able to view User A's book!" -ForegroundColor Red
} catch {
    $code = Get-StatusCode $_.Exception
    if ($code -eq 404) {
        $results["10. User B Accesses User A Book (404)"] = "PASS (404 Confirmed)"
        Write-Host "PASS: User B received 404 Not Found trying to access User A's book" -ForegroundColor Green
    } else {
        $results["10. User B Accesses User A Book (404)"] = "FAILED ($code)"
        Write-Host "FAIL: Expected 404, received $code" -ForegroundColor Red
    }
}

# User B retrieves all books (Expect Empty)
$userBListParams = @{
    Uri     = "http://localhost:8080/api/v1/books"
    Method  = "GET"
    Headers = $headersB
}

$userBBooks = Invoke-RestMethod @userBListParams
$userBCount = @($userBBooks).Count
if ($userBCount -eq 0) {
    $results["11. User B Books Empty"] = "PASS (Empty List)"
    Write-Host "PASS: User B library has 0 books (isolated from User A)" -ForegroundColor Green
} else {
    $results["11. User B Books Empty"] = "FAILED ($userBCount books found)"
    Write-Host "FAIL: User B sees $userBCount books in their library!" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 10. Clean up test book under User A
# ---------------------------------------------------------------------
Write-Host "`n[10/10] Cleaning up test book as User A..." -ForegroundColor Cyan
$cleanupParams = @{
    Uri     = "http://localhost:8080/api/v1/books/$userABookId"
    Method  = "DELETE"
    Headers = $headersA
}

Invoke-RestMethod @cleanupParams
$results["12. Cleanup Test Book"] = "204 No Content"
Write-Host "PASS: Cleaned up test book (204 No Content)" -ForegroundColor Green

# ---------------------------------------------------------------------
# Final Results Table
# ---------------------------------------------------------------------
Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "                  FINAL TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
$results.GetEnumerator() | Format-Table -Property @{Label="Test Name"; Expression={$_.Key}}, @{Label="Result"; Expression={$_.Value}}
