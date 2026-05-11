param(
  [switch]$SeedDemo,
  [switch]$SkipInstall,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $Root "skillmatch-backend-main"
$FrontendDir = Join-Path $Root "skillmatch-frontend-main\talent_link"

$Node = "C:\Program Files\nodejs\node.exe"
$Npm = "C:\Program Files\nodejs\npm.cmd"
$Flutter = "C:\dev\flutter\bin\flutter.bat"

$BackendOut = Join-Path $Root "backend.out.log"
$BackendErr = Join-Path $Root "backend.err.log"
$WebOut = Join-Path $Root "web.out.log"
$WebErr = Join-Path $Root "web.err.log"

function Require-Path {
  param([string]$Path, [string]$Label)
  if (-not (Test-Path $Path)) {
    throw "$Label was not found at: $Path"
  }
}

function Stop-Port {
  param([int]$Port)

  $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
  foreach ($connection in $connections) {
    $processId = $connection.OwningProcess
    if ($processId -and $processId -ne 0) {
      Write-Host "Stopping process $processId on port $Port..."
      Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    }
  }
}

function Wait-ForUrl {
  param([string]$Url, [int]$Seconds = 30)

  $deadline = (Get-Date).AddSeconds($Seconds)
  do {
    try {
      $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return $true
      }
    } catch {
      Start-Sleep -Seconds 1
    }
  } while ((Get-Date) -lt $deadline)

  return $false
}

function Wait-ForBackendHealth {
  param([int]$Seconds = 60)

  $deadline = (Get-Date).AddSeconds($Seconds)
  $lastHealth = $null

  do {
    try {
      $lastHealth = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -TimeoutSec 5
      if (-not $lastHealth.mongoConfigured -or $lastHealth.mongoConnected) {
        return $lastHealth
      }
    } catch {
      Start-Sleep -Seconds 1
    }
  } while ((Get-Date) -lt $deadline)

  return $lastHealth
}

Require-Path $BackendDir "Backend directory"
Require-Path $FrontendDir "Flutter frontend directory"
Require-Path $Node "Node.js"
Require-Path $Npm "npm"
Require-Path $Flutter "Flutter"

$BackendEnv = Join-Path $BackendDir ".env"
$BackendEnvExample = Join-Path $BackendDir ".env.example"
if (-not (Test-Path $BackendEnv) -and (Test-Path $BackendEnvExample)) {
  Copy-Item $BackendEnvExample $BackendEnv
  Write-Host "Created backend .env from .env.example. Check MONGO_URI before using database features."
}

$FrontendEnv = Join-Path $FrontendDir "api.env"
$FrontendEnvExample = Join-Path $FrontendDir "api.env.example"
if (-not (Test-Path $FrontendEnv) -and (Test-Path $FrontendEnvExample)) {
  Copy-Item $FrontendEnvExample $FrontendEnv
  Write-Host "Created frontend api.env from api.env.example."
}

Write-Host ""
Write-Host "Preparing SkillMatch Platform..."

if (-not $SkipInstall) {
  if (-not (Test-Path (Join-Path $BackendDir "node_modules"))) {
    Write-Host "Installing backend dependencies..."
    Push-Location $BackendDir
    & $Npm install
    Pop-Location
  }

  Write-Host "Resolving Flutter dependencies..."
  Push-Location $FrontendDir
  & $Flutter pub get
  Pop-Location
}

Write-Host "Freeing ports 5000 and 5050..."
Stop-Port 5000
Stop-Port 5050

Write-Host "Starting backend on http://localhost:5000..."
Start-Process `
  -FilePath $Node `
  -ArgumentList "server.js" `
  -WorkingDirectory $BackendDir `
  -RedirectStandardOutput $BackendOut `
  -RedirectStandardError $BackendErr `
  -WindowStyle Hidden

$health = Wait-ForBackendHealth 75
if (-not $health) {
  Write-Host "Backend did not become ready. Last backend error log:"
  if (Test-Path $BackendErr) { Get-Content $BackendErr -Tail 60 }
  throw "Backend startup failed."
}

if ($health.mongoConfigured -and -not $health.mongoConnected) {
  Write-Warning "Backend started, but MongoDB is not connected yet."
  Write-Warning "If this stays false, check MongoDB Atlas Network Access and add your current IP address."
  if (Test-Path $BackendErr) { Get-Content $BackendErr -Tail 20 }
}

if ($SeedDemo) {
  Write-Host "Seeding demo data..."
  Push-Location $BackendDir
  & $Npm run seed:demo
  Pop-Location
}

if (-not $SkipBuild) {
  Write-Host "Building Flutter web app..."
  Push-Location $FrontendDir
  & $Flutter build web --no-wasm-dry-run
  Pop-Location
}

Write-Host "Starting web app on http://localhost:5050..."
Start-Process `
  -FilePath $Node `
  -ArgumentList "scripts\serve_web.js" `
  -WorkingDirectory $FrontendDir `
  -RedirectStandardOutput $WebOut `
  -RedirectStandardError $WebErr `
  -WindowStyle Hidden

if (-not (Wait-ForUrl "http://localhost:5050" 30)) {
  Write-Host "Web app did not become ready. Last web error log:"
  if (Test-Path $WebErr) { Get-Content $WebErr -Tail 60 }
  throw "Web startup failed."
}

$health = Invoke-RestMethod -Uri "http://localhost:5000/api/health"

Write-Host ""
Write-Host "SkillMatch Platform is running."
Write-Host "Frontend: http://localhost:5050"
Write-Host "Backend:  http://localhost:5000"
Write-Host "Health:   Mongo configured=$($health.mongoConfigured), connected=$($health.mongoConnected)"
Write-Host ""
Write-Host "Demo accounts, password: 123456"
Write-Host "  organization@demo.com"
Write-Host "  jobseeker@demo.com"
Write-Host "  freelancer@demo.com"
Write-Host "  designer@demo.com"
Write-Host "  developer@demo.com"
Write-Host "  admin@admin.com"
Write-Host ""
Write-Host "Logs:"
Write-Host "  $BackendOut"
Write-Host "  $BackendErr"
Write-Host "  $WebOut"
Write-Host "  $WebErr"
