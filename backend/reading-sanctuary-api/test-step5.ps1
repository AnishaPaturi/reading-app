# =====================================================================
# Reading Sanctuary API - Step 5 Metadata & Cover Verification Script
# =====================================================================

$ErrorActionPreference = "Stop"
$baseUrl = "http://localhost:8080"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   READING SANCTUARY API: STEP 5 METADATA & COVER TEST" -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# Test 1: Log in
# ---------------------------------------------------------------------
Write-Host "[Test 1] Logging in as reader@example.com..." -ForegroundColor Cyan
$loginBody = @{
    email    = "reader@example.com"
    password = "Reader@123"
} | ConvertTo-Json

$login = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/auth/login" -ContentType "application/json" -Body $loginBody
$headers = @{
    Authorization = "Bearer $($login.accessToken)"
}
Write-Host "PASS: Logged in successfully. Token acquired." -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 2: Create an author
# ---------------------------------------------------------------------
Write-Host "`n[Test 2] Creating author 'Alex Michaelides'..." -ForegroundColor Cyan
$authorBody = @{
    name      = "Alex Michaelides"
    biography = "British-Cypriot author and novelist."
} | ConvertTo-Json

# If author already exists from a previous run, fetch it, otherwise create it
try {
    $author = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/authors" -Headers $headers -ContentType "application/json" -Body $authorBody
    Write-Host "PASS: Author created. ID: $($author.id)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host "Author already exists, fetching existing author..." -ForegroundColor Yellow
        $allAuthors = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/authors" -Headers $headers
        $author = $allAuthors | Where-Object { $_.name -eq "Alex Michaelides" } | Select-Object -First 1
        Write-Host "Found existing Author ID: $($author.id)" -ForegroundColor Green
    } else {
        throw $_
    }
}
$authorId = $author.id

# ---------------------------------------------------------------------
# Test 3: Create a genre
# ---------------------------------------------------------------------
Write-Host "`n[Test 3] Creating genre 'Psychological Thriller'..." -ForegroundColor Cyan
$genreBody = @{
    name        = "Psychological Thriller"
    description = "Thrillers focused on psychological tension and suspense."
} | ConvertTo-Json

try {
    $genre = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/genres" -Headers $headers -ContentType "application/json" -Body $genreBody
    Write-Host "PASS: Genre created. ID: $($genre.id)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 409) {
        Write-Host "Genre already exists, fetching existing genre..." -ForegroundColor Yellow
        $allGenres = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/genres" -Headers $headers
        $genre = $allGenres | Where-Object { $_.name -eq "Psychological Thriller" } | Select-Object -First 1
        Write-Host "Found existing Genre ID: $($genre.id)" -ForegroundColor Green
    } else {
        throw $_
    }
}
$genreId = $genre.id

# ---------------------------------------------------------------------
# Test 4: Create a test book
# ---------------------------------------------------------------------
Write-Host "`n[Test 4] Creating test book 'The Silent Patient'..." -ForegroundColor Cyan
$bookBody = @{
    title       = "The Silent Patient"
    description = "A psychological thriller."
} | ConvertTo-Json

$book = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/v1/books" -Headers $headers -ContentType "application/json" -Body $bookBody
$bookId = $book.id
Write-Host "PASS: Book created. ID: $bookId" -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 5: Add metadata to the book
# ---------------------------------------------------------------------
Write-Host "`n[Test 5] Adding metadata to book $bookId..." -ForegroundColor Cyan
$metadataBody = @{
    isbn            = "9781250301697"
    publisher       = "Celadon Books"
    language        = "English"
    publicationDate = "2019-02-05"
    description     = "Alicia Berenson is a famous painter who has not spoken since her husband's death."
    authorIds       = @($authorId)
    genreIds        = @($genreId)
} | ConvertTo-Json -Depth 5

$metadata = Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/v1/books/$bookId/metadata" -Headers $headers -ContentType "application/json" -Body $metadataBody
Write-Host "PASS: Metadata updated successfully." -ForegroundColor Green
Write-Host "Title: $($metadata.title)"
Write-Host "ISBN: $($metadata.isbn)"
Write-Host "Publisher: $($metadata.publisher)"
Write-Host "Authors: $(($metadata.authors | ForEach-Object { $_.name }) -join ', ')"
Write-Host "Genres: $(($metadata.genres | ForEach-Object { $_.name }) -join ', ')"

# ---------------------------------------------------------------------
# Test 6: Retrieve metadata
# ---------------------------------------------------------------------
Write-Host "`n[Test 6] Retrieving metadata..." -ForegroundColor Cyan
$retrievedMeta = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/metadata" -Headers $headers
if ($retrievedMeta.isbn -ne "9781250301697" -or $retrievedMeta.publisher -ne "Celadon Books") {
    throw "Metadata retrieval mismatch!"
}
Write-Host "PASS: Metadata retrieved and verified." -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 7: Upload a book cover
# ---------------------------------------------------------------------
Write-Host "`n[Test 7] Creating a valid test JPEG image and uploading..." -ForegroundColor Cyan
$testImagePath = "$PSScriptRoot\test-cover.jpg"

# Standard valid minimal JPEG binary (SOI, APP0, SOF0, SOS, EOI)
$jpegBytes = [byte[]]@(
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
    0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
    0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
    0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
    0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
    0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
    0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
    0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
    0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
    0x00, 0x7F, 0x00, 0xFF, 0xD9
)
[System.IO.File]::WriteAllBytes($testImagePath, $jpegBytes)

$curlOutput = curl.exe -s -w "%{http_code}" -X POST "$baseUrl/api/v1/books/$bookId/cover" -H "Authorization: Bearer $($login.accessToken)" -F "file=@$testImagePath;type=image/jpeg"
if ($curlOutput -ne "204") {
    throw "Upload cover failed with HTTP status: $curlOutput"
}
Write-Host "PASS: Cover uploaded successfully (HTTP 204)." -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 8: Retrieve the cover
# ---------------------------------------------------------------------
Write-Host "`n[Test 8] Retrieving the cover..." -ForegroundColor Cyan
$downloadedCoverPath = "$PSScriptRoot\downloaded-cover.jpg"
if (Test-Path $downloadedCoverPath) { Remove-Item $downloadedCoverPath -Force }

$getCoverResponse = Invoke-WebRequest -UseBasicParsing -Method Get -Uri "$baseUrl/api/v1/books/$bookId/cover" -Headers $headers -OutFile $downloadedCoverPath
if (-not (Test-Path $downloadedCoverPath)) {
    throw "Downloaded cover file does not exist!"
}
$fileLen = (Get-Item $downloadedCoverPath).Length
Write-Host "PASS: Cover retrieved successfully. Downloaded size: $fileLen bytes." -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 9: Verify metadata contains the cover URL
# ---------------------------------------------------------------------
Write-Host "`n[Test 9] Verifying coverUrl in metadata..." -ForegroundColor Cyan
$metaWithCover = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/books/$bookId/metadata" -Headers $headers
Write-Host "coverUrl: $($metaWithCover.coverUrl)"
Write-Host "coverUpdatedAt: $($metaWithCover.coverUpdatedAt)"
if ($metaWithCover.coverUrl -ne "/api/v1/books/$bookId/cover") {
    throw "Cover URL does not match expected path!"
}
Write-Host "PASS: coverUrl verified." -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 10: Delete the cover
# ---------------------------------------------------------------------
Write-Host "`n[Test 10] Deleting the cover..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/v1/books/$bookId/cover" -Headers $headers
Write-Host "PASS: Cover deleted successfully." -ForegroundColor Green

# ---------------------------------------------------------------------
# Test 11: Verify the cover is deleted
# ---------------------------------------------------------------------
Write-Host "`n[Test 11] Verifying 404 Not Found on deleted cover..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -UseBasicParsing -Method Get -Uri "$baseUrl/api/v1/books/$bookId/cover" -Headers $headers
    throw "Expected 404 Not Found, but request succeeded!"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 404) {
        Write-Host "PASS: Cover deletion verified. HTTP status: $statusCode" -ForegroundColor Green
    } else {
        throw "Unexpected status code on deleted cover: $statusCode"
    }
}

# ---------------------------------------------------------------------
# Test 12: Verify author and genre lists
# ---------------------------------------------------------------------
Write-Host "`n[Test 12] Verifying author and genre lists..." -ForegroundColor Cyan
$authorsList = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/authors" -Headers $headers
$genresList = Invoke-RestMethod -Method Get -Uri "$baseUrl/api/v1/genres" -Headers $headers

Write-Host "Authors:"
$authorsList | Format-Table id, name
Write-Host "Genres:"
$genresList | Format-Table id, name

# Cleanup temporary local test files
if (Test-Path $testImagePath) { Remove-Item $testImagePath -Force }
if (Test-Path $downloadedCoverPath) { Remove-Item $downloadedCoverPath -Force }

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host "   ALL 12 TESTS PASSED SUCCESSFULLY! (STEP 5 COMPLETE)" -ForegroundColor Green
Write-Host "=======================================================`n" -ForegroundColor Green
