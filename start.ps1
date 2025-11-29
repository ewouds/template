<#
.SYNOPSIS
Creates a new GitHub repository and local project folder.

.DESCRIPTION
This script automates the full setup of a new project:
- Creates a local folder
- Initializes git
- Optionally starts from a GitHub template
- Creates a remote repository on GitHub
- Pushes the initial commit
- Opens in VS Code (optional)

.EXAMPLE
.\New-GitProject.ps1 -Name "my-new-app" -Description "Azure automation tool" -Private -UseTemplate "ewoudsmets/app-template"
#>

param(
    [Parameter(Mandatory, HelpMessage = "Enter the name for your new project")]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RootPath = "C:\dev",

    [string]$Description = "",

    [bool]$Private = $true,

    [string]$UseTemplate = "https://github.com/ewouds/template",

    [switch]$OpenVSCode
)

# --- PRECHECKS ---
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "[ERROR] GitHub CLI (gh) not found. Install from https://cli.github.com/"
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "[ERROR] Git not found. Install from https://git-scm.com/"
    exit 1
}

# --- CREATE LOCAL FOLDER ---
$ProjectPath = Join-Path -Path $RootPath -ChildPath $Name
if (Test-Path -Path $ProjectPath) {
    Write-Error "[ERROR] Folder '$ProjectPath' already exists. Choose a different project name."
    exit 1
}
New-Item -ItemType Directory -Path $ProjectPath | Out-Null
Set-Location $ProjectPath

# --- SET VISIBILITY ---
$Visibility = if ($Private) { "private" } else { "public" }

# --- CONFIRMATION ---
Write-Host "`nProject Configuration:" -ForegroundColor Cyan
Write-Host "  Name:        $Name"
Write-Host "  Location:    $ProjectPath"
Write-Host "  Template:    $UseTemplate"
Write-Host "  Visibility:  $Visibility"
Write-Host "  Description: $Description"
Write-Host ""

$Confirmation = Read-Host "Do you want to proceed create a github project? (Y/N)"
if ($Confirmation -ne 'Y' -and $Confirmation -ne 'y') {
    Write-Host "[CANCELLED] Project creation cancelled by user."
    Remove-Item -Path $ProjectPath -Force -ErrorAction SilentlyContinue
    exit 0
}

# --- INIT OR TEMPLATE CLONE ---
Write-Host "[INFO] Creating repo from template '$UseTemplate'..."
gh repo create $Name --template $UseTemplate --$Visibility --description "$Description" --clone

# --- OPEN IN VS CODE ---
if ($OpenVSCode) {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code .
    }
    else {
        Write-Host "[INFO] VS Code not found in PATH. Skipping..."
    }
}

Write-Host "[SUCCESS] Project '$Name' created successfully!"
