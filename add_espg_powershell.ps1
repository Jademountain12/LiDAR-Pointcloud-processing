# PowerShell script for parallel PDAL processing to COPC
# Save this as assign_epsg_copc.ps1

# Set your input and output folders
$INPUT_FOLDER = "C:\Users\gis\Documents\projects\projects\2025-11-22_Pdal_Ground_index\data"
$OUTPUT_FOLDER = "C:\Users\gis\Documents\projects\projects\2025-11-22_Pdal_Ground_index\data_copc"

# Set number of parallel jobs (adjust based on your CPU cores)
$MaxThreads = 8

# Create output folder if it doesn't exist
if (-not (Test-Path $OUTPUT_FOLDER)) {
    Write-Host "Creating output folder..."
    New-Item -ItemType Directory -Path $OUTPUT_FOLDER -Force | Out-Null
}

# Get all LAZ files
$files = Get-ChildItem -Path $INPUT_FOLDER -Filter "*.laz"

Write-Host "Found $($files.Count) files to process"
Write-Host "Using $MaxThreads parallel threads"
Write-Host ""

# Process files in parallel using Start-Job
$jobs = @()
foreach ($file in $files) {
    # Wait if we've hit the max number of parallel jobs
    while ((Get-Job -State Running).Count -ge $MaxThreads) {
        Start-Sleep -Milliseconds 200
    }
    
    Write-Host "Starting job for $($file.Name)"
    
    $jobs += Start-Job -ScriptBlock {
        param($inputFile, $outputFolder, $fileName)
        
        # Change extension to .copc.laz
        $outputFileName = $fileName -replace '\.laz$', '.copc.laz'
        $outputFile = Join-Path $outputFolder $outputFileName
        
        pdal translate $inputFile $outputFile --writers.copc.a_srs="EPSG:27700"
        
        return "Completed: $outputFileName"
    } -ArgumentList $file.FullName, $OUTPUT_FOLDER, $file.Name
}

# Wait for all jobs to complete and show output
Write-Host ""
Write-Host "Waiting for all jobs to complete..."
$jobs | Wait-Job | ForEach-Object {
    $result = Receive-Job -Job $_
    Write-Host $result
    Remove-Job -Job $_
}

Write-Host ""
Write-Host "All files processed!"

# Verify output
$outputFiles = Get-ChildItem $OUTPUT_FOLDER -Filter "*.copc.laz"
Write-Host "Output folder contains $($outputFiles.Count) COPC files"