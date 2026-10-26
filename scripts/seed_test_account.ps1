# Creates (or signs in) a test account on the Firebase project and fills it with sample data.
# Usage: powershell -File scripts\seed_test_account.ps1
$ErrorActionPreference = 'Stop'
$key = 'AIzaSyBIU3V5GCyTukAY4bDiUViwa0o35MFbtrY'   # public web key from firebase_options.dart
$project = 'cookingapp-8eef2'
$email = 'test.cook@example.com'
$password = 'CookTest123'

$body = @{ email = $email; password = $password; returnSecureToken = $true } | ConvertTo-Json
try {
  $auth = Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body `
    -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$key"
} catch {
  $auth = Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body `
    -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key"
}
$uid = $auth.localId
$headers = @{ Authorization = "Bearer $($auth.idToken)" }
$root = "https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents/users/$uid"

# display name shows in the greeting
$nameBody = @{ idToken = $auth.idToken; displayName = 'Halima'; returnSecureToken = $false } | ConvertTo-Json
Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $nameBody `
  -Uri "https://identitytoolkit.googleapis.com/v1/accounts:update?key=$key" | Out-Null

function S($v) { @{ stringValue = "$v" } }
function Put($path, $fields) {
  Invoke-RestMethod -Method Patch -Headers $headers -ContentType 'application/json' `
    -Body (@{ fields = $fields } | ConvertTo-Json -Depth 20) -Uri "$root$path" | Out-Null
}

$today = Get-Date
$people = @(
  @{ mapValue = @{ fields = @{ age = @{ integerValue = '38' }; gender = (S 'Female') } } },
  @{ mapValue = @{ fields = @{ age = @{ integerValue = '40' }; gender = (S 'Male') } } },
  @{ mapValue = @{ fields = @{ age = @{ integerValue = '9' }; gender = (S 'Female') } } },
  @{ mapValue = @{ fields = @{ age = @{ integerValue = '6' }; gender = (S 'Male') } } }
)
$profile = @{ mapValue = @{ fields = @{
  people = @{ arrayValue = @{ values = $people } }
  country = (S 'Pakistan'); spice = (S 'Medium')
  cuisines = @{ arrayValue = @{ values = @((S 'Pakistani'), (S 'Indian')) } }
  habits = (S 'Men like desi food, kids like fries and noodles')
} } }
Put '' @{
  profile = $profile
  lastShoppingDate = (S $today.AddDays(-9).ToString('yyyy-MM-dd'))
  nextShoppingDate = (S $today.AddDays(5).ToString('yyyy-MM-dd'))
}

function DocId($name, $unit) {
  $b = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($name.ToLower())|$unit"))
  $b.Replace('+', '-').Replace('/', '_').TrimEnd('=')
}
$items = @(
  @('Basmati rice', 'kg', 4), @('Wheat flour', 'kg', 5), @('Red lentils', 'g', 500),
  @('Chickpeas', 'g', 750), @('Onions', 'kg', 2), @('Tomatoes', 'kg', 1.5), @('Potatoes', 'kg', 3),
  @('Eggs', 'pieces', 10), @('Milk', 'L', 2), @('Chicken', 'kg', 1), @('Cooking oil', 'L', 1.5),
  @('Shan chat masala', 'packs', 1), @('National biryani masala', 'packs', 2), @('Yogurt', 'kg', 1),
  @('Spinach', 'g', 400), @('Garlic', 'g', 150)
)
foreach ($i in $items) {
  $amt = if ($i[2] -is [int]) { @{ integerValue = "$($i[2])" } } else { @{ doubleValue = [double]$i[2] } }
  Put "/inventory/$(DocId $i[0] $i[1])" @{
    name = (S $i[0]); unit = (S $i[1]); amount = $amt
    addedAt = @{ timestampValue = $today.AddDays(-2).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }
  }
}

$meals = @(
  @('Chicken karahi', 'Dinner', 1), @('Aloo paratha', 'Breakfast', 1), @('Daal chawal', 'Lunch', 2),
  @('Chana chaat', 'Lunch', 3), @('Vegetable biryani', 'Dinner', 4), @('Omelette', 'Breakfast', 5)
)
foreach ($m in $meals) {
  $d = $today.AddDays(-$m[2])
  Put "/meals/seed$([guid]::NewGuid().ToString('N').Substring(0,8))" @{
    dishName = (S $m[0]); slot = (S $m[1]); date = (S $d.ToString('yyyy-MM-dd'))
    used = @{ arrayValue = @{ } }
    createdAt = @{ timestampValue = $d.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }
  }
}
"Seeded $email (uid $uid): profile, $($items.Count) groceries, $($meals.Count) meals."
