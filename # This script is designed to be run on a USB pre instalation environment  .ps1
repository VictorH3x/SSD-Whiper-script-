# This script is designed to be run in a Windows Preinstallation Environment (WinPE)
# DO NOT RUN THIS SCRIPT FROM YOUR LIVE OPERATING SYSTEM.
#
# IMPORTANT: This script will perform an irreversible data wipe.
# Proceed only after backing up any data you wish to keep.

# --- Log file setup ---
$logTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = ".\Safe-Disk-Wipe_$logTimestamp.log"

# Function to write to both the host and the log file
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
    $Message | Out-File -FilePath $logFilePath -Append -Encoding utf8
}

Write-Log "Starting a new log for the disk wipe process on $($logTimestamp)..."

# --- Step 1: Display all disks for user verification ---
Write-Log "----------------------------------------------"
Write-Log "   WARNING: IRREVERSIBLE DATA LOSS IMMINENT!   " -ForegroundColor Red
Write-Log "----------------------------------------------"
Write-Log "Please review the list of disks below carefully."
Write-Log "You must identify the disk you want to wipe."
Write-Log "The wipe will DELETE ALL DATA on the selected disk."
Write-Log ""
Write-Log "Running: diskpart list disk"
Write-Log "----------------------------------------------"

# Run diskpart to list all disks and display the output
$diskpartOutput = & diskpart /s (Get-Content -LiteralPath '.\listdisk.txt' -Raw)
Write-Log $diskpartOutput

# --- Step 2: Prompt user for disk selection ---
Write-Log "----------------------------------------------"
$diskNumber = Read-Host "Enter the number of the disk you want to wipe (e.g., 0, 1, 2) and press Enter"
Write-Log "User selected disk: $diskNumber"

# --- Step 3: Prompt for final confirmation ---
$confirmation = Read-Host "Are you ABSOLUTELY SURE you want to clean all data on Disk $diskNumber? Type 'YES' to proceed"
Write-Log "User confirmation: $confirmation"

if ($confirmation -eq "YES") {
    # Create a temporary script for diskpart to execute
    $diskpartScript = "select disk $diskNumber`nclean all`nexit"
    $diskpartScript | Out-File -FilePath '.\wipe.txt' -Encoding ascii

    Write-Log "Starting irreversible wipe on Disk $diskNumber..." -ForegroundColor Yellow
    Write-Log "This process may take a very long time with no progress bar." -ForegroundColor Yellow
    Write-Log "DO NOT POWER OFF THE COMPUTER." -ForegroundColor Red

    # --- Step 4: Execute the diskpart command with the user-provided input ---
    $wipeOutput = & diskpart /s .\wipe.txt
    Write-Log $wipeOutput

    if ($wipeOutput -like "*succeeded in cleaning*") {
        Write-Log "----------------------------------------------"
        Write-Log "        DISK WIPE SUCCESSFUL!        " -ForegroundColor Green
        Write-Log "Data on Disk $diskNumber has been overwritten." -ForegroundColor Green
        Write-Log "----------------------------------------------"
    } else {
        Write-Log "----------------------------------------------"
        Write-Log "    DISK WIPE FAILED OR HAD ERRORS.    " -ForegroundColor Red
        Write-Log "Please check the output above for details." -ForegroundColor Red
        Write-Log "----------------------------------------------"
    }

    # Clean up temporary script files
    Remove-Item -Path '.\wipe.txt' -Force
    Remove-Item -Path '.\listdisk.txt' -Force
    Write-Log "Temporary files have been cleaned up."

} else {
    Write-Log "Process canceled by user. No disks were wiped." -ForegroundColor Cyan
}

# Keep the console open for the user to review the final message
Read-Host "Press Enter to exit"

