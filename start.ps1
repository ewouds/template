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

    [string]$Description = "",

    [bool]$Private = $true,

    [string]$UseTemplate = "https://github.com/ewouds/template",

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

# --- INIT OR TEMPLATE CLONE ---
Write-Host "📦 Creating repo from template '$UseTemplate'..."
gh repo create $Name --template $UseTemplate --$Visibility --description "$Description" --clone
Set-Location $Name

# --- OPEN IN VS CODE ---
if ($OpenVSCode) {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code .
    }
    else {
        Write-Host "💡 VS Code not found in PATH. Skipping..."
    }
}

Write-Host "✅ Project '$Name' created successfully!"
