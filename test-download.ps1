# Test script to verify download and check encoding
$url = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main/NNTool-Main.ps1"
$content = Invoke-WebRequest -Uri $url -UseBasicParsing
$line400 = ($content.Content -split "`n")[399]
Write-Host "Line 400 contains: $line400"

if ($line400 -like "*&#10004;*") {
    Write-Host "✓ HTML entities are correct" -ForegroundColor Green
} else {
    Write-Host "✗ Still has Unicode characters" -ForegroundColor Red
}