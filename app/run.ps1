# Same as: flutter run --dart-define-from-file=config/env.json
# Usage: .\run.ps1   or   .\run.ps1 -d <deviceId>
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$argsList = @('run', '--dart-define-from-file=config/env.json') + $args
& flutter @argsList
