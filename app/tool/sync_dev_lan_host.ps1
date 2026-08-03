# Syncs the PC's current LAN IPv4 into app/.env for local API hosts.
# Usage (from repo or app/):
#   powershell -ExecutionPolicy Bypass -File app/tool/sync_dev_lan_host.ps1
#   powershell -ExecutionPolicy Bypass -File app/tool/sync_dev_lan_host.ps1 -Ip 192.168.1.42
#
# Then hot-restart (or full restart) the Flutter app so dotenv reloads.

param(
  [string]$Ip = '',
  [string]$EnvFile = ''
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Split-Path -Parent $scriptDir
if (-not $EnvFile) {
  $EnvFile = Join-Path $appDir '.env'
}

function Get-LanIpv4 {
  $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Sort-Object RouteMetric, InterfaceMetric |
    Select-Object -First 1
  if ($null -eq $defaultRoute) {
    throw 'No default route found - connect to Wi-Fi/Ethernet first.'
  }

  $candidate = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $defaultRoute.InterfaceIndex -ErrorAction SilentlyContinue |
    Where-Object {
      $_.IPAddress -notlike '127.*' -and
      $_.IPAddress -notlike '169.254.*'
    } |
    Select-Object -First 1

  if ($null -eq $candidate) {
    throw 'Could not resolve a LAN IPv4 on the default route interface.'
  }
  return $candidate.IPAddress
}

function Replace-UrlHost([string]$url, [string]$hostIp) {
  if ([string]::IsNullOrWhiteSpace($url)) { return $url }
  return [regex]::Replace(
    $url.Trim(),
    '^(?<scheme>https?|wss?):\/\/[^\/:\s]+',
    { param($m) "$($m.Groups['scheme'].Value)://$hostIp" }
  )
}

$keys = @(
  'MONPEYA_API_URL',
  'API_BASE_URL',
  'IMMO_API_URL',
  'RENTAL_API_URL',
  'IMMO_WS_URL',
  'BILLETTERIE_API_URL',
  'BILLETTERIE_TRANSPORT_API_URL',
  'BILLETTERIE_EVENT_API_URL',
  'BILLETTERIE_WS_URL'
)

if (-not (Test-Path -LiteralPath $EnvFile)) {
  throw "Missing $EnvFile - copy app/.env.example to app/.env first."
}

if (-not $Ip) {
  $Ip = Get-LanIpv4
}

if ($Ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
  throw "Invalid IPv4: $Ip"
}

$original = Get-Content -LiteralPath $EnvFile -Raw
$lines = Get-Content -LiteralPath $EnvFile
$updated = @()
$changed = 0

foreach ($line in $lines) {
  if ($line -match '^\s*#' -or $line -notmatch '=') {
    $updated += $line
    continue
  }

  $eq = $line.IndexOf('=')
  $key = $line.Substring(0, $eq).Trim()
  $value = $line.Substring($eq + 1).Trim()

  if ($keys -notcontains $key -or [string]::IsNullOrWhiteSpace($value)) {
    $updated += $line
    continue
  }

  $hostMatch = [regex]::Match($value, '^(?:https?|wss?):\/\/([^\/:\s]+)')
  if (-not $hostMatch.Success) {
    $updated += $line
    continue
  }
  $oldHost = $hostMatch.Groups[1].Value
  $isLocalish =
    $oldHost -eq 'localhost' -or
    $oldHost -eq '127.0.0.1' -or
    $oldHost -eq '10.0.2.2' -or
    $oldHost -eq 'AUTO' -or
    $oldHost -eq 'lan.host' -or
    $oldHost -match '^192\.168\.' -or
    $oldHost -match '^10\.' -or
    $oldHost -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.'

  if (-not $isLocalish) {
    $updated += $line
    continue
  }

  $newValue = Replace-UrlHost $value $Ip
  if ($newValue -ne $value) {
    $changed++
    Write-Host "  $key"
    Write-Host "    $value"
    Write-Host "    -> $newValue"
  }
  $updated += "$key=$newValue"
}

$newContent = ($updated -join "`n") + "`n"
if ($newContent -ne $original) {
  Set-Content -LiteralPath $EnvFile -Value $newContent -NoNewline
}

Write-Host ""
Write-Host "LAN host: $Ip"
Write-Host "Updated $changed URL(s) in $EnvFile"
Write-Host "Hot-restart (or full restart) Flutter so .env reloads."
