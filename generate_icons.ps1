Add-Type -AssemblyName System.Drawing

$fontPath = "C:\Users\muham\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf"
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($fontPath)
$matFontFamily = $pfc.Families[0]

function New-Icon([int]$size, [string]$outPath) {
    $dir = [System.IO.Path]::GetDirectoryName($outPath)
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # 1. Dark Olive Charcoal Outer Background (#1E2116)
    $rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 30, 33, 22)), ([System.Drawing.Color]::FromArgb(255, 42, 46, 31)), 45
    $g.FillRectangle($bgBrush, $rect)

    # 2. Warm Camel Squircle Badge (#99744A)
    $margin = [int]($size * 0.10)
    $badgeSize = $size - ($margin * 2)
    $corner = [int]($size * 0.26)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($margin, $margin, $corner, $corner, 180, 90)
    $path.AddArc($margin + $badgeSize - $corner, $margin, $corner, $corner, 270, 90)
    $path.AddArc($margin + $badgeSize - $corner, $margin + $badgeSize - $corner, $corner, $corner, 0, 90)
    $path.AddArc($margin, $margin + $badgeSize - $corner, $corner, $corner, 90, 90)
    $path.CloseAllFigures()

    $camelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 153, 116, 74))
    $g.FillPath($camelBrush, $path)

    # 3. Inner Warm Sand Circle Accent (#F5F0E6 overlay)
    $circleMargin = [int]($size * 0.20)
    $circleSize = $size - ($circleMargin * 2)
    $innerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, 245, 240, 230))
    $g.FillEllipse($innerBrush, $circleMargin, $circleMargin, $circleSize, $circleSize)

    # 4. Render MaterialIcons handshake_rounded (0xF06CB) in Dark Olive (#1E2116)
    $fontSizePx = [float]($size * 0.44)
    $fontStyle = [System.Drawing.FontStyle]::Regular
    $font = New-Object System.Drawing.Font -ArgumentList $matFontFamily, $fontSizePx, $fontStyle, ([System.Drawing.GraphicsUnit]::Pixel)
    $symbolBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 30, 33, 22))
    
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $charStr = [char]::ConvertFromUtf32(0xF06CB)
    $rectF = New-Object System.Drawing.RectangleF 0, 0, $size, $size
    $g.DrawString($charStr, $font, $symbolBrush, $rectF, $sf)

    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Generated launcher icon with new master color theme: $outPath ($size x $size)"
}

$root = "c:\Users\muham\Vscode Projects\Borrowly"

New-Icon 48 "$root\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
New-Icon 72 "$root\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
New-Icon 96 "$root\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
New-Icon 144 "$root\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
New-Icon 192 "$root\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
New-Icon 512 "$root\assets\icons\app_icon.png"
