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
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$RootPath = "C:\dev",

    [string]$Description = "",

    [bool]$Private = $true,

    [string]$UseTemplate = "https://github.com/ewouds/template"
)

# Clear screen for clean display
Clear-Host

# --- HEADER ---
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "           GitHub Project Setup & Initialization" -ForegroundColor Cyan
Write-Host "                     v1.0.0" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# --- INTERACTIVE PARAMETER COLLECTION ---
if (-not $Name) {
    Write-Host ">> Project Information" -ForegroundColor Yellow
    Write-Host ""
    
    $ValidName = $false
    while (-not $ValidName) {
        Write-Host "   Project Name: " -ForegroundColor Cyan -NoNewline
        $Name = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($Name)) {
            Write-Host "   [X] Project name cannot be empty! Please try again." -ForegroundColor Red
            Write-Host ""
            continue
        }
        
        $TestPath = Join-Path -Path $RootPath -ChildPath $Name
        if (Test-Path -Path $TestPath) {
            Write-Host "   [X] Project '$Name' already exists at $TestPath" -ForegroundColor Red
            Write-Host "   Please choose a different name." -ForegroundColor Yellow
            Write-Host ""
            continue
        }
        
        $ValidName = $true
    }
    Write-Host ""
}

# --- PRECHECKS ---
Write-Host ">> System Prerequisites Check" -ForegroundColor Yellow
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "   [X] GitHub CLI (gh)" -ForegroundColor Red
    Write-Host ""
    Write-Error "GitHub CLI not found. Install from https://cli.github.com/"
    exit 1
}
else {
    Write-Host "   [OK] GitHub CLI (gh)" -ForegroundColor Green
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "   [X] Git" -ForegroundColor Red
    Write-Host ""
    Write-Error "Git not found. Install from https://git-scm.com/"
    exit 1
}
else {
    Write-Host "   [OK] Git" -ForegroundColor Green
}
Write-Host "   All prerequisites met!" -ForegroundColor Green
Write-Host ""

# --- CREATE LOCAL FOLDER ---
Write-Host ">> Project Setup" -ForegroundColor Yellow
$ProjectPath = Join-Path -Path $RootPath -ChildPath $Name

# --- SET VISIBILITY ---
$Visibility = if ($Private) { "private" } else { "public" }

# --- CONFIRMATION ---
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "                  Project Configuration" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Name:        $Name" -ForegroundColor White
Write-Host " Location:    $ProjectPath" -ForegroundColor White
Write-Host " Template:    $UseTemplate" -ForegroundColor White
Write-Host " Visibility:  $Visibility" -ForegroundColor $(if ($Private) { "Yellow" }else { "Green" })
Write-Host " Description: $Description" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "Do you want to create a GitHub repository? (Y/N/S for Skip): " -ForegroundColor Yellow -NoNewline
$GitHubConfirmation = Read-Host

if ($GitHubConfirmation -eq "N" -or $GitHubConfirmation -eq "n") {
    Write-Host ""
    Write-Host "X Project creation cancelled by user." -ForegroundColor Red
    Remove-Item -Path $ProjectPath -Force -ErrorAction SilentlyContinue
    Write-Host ""
    exit 0
}

$CreateGitHub = ($GitHubConfirmation -eq "Y" -or $GitHubConfirmation -eq "y")
Write-Host ""

# --- INIT OR TEMPLATE CLONE ---
if ($CreateGitHub) {
    Write-Host ">> GitHub Repository Creation" -ForegroundColor Yellow
    Write-Host "   Creating repo from template..." -ForegroundColor Cyan
    
    # Ensure we're in the root path
    Set-Location $RootPath
    
    # Create the repository and clone it
    gh repo create $Name --template $UseTemplate --$Visibility --description "$Description" --clone
    Write-Host "   [OK] Repository created" -ForegroundColor Green
    
    # Verify the clone worked, if not clone manually
    if (-not (Test-Path $ProjectPath)) {
        Write-Host "   Cloning repository..." -ForegroundColor Cyan
        git clone "https://github.com/$((gh api user --jq .login))/$Name.git" $ProjectPath
    }
    
    Write-Host "   [OK] Repository cloned to $ProjectPath" -ForegroundColor Green
    Write-Host ""
    
    # Navigate into the cloned repository
    Set-Location $ProjectPath
    
    # Delete start.ps1 if it exists
    Write-Host ">> Cleaning Up Template Files" -ForegroundColor Yellow
    if (Test-Path "start.ps1") {
        Write-Host "   Removing start.ps1 from cloned repo..." -ForegroundColor Cyan
        Remove-Item "start.ps1" -Force
        Write-Host "   [OK] start.ps1 removed" -ForegroundColor Green
        
        # Commit and push changes
        Write-Host "   Committing changes..." -ForegroundColor Cyan
        git add -A
        git commit -m "Remove start.ps1 from template"
        Write-Host "   [OK] Changes committed" -ForegroundColor Green
        
        Write-Host "   Syncing with remote..." -ForegroundColor Cyan
        git push
        Write-Host "   [OK] Changes pushed to remote" -ForegroundColor Green
    }
    else {
        Write-Host "   [OK] No start.ps1 found in template" -ForegroundColor Green
    }
    Write-Host ""
}
else {
    Write-Host "   Creating project directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ProjectPath | Out-Null
    Set-Location $ProjectPath
    Write-Host "   [OK] Directory created: $ProjectPath" -ForegroundColor Green
    Write-Host ""
    
    Write-Host ">> Initializing Local Git Repository" -ForegroundColor Yellow
    Write-Host "   Skipping GitHub repository creation..." -ForegroundColor Cyan
    git init
    Write-Host "   [OK] Local git repository initialized" -ForegroundColor Green
    Write-Host ""
}

# --- CREATE VSCODE WORKSPACE ---
Write-Host ">> Creating VS Code Workspace" -ForegroundColor Yellow
$WorkspaceFile = "$Name.code-workspace"
$WorkspaceContent = @{
    folders  = @(
        @{
            path = "."
        }
    )
    settings = @{
        "files.exclude" = @{
            "**/.git" = $false
        }
    }
} | ConvertTo-Json -Depth 10

Set-Content -Path $WorkspaceFile -Value $WorkspaceContent -Encoding UTF8
Write-Host "   [OK] Workspace file created: $WorkspaceFile" -ForegroundColor Green
Write-Host ""

# --- OPEN IN VS CODE ---
Write-Host ">> Opening in VS Code" -ForegroundColor Yellow
if (Get-Command code -ErrorAction SilentlyContinue) {
    code $WorkspaceFile
    Write-Host "   [OK] VS Code workspace opened" -ForegroundColor Green
}
else {
    Write-Host "   [X] VS Code not found in PATH" -ForegroundColor Red
}
Write-Host ""


# --- SUCCESS ---
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "                     SUCCESS!" -ForegroundColor Green
Write-Host ""
Write-Host "  Project ""$Name"" has been created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""