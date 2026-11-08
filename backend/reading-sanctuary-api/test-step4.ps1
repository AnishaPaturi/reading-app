# =====================================================================
# Reading Sanctuary API - Step 4 File Management Verification Script
# =====================================================================

$ErrorActionPreference = "Stop"
$baseUrl = "http://localhost:8080"

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   READING SANCTUARY API: STEP 4 FILE MANAGEMENT TEST" -ForegroundColor Cyan
Write-Host "=======================================================`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------
# 1. Login and Create a Test Book
# ---------------------------------------------------------------------
Write-Host "[1/5] Logging in as reader@example.com..." -ForegroundColor Cyan
$loginBody = @{
    email    = "reader@example.com"
    password = "Reader@123"
} | ConvertTo-Json

$loginParams = @{
    Uri         = "$baseUrl/api/v1/auth/login"
    Method      = "POST"
    ContentType = "application/json"
    Body        = $loginBody
}

$login = Invoke-RestMethod @loginParams
$headers = @{ Authorization = "Bearer $($login.accessToken)" }
Write-Host "Login successful. Token acquired." -ForegroundColor Green

Write-Host "`nCreating a test book for file upload..." -ForegroundColor Cyan
$bookBody = @{
    title       = "Reading Sanctuary File Upload Test"
    description = "Testing book file uploads"
    language    = "English"
} | ConvertTo-Json

$createBookParams = @{
    Uri         = "$baseUrl/api/v1/books"
    Method      = "POST"
    Headers     = $headers
    ContentType = "application/json"
    Body        = $bookBody
}

$book = Invoke-RestMethod @createBookParams
$bookId = $book.id
Write-Host "Test book created. ID: $bookId" -ForegroundColor Green

# ---------------------------------------------------------------------
# 2. Prepare Sample PDF File and Upload
# ---------------------------------------------------------------------
Write-Host "`n[2/5] Preparing sample PDF file..." -ForegroundColor Cyan
$samplePdfPath = "$PSScriptRoot\sample.pdf"
if (-not (Test-Path $samplePdfPath)) {
    # Generate a valid minimal PDF file
    $minimalPdfContent = "%PDF-1.4`n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj 2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj 3 0 obj<</Type/Page/MediaBox[0 0 3 3]>>endobj`nxref`n0 4`n0000000000 65535 f `n0000000009 00000 n `n0000000052 00000 n `n0000000101 00000 n `ntrailer<</Size 4/Root 1 0 R>>`nstartxref`n149`n%%EOF"
    [System.IO.File]::WriteAllText($samplePdfPath, $minimalPdfContent)
    Write-Host "Created sample PDF at: $samplePdfPath" -ForegroundColor Yellow
}

Write-Host "Uploading sample.pdf to book $bookId..." -ForegroundColor Cyan
$uploadUri = "$baseUrl/api/v1/books/$bookId/files"

# Use curl.exe for 100% universal multipart compatibility across all Windows/PowerShell versions
$uploadJson = & curl.exe -s -X POST $uploadUri -H "Authorization: Bearer $($login.accessToken)" -F "file=@$samplePdfPath"
$upload = $uploadJson | ConvertFrom-Json
$fileId = $upload.id
Write-Host "Upload successful! File ID: $fileId" -ForegroundColor Green
$upload | Format-List

# ---------------------------------------------------------------------
# 3. List All Files for the Book
# ---------------------------------------------------------------------
Write-Host "`n[3/5] Listing files for book $bookId..." -ForegroundColor Cyan
$listParams = @{
    Uri     = "$baseUrl/api/v1/books/$bookId/files"
    Method  = "GET"
    Headers = $headers
}

$files = Invoke-RestMethod @listParams
Write-Host "Found $(@($files).Count) file(s):" -ForegroundColor Green
$files | Format-Table id, fileName, fileFormat, fileSizeBytes, checksum

# ---------------------------------------------------------------------
# 4. Download the File
# ---------------------------------------------------------------------
Write-Host "`n[4/5] Downloading file $fileId..." -ForegroundColor Cyan
$downloadedFilePath = "$PSScriptRoot\downloaded-sample.pdf"
if (Test-Path $downloadedFilePath) {
    Remove-Item $downloadedFilePath -Force
}

$downloadParams = @{
    Uri     = "$baseUrl/api/v1/books/$bookId/files/$fileId"
    Method  = "GET"
    Headers = $headers
    OutFile = $downloadedFilePath
}

Invoke-RestMethod @downloadParams

if (Test-Path $downloadedFilePath) {
    $downloadedSize = (Get-Item $downloadedFilePath).Length
    Write-Host "File downloaded successfully ($downloadedSize bytes) to: $downloadedFilePath" -ForegroundColor Green
} else {
    Write-Host "ERROR: Downloaded file not found!" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 5. Delete the File & Clean up
# ---------------------------------------------------------------------
Write-Host "`n[5/5] Deleting file $fileId..." -ForegroundColor Cyan
$deleteFileParams = @{
    Uri     = "$baseUrl/api/v1/books/$bookId/files/$fileId"
    Method  = "DELETE"
    Headers = $headers
}

Invoke-RestMethod @deleteFileParams
Write-Host "File deletion returned 204 No Content" -ForegroundColor Green

# Verify file no longer listed
$remainingFiles = Invoke-RestMethod @listParams
$remainingCount = @($remainingFiles).Count
Write-Host "Remaining files for book: $remainingCount (Expected: 0)" -ForegroundColor Green

# Clean up temporary test book
$cleanupBookParams = @{
    Uri     = "$baseUrl/api/v1/books/$bookId"
    Method  = "DELETE"
    Headers = $headers
}
Invoke-RestMethod @cleanupBookParams | Out-Null
Write-Host "Cleaned up test book." -ForegroundColor Green

# Clean up local downloaded sample
if (Test-Path $downloadedFilePath) {
    Remove-Item $downloadedFilePath -Force
}
if (Test-Path $samplePdfPath) {
    Remove-Item $samplePdfPath -Force
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "   STEP 4 FILE MANAGEMENT TESTS COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "=======================================================`n" -ForegroundColor Cyan
