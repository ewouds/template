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
    [Parameter(Mandatory)]
    [string]$Name,

    [string]$Description = "",

    [switch]$Private,

    [string]$UseTemplate = "",

    [switch]$OpenVSCode
)

# --- PRECHECKS ---
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "❌ GitHub CLI (gh) not found. Install from https://cli.github.com/"
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Git not found. Install from https://git-scm.com/"
    exit 1
}

# --- SET VISIBILITY ---
$Visibility = if ($Private) { "private" } else { "public" }

# --- CREATE LOCAL FOLDER ---
if (-not (Test-Path $Name)) {
    New-Item -ItemType Directory -Path $Name | Out-Null
}
Set-Location $Name

# --- INIT OR TEMPLATE CLONE ---
if ($UseTemplate) {
    Write-Host "📦 Creating repo from template '$UseTemplate'..."
    gh repo create $Name --template $UseTemplate --$Visibility --description "$Description" --clone
    Set-Location $Name
} else {
    git init
    "# $Name`n$Description" | Out-File README.md -Encoding UTF8
    git add .
    git commit -m "Initial commit"
    gh repo create $Name --$Visibility --description "$Description" --source . --remote origin
    git push -u origin main
}

# --- OPEN IN VS CODE ---
if ($OpenVSCode) {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code .
    } else {
        Write-Host "💡 VS Code not found in PATH. Skipping..."
    }
}

Write-Host "✅ Project '$Name' created successfully!"
