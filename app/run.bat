@echo off
cd /d "%~dp0"
flutter run --dart-define-from-file=config/env.json %*
