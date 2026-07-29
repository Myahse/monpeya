#Requires -Version 5.1
<#
.SYNOPSIS
  Smoke-test all Monpeya Backend API endpoints (POST /v1/*).

.DESCRIPTION
  Local-only checks always run (ping, catalog, plans, guest access).
  Auth / subscribe / me run when -Phone and -Pin are set (or SMOKE_PHONE / SMOKE_PIN).

.PARAMETER BaseUrl
  Default: http://localhost:8081 (matches .env SERVER_PORT)

.EXAMPLE
  .\scripts\smoke-test-endpoints.ps1

.EXAMPLE
  .\scripts\smoke-test-endpoints.ps1 -Phone 0700000000 -Pin 1234
#>

[CmdletBinding()]
param(
    [string] $BaseUrl = $(if ($env:MONPEYA_BASE_URL) { $env:MONPEYA_BASE_URL } else { "http://localhost:8081" }),
    [string] $Phone = $(if ($env:SMOKE_PHONE) { $env:SMOKE_PHONE } else { "" }),
    [string] $Pin = $(if ($env:SMOKE_PIN) { $env:SMOKE_PIN } else { "" })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$script:Passed = 0
$script:Failed = 0
$script:Skipped = 0
$script:AccessToken = $null
$script:RefreshToken = $null

function Write-Step([string] $Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-Api {
    param(
        [string] $Name,
        [string] $Path,
        [hashtable] $Data = $null,
        [int[]] $AcceptStatus = @(200),
        [switch] $AllowHasError
    )

    $uri = "$BaseUrl$Path"
    $bodyObj = @{}
    if ($null -ne $Data) { $bodyObj.data = $Data }
    $json = ($bodyObj | ConvertTo-Json -Depth 8 -Compress)

    try {
        $resp = Invoke-WebRequest -Uri $uri -Method POST -Body $json -ContentType "application/json; charset=utf-8" -UseBasicParsing
        $code = [int]$resp.StatusCode
        $parsed = $resp.Content | ConvertFrom-Json
        $okHttp = $AcceptStatus -contains $code
        $okBiz = $AllowHasError -or (-not $parsed.hasError)
        if ($okHttp -and $okBiz) {
            Write-Host "  PASS  $Name  [$code]" -ForegroundColor Green
            $script:Passed++
            return $parsed
        }
        Write-Host "  FAIL  $Name  [$code] hasError=$($parsed.hasError)" -ForegroundColor Red
        if ($parsed.status) {
            Write-Host ("        status=" + ($parsed.status | ConvertTo-Json -Compress)) -ForegroundColor DarkRed
        }
        $script:Failed++
        return $parsed
    }
    catch {
        $ex = $_.Exception
        $code = 0
        $content = $null
        if ($ex.Response) {
            $code = [int]$ex.Response.StatusCode
            try {
                $stream = $ex.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $content = $reader.ReadToEnd()
            } catch {}
        }
        if (($AcceptStatus -contains $code) -and $content) {
            try {
                $parsed = $content | ConvertFrom-Json
                Write-Host "  PASS  $Name  [$code] (expected error status)" -ForegroundColor Green
                $script:Passed++
                return $parsed
            } catch {}
        }
        Write-Host "  FAIL  $Name  $($ex.Message)" -ForegroundColor Red
        if ($content) { Write-Host "        body=$content" -ForegroundColor DarkRed }
        $script:Failed++
        return $null
    }
}

function Skip-Test {
    param([string] $Name, [string] $Reason = "")
    if ($Reason) {
        Write-Host "  SKIP  $Name  ($Reason)" -ForegroundColor Yellow
    } else {
        Write-Host "  SKIP  $Name" -ForegroundColor Yellow
    }
    $script:Skipped++
}

Write-Host "Monpeya API smoke test" -ForegroundColor White
Write-Host "BaseUrl: $BaseUrl"
Write-Host ""

Write-Step "Endpoint list"
@(
    "POST /v1/ping",
    "POST /v1/auth/lookup",
    "POST /v1/auth/otp/send",
    "POST /v1/auth/otp/verify",
    "POST /v1/auth/login",
    "POST /v1/auth/refresh",
    "POST /v1/auth/logout",
    "POST /v1/auth/me",
    "POST /v1/modules/catalog",
    "POST /v1/access/check",
    "POST /v1/plans",
    "POST /v1/subscriptions/me",
    "POST /v1/subscriptions/subscribe"
) | ForEach-Object { Write-Host "  $_" }

Write-Step "Health"
Invoke-Api -Name "ping" -Path "/v1/ping" -Data @{ pingId = 1 } | Out-Null

Write-Step "Modules catalog (guest)"
$catalog = Invoke-Api -Name "modules/catalog" -Path "/v1/modules/catalog"
if ($catalog -and $catalog.items) {
    Write-Host "        modules=$($catalog.count)" -ForegroundColor DarkGray
}

Write-Step "Plans (empty until defined)"
Invoke-Api -Name "plans" -Path "/v1/plans" | Out-Null

Write-Step "Access check - guest browse Immo"
Invoke-Api -Name "access/check guest open real-estate" -Path "/v1/access/check" -Data @{
    moduleCode = "real-estate"
} | Out-Null

Write-Step "Access check - guest denied wallet.transfer"
$deny = Invoke-Api -Name "access/check guest wallet.transfer" -Path "/v1/access/check" -Data @{
    moduleCode = "peyapay"
    actionCode = "wallet.transfer"
}
if ($deny -and $deny.item -and ($deny.item.allowed -eq $false)) {
    Write-Host "        reason=$($deny.item.reason)" -ForegroundColor DarkGray
} elseif ($deny -and $deny.item -and ($deny.item.allowed -eq $true)) {
    Write-Host "  FAIL  expected deny for guest wallet.transfer" -ForegroundColor Red
    $script:Failed++
    $script:Passed--
}

Write-Step "Access check - guest Leadway open OK"
Invoke-Api -Name "access/check guest open leadway" -Path "/v1/access/check" -Data @{
    moduleCode = "leadway-assurance"
} | Out-Null

Write-Step "Access check - guest Leadway unknown action OK (default GUEST)"
$leadGuest = Invoke-Api -Name "access/check guest leadway browse" -Path "/v1/access/check" -Data @{
    moduleCode = "leadway-assurance"
    actionCode = "policy.browse"
}
if ($leadGuest -and $leadGuest.item -and ($leadGuest.item.allowed -eq $true)) {
    Write-Host "        reason=$($leadGuest.item.reason)" -ForegroundColor DarkGray
} elseif ($leadGuest -and $leadGuest.item -and ($leadGuest.item.allowed -eq $false)) {
    Write-Host "  FAIL  expected allow for guest leadway browse" -ForegroundColor Red
    $script:Failed++
    $script:Passed--
}

Write-Step "Access check - guest Leadway payment denied (AUTH)"
$leadPay = Invoke-Api -Name "access/check guest leadway payment" -Path "/v1/access/check" -Data @{
    moduleCode = "leadway-assurance"
    actionCode = "policy.checkout"
}
if ($leadPay -and $leadPay.item -and ($leadPay.item.allowed -eq $false)) {
    Write-Host "        reason=$($leadPay.item.reason)" -ForegroundColor DarkGray
} elseif ($leadPay -and $leadPay.item -and ($leadPay.item.allowed -eq $true)) {
    Write-Host "  FAIL  expected deny for guest policy.checkout" -ForegroundColor Red
    $script:Failed++
    $script:Passed--
}

if (-not $Phone -or -not $Pin) {
    Write-Step "Auth / subscription (skipped)"
    Skip-Test "auth/lookup" "set -Phone / -Pin or SMOKE_PHONE / SMOKE_PIN"
    Skip-Test "auth/login"
    Skip-Test "auth/me"
    Skip-Test "subscriptions/subscribe"
    Skip-Test "subscriptions/me"
    Skip-Test "auth/refresh"
    Skip-Test "auth/logout"
    Skip-Test "otp/send"
    Skip-Test "otp/verify"
} else {
    Write-Step "Auth lookup"
    $lookup = Invoke-Api -Name "auth/lookup" -Path "/v1/auth/lookup" -Data @{ phone = $Phone } -AllowHasError
    if ($lookup -and $lookup.item) {
        Write-Host "        knownPeya=$($lookup.item.knownPeyaClient) otpRequired=$($lookup.item.otpRequired)" -ForegroundColor DarkGray
    }

    Write-Step "Auth login"
    $login = Invoke-Api -Name "auth/login" -Path "/v1/auth/login" -Data @{
        phone = $Phone
        pin   = $Pin
    } -AllowHasError
    if ($login -and (-not $login.hasError) -and $login.item) {
        $script:AccessToken = $login.item.accessToken
        $script:RefreshToken = $login.item.refreshToken
        Write-Host "        userId=$($login.item.user.userId) codeClient=$($login.item.user.codeClient)" -ForegroundColor DarkGray
    }

    if ($script:AccessToken) {
        Write-Step "Auth me"
        Invoke-Api -Name "auth/me" -Path "/v1/auth/me" -Data @{ accessToken = $script:AccessToken } | Out-Null

        Write-Step "Access check - AUTH wallet.transfer"
        $authWallet = Invoke-Api -Name "access/check auth wallet.transfer" -Path "/v1/access/check" -Data @{
            moduleCode  = "peyapay"
            actionCode  = "wallet.transfer"
            accessToken = $script:AccessToken
        }
        if ($authWallet -and $authWallet.item) {
            Write-Host "        allowed=$($authWallet.item.allowed) reason=$($authWallet.item.reason)" -ForegroundColor DarkGray
        }

        Write-Step "Access check - billetterie checkout without sub (expect deny)"
        $billet = Invoke-Api -Name "access/check billetterie checkout" -Path "/v1/access/check" -Data @{
            moduleCode  = "billetterie"
            actionCode  = "ticket.checkout"
            accessToken = $script:AccessToken
        }
        if ($billet -and $billet.item) {
            Write-Host "        allowed=$($billet.item.allowed) reason=$($billet.item.reason)" -ForegroundColor DarkGray
        }

        Write-Step "Mock subscribe"
        $sub = Invoke-Api -Name "subscriptions/subscribe" -Path "/v1/subscriptions/subscribe" -Data @{
            accessToken = $script:AccessToken
        }
        if ($sub -and $sub.item) {
            Write-Host "        paymentStatus=$($sub.item.paymentStatus) mock=$($sub.item.isMockPayment) ref=$($sub.item.paymentRef)" -ForegroundColor DarkGray
        }

        Write-Step "Subscriptions me"
        Invoke-Api -Name "subscriptions/me" -Path "/v1/subscriptions/me" -Data @{
            accessToken = $script:AccessToken
        } | Out-Null

        Write-Step "Access check - billetterie after mock sub (expect allow)"
        $billet2 = Invoke-Api -Name "access/check billetterie after sub" -Path "/v1/access/check" -Data @{
            moduleCode  = "billetterie"
            actionCode  = "ticket.checkout"
            accessToken = $script:AccessToken
        }
        if ($billet2 -and $billet2.item) {
            Write-Host "        allowed=$($billet2.item.allowed) reason=$($billet2.item.reason)" -ForegroundColor DarkGray
        }

        Write-Step "Access check - Leadway payment after login (AUTH, no sub)"
        $leadAuth = Invoke-Api -Name "access/check leadway policy.checkout" -Path "/v1/access/check" -Data @{
            moduleCode  = "leadway-assurance"
            actionCode  = "policy.checkout"
            accessToken = $script:AccessToken
        }
        if ($leadAuth -and $leadAuth.item) {
            Write-Host "        allowed=$($leadAuth.item.allowed) reason=$($leadAuth.item.reason)" -ForegroundColor DarkGray
        }

        if ($script:RefreshToken) {
            Write-Step "Auth refresh"
            $ref = Invoke-Api -Name "auth/refresh" -Path "/v1/auth/refresh" -Data @{
                refreshToken = $script:RefreshToken
            }
            if ($ref -and $ref.item -and $ref.item.accessToken) {
                $script:AccessToken = $ref.item.accessToken
                $script:RefreshToken = $ref.item.refreshToken
            }
        }

        Write-Step "Auth logout"
        Invoke-Api -Name "auth/logout" -Path "/v1/auth/logout" -Data @{
            accessToken = $script:AccessToken
        } | Out-Null
    } else {
        Skip-Test "auth/me" "login failed"
        Skip-Test "subscriptions/*" "login failed"
        Skip-Test "auth/refresh" "login failed"
        Skip-Test "auth/logout" "login failed"
    }

    Write-Step "OTP endpoints (optional - may send real SMS)"
    Skip-Test "auth/otp/send" "skipped by default (real SMS)"
    Skip-Test "auth/otp/verify" "skipped by default"
}

Write-Host ""
Write-Host "----------------------------------------"
Write-Host ("Passed={0}  Failed={1}  Skipped={2}" -f $script:Passed, $script:Failed, $script:Skipped)
if ($script:Failed -gt 0) { exit 1 } else { exit 0 }
