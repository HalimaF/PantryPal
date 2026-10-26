# Runs every test and saves the reports in test-reports/ (that folder is not in git).
#   1. flutter test   - fast checks on the laptop (logic, screens, saving)      no phone needed
#   2. Patrol         - taps through the login screen on the connected phone
#   3. Maestro        - the same kind of phone checks, written as YAML
# Steps 2 and 3 clear the app's data on the phone, so you will be logged out afterwards.
param(
    [string]$Device = "R5CW726FH0N",
    [string]$Maestro = "C:\Users\Haleema\maestro-install\maestro\bin\maestro.bat",
    [switch]$LaptopOnly
)

$ErrorActionPreference = "Continue"
New-Item -ItemType Directory -Force test-reports | Out-Null

Write-Host "== 1/3 flutter test"
flutter test --coverage --file-reporter "json:test-reports/flutter-test.json" | Tee-Object test-reports/flutter-test.txt

if ($LaptopOnly) { return }

Write-Host "== 2/3 Patrol"
& "$env:LOCALAPPDATA\Pub\Cache\bin\patrol.bat" test --target patrol_test/auth_screen_test.dart -d $Device
Remove-Item -Recurse -Force test-reports\patrol -ErrorAction SilentlyContinue
Copy-Item build\app\reports\androidTests\connected\debug test-reports\patrol -Recurse -Force

Write-Host "== 3/3 Maestro"
$env:MAESTRO_CLI_NO_ANALYTICS = "1"
& $Maestro --device $Device test maestro\ --format html --output test-reports\maestro-report.html

Write-Host "Reports are in test-reports\: flutter-test.txt (and .json), patrol\index.html, maestro-report.html"
