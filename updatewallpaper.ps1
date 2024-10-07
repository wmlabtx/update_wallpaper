# OpenAI API Key
$apiKey = "YOUR_OPENAI_API_KEY_HERE"

# Set the prompt for DALL-E
$prompt = "An old-fashioned wallpaper with flowers and birds. Muted colors, not bright, with the texture of rough paper"

# Create a JSON body with the prompt
$body = @{
    "model" = "dall-e-3"
    "prompt" = $prompt
    "n" = 1
    "size" = "1792x1024"
} | ConvertTo-Json

# Define the output file paths
$outputDir = "$env:USERPROFILE\Pictures\AI_Wallpapers"

# Ensure the output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Generate a random 8-character alphanumeric string
$chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
$randomString = -join ((1..8) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })

$outputFile = "$outputDir\dalle_generated_$randomString.jpg"

# Call the OpenAI API to generate the image
# https://platform.openai.com/docs/guides/images/usage
$response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" `
    -Method Post `
    -Headers @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" } `
    -Body $body

# Extract the image URL from the API response
$imageUrl = $response.data[0].url

# Download the image to the specified path
Invoke-WebRequest -Uri $imageUrl -OutFile $outputFile

# Set a wallpaper
$code = @"
[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
"@

$type = Add-Type -MemberDefinition $code -Name "Wallpaper" -Namespace "Win32" -PassThru
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02
$type::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $outputFile, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)

