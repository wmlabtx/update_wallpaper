# OpenAI API Key
$apiKey = "YOUR_OPENAI_KEY"

# Set the prompt for DALL-E

$prompt = @"
a thicket of a dark, mysterious mixed forest, shrubs, and various grasses, at twilight, 
featuring fantastical and diverse trees with lush foliage, bushes, vines, a fallen tree, lots of fallen leaves, 
a stump, amidst the dense, patchy fog, golden rays of the setting sun barely breaking through the foliage, 
view from below, from the very ground, muted dark colors
"@

function IsWallpaperOk()
{
    param ([String]$fullName)

    Add-Type -AssemblyName System.Drawing
    $image = $null
    try {
        $image = [System.Drawing.Image]::FromFile($fullName)
        $points = @(
            [System.Drawing.Point]::new(3, 3),
            [System.Drawing.Point]::new(3, 257),
            [System.Drawing.Point]::new(3, 512),
            [System.Drawing.Point]::new(3, 766),
            [System.Drawing.Point]::new(3, 1020),
            [System.Drawing.Point]::new(1788, 5),
            [System.Drawing.Point]::new(1788, 257),
            [System.Drawing.Point]::new(1788, 512),
            [System.Drawing.Point]::new(1788, 766),
            [System.Drawing.Point]::new(1788, 1020)
        )

        $greenValues = $points | ForEach-Object { $image.GetPixel($_.X, $_.Y).G }
        $maxDifference = 0
        for ($i = 0; $i -lt $greenValues.Length - 1; $i++) {
            for ($j = $i + 1; $j -lt $greenValues.Length; $j++) {
                $difference = [Math]::Abs($greenValues[$i] - $greenValues[$j])
                if ($difference -gt $maxDifference) {
                    $maxDifference = $difference
                }
            }
        }

        return $maxDifference -ge 24
    }
    catch {
        Write-Error $_.Exception.Message
        return $false
    }
    finally {
        if ($image) { 
            $image.Dispose() 
        }
    }
}

$body = @{
    "model"   = "dall-e-3"
    "prompt"  = $prompt
    "size"    = "1792x1024"
    "style"   = "vivid"
    "quality" = "hd"
} | ConvertTo-Json

$outputDir = "$env:USERPROFILE\Pictures\AI_Wallpapers"

if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

while ($true) {
    $outputFile = "$outputDir\dalle3_$((Get-Date).ToString("yyMMdd_HHmmss")).png"
    
    # https://platform.openai.com/docs/guides/images/usage
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" `
        -Method Post `
        -Headers @{ "Authorization" = "Bearer $apiKey"; "Content-Type" = "application/json" } `
        -Body $body
    
    $imageUrl = $response.data[0].url
    Invoke-WebRequest -Uri $imageUrl -OutFile $outputFile

    if (-not (IsWallpaperOk($outputFile))) {
        Rename-Item -Path $outputFile -NewName "$outputFile.bad" -Force | Out-Null
        continue
    }

    break
}

$code = @"
[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
"@

# Using only Windows API functions like SystemParametersInfo,
# it's not possible to set a wallpaper for individual monitors directly,
# as it affects all monitors at once
$type = Add-Type -MemberDefinition $code -Name "Wallpaper" -Namespace "Win32" -PassThru
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02
$type::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $outputFile, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)

# More complex method described here:
# https://hinchley.net/articles/using-powershell-to-automatically-change-the-desktop-wallpaper-based-on-screen-resolution