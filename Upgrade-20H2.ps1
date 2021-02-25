<#
    Download and silently upgrade to Windows 10 20H2
#>

#================================================================================
# User Variables / Configuration
#================================================================================

# Application name (this will be used to check if application already installed)
$name = "Windows 10"

# Download URL (redirects will be followed)
$dlurl = 'https://go.microsoft.com/fwlink/?LinkID=799445'

# Installer filename (can be blank if download isn't a zip, wildcards allowed)
$installer = "Windows10Upgrade*.exe"

# Arguments to use for installer (can be blank)
$arg = "/QuietInstall /SkipEULA /SkipSelfUpdate /ShowOOBE none"

# Disk space required in MB (leave blank for no requirement)
$diskspacerequired = '11000'

# Temporary storage location (no trailing \)
$homepath = "c:\windows\temp"

#================================================================================
# Operations
#================================================================================

Write-Output "$name installation starting..."

Write-Output "Checking disk space..."
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" | Select-Object FreeSpace
$disk = ([Math]::Round($Disk.Freespace / 1MB))
if ($disk -lt $diskspacerequired) {
    write-output "$name requires $diskspacerequired MB to install but there's only $disk MB free."
    exit 1
}

# Test for home directory and create if it doesn't exist
if (-not (Test-Path $homepath)) { mkdir $homepath | Out-Null }
Set-Location $homepath

# Prevent "You can’t install Windows on a USB flash drive using Setup" Error
if (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'PortableOperatingSystem') {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'PortableOperatingSystem' -Value 0
}

# Retrieve headers to make sure we have the final destination redirected file URL
$dlurl = (Invoke-WebRequest -UseBasicParsing -Uri $dlurl -MaximumRedirection 0 -ErrorAction Ignore).headers.location
Write-Output "Downloading: $dlurl"
$dlfilename = [io.path]::GetFileName("$dlurl")
(New-Object Net.WebClient).DownloadFile("$dlurl", "$homepath\$dlfilename")

# Use GCI to determine filename in case wildcards are used
$installer = (Get-ChildItem $installer).Name
Write-Output "Installing: $homepath\$installer $arg"
Start-Process "$installer" -ArgumentList "$arg"

# Remove installer file
Write-Output "Cleaning up..."
Start-Sleep -s 60
Remove-Item $installer -Force
    
# End of Script