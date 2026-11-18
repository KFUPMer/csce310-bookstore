# make-hero.ps1
#
# Draws the picture at the top of the README: docs/02-design/ui/readme-hero.png.
# It shows both apps as two overlapping desktop windows on the deep green of
# the store's sign: the customer app's shelf of covers (behind, left) and the
# manager app's Sales report (in front, right). Each window gets a plain title
# bar, rounded corners and a soft shadow.
#
# Input (real app screens drawn by the Flutter screenshot tests, 1440x900):
#   docs/02-design/ui/customer-search-light.png
#   docs/02-design/ui/manager-reports-light.png
# Uses only Windows' own System.Drawing and the Segoe UI system font:
# no outside images, fonts or packages.
#
# Run from the repo root:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\screenshots\make-hero.ps1
#
# Kept to plain ASCII on purpose: Windows PowerShell 5.1 misreads UTF-8 (P-013).

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ui = Join-Path $repo 'docs\02-design\ui'
$out = Join-Path $ui 'readme-hero.png'

# Canvas and layout (pixels).
$W = 1800; $H = 1000
$scale = 0.70                       # 1440x900 -> 1008x630
$titleH = 34                        # window title bar height
$radius = 14                        # window corner radius

function New-RoundedPath([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Set-Quality($g) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
}

# Draws one window (title bar + scaled screenshot) into its own bitmap.
function New-WindowBitmap([string]$shot, [string]$title) {
    $src = [System.Drawing.Image]::FromFile($shot)
    $w = [int][Math]::Round($src.Width * $scale)
    $h = [int][Math]::Round($src.Height * $scale) + $titleH
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    Set-Quality $g
    $g.Clear([System.Drawing.Color]::FromArgb(255, 233, 228, 218))

    # Screenshot, scaled, under the title bar. Clamp edges so the border is not faded.
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $dest = New-Object System.Drawing.Rectangle 0, $titleH, $w, ($h - $titleH)
    $g.DrawImage($src, $dest, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)

    # Title text.
    $font = New-Object System.Drawing.Font 'Segoe UI', 13, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
    $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 70, 64, 56))
    $sf = New-Object System.Drawing.StringFormat
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString($title, $font, $ink, (New-Object System.Drawing.RectangleF 18, 0, 600, $titleH), $sf)

    # Windows-style controls: minimise, maximise, close.
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 90, 84, 76)), 1.2
    $cy = $titleH / 2
    $x = $w - 30
    $g.DrawLine($pen, ($x - 5), ($cy - 5), ($x + 5), ($cy + 5))
    $g.DrawLine($pen, ($x - 5), ($cy + 5), ($x + 5), ($cy - 5))
    $x = $w - 76
    $g.DrawRectangle($pen, ($x - 5), ($cy - 5), 10, 10)
    $x = $w - 122
    $g.DrawLine($pen, ($x - 5), $cy, ($x + 5), $cy)

    # Hairline between title bar and app.
    $line = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 214, 207, 195)), 1
    $g.DrawLine($line, 0, ($titleH - 0.5), $w, ($titleH - 0.5))

    $g.Dispose(); $src.Dispose()
    return $bmp
}

# Soft shadow: many faint rounded rectangles, growing outwards.
function Draw-Shadow($g, [single]$x, [single]$y, [single]$w, [single]$h) {
    $layers = 36
    for ($i = $layers; $i -ge 1; $i--) {
        $a = [int](7 * (1 - ($i / ($layers + 1))) + 1)
        $b = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, 0, 12, 6))
        $p = New-RoundedPath ($x - $i) ($y - $i + 22) ($w + 2 * $i) ($h + 2 * $i) ($radius + $i)
        $g.FillPath($b, $p)
        $p.Dispose(); $b.Dispose()
    }
}

# Window with antialiased rounded corners (filled with a texture brush, not clipped).
function Draw-Window($g, $bmp, [single]$x, [single]$y) {
    Draw-Shadow $g $x $y $bmp.Width $bmp.Height
    $brush = New-Object System.Drawing.TextureBrush $bmp
    $brush.WrapMode = [System.Drawing.Drawing2D.WrapMode]::Clamp
    $brush.TranslateTransform($x, $y)
    $p = New-RoundedPath $x $y $bmp.Width $bmp.Height $radius
    $g.FillPath($brush, $p)
    $edge = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 0, 0, 0)), 1
    $g.DrawPath($edge, $p)
    $p.Dispose(); $brush.Dispose(); $edge.Dispose()
}

$canvas = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($canvas)
Set-Quality $g

# Background: the sign's deep green, a little lighter towards the upper left.
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Point 0, 0), (New-Object System.Drawing.Point $W, $H), ([System.Drawing.Color]::FromArgb(255, 36, 74, 56)), ([System.Drawing.Color]::FromArgb(255, 18, 44, 33))
$g.FillRectangle($bg, 0, 0, $W, $H)

$customer = New-WindowBitmap (Join-Path $ui 'customer-search-light.png') "Mooney's"
$manager = New-WindowBitmap (Join-Path $ui 'manager-reports-light.png') "Mooney's Manager"

# Customer behind (upper left), manager in front (lower right).
$cx = 70;  $cy = 60
$mx = $W - 70 - $manager.Width; $my = $H - 60 - $manager.Height
Draw-Window $g $customer $cx $cy
Draw-Window $g $manager $mx $my

$g.Dispose()
$canvas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $customer.Dispose(); $manager.Dispose()

$info = Get-Item $out
"Wrote $out ($W x $H, $($info.Length) bytes)"
