# Procedural texture generator for the ANEURISM IV GMod HUD.
# Run: powershell -ExecutionPolicy Bypass -File tools\generate_textures.ps1
# Requires only .NET System.Drawing (present on every Windows install).

Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot "..\materials\aneurism_hud"
if (-not (Test-Path $out)) { New-Item -ItemType Directory -Force -Path $out | Out-Null }
$rnd = New-Object System.Random(4815)

function Save-Png($bmp, $name) {
    $path = Join-Path $out $name
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "generated: $name"
}

function Add-Grain($bmp, $count, $light, $dark, $alpha) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    for ($i = 0; $i -lt $count; $i++) {
        $x = $rnd.Next(0, $bmp.Width); $y = $rnd.Next(0, $bmp.Height)
        $s = $rnd.Next(1, 3)
        if ($rnd.Next(0, 2) -eq 0) { $c = [System.Drawing.Color]::FromArgb($alpha, $light.R, $light.G, $light.B) }
        else { $c = [System.Drawing.Color]::FromArgb($alpha, $dark.R, $dark.G, $dark.B) }
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($c)), $x, $y, $s, $s)
    }
    $g.Dispose()
}

function Add-Scratches($bmp, $count, $col, $maxLen) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $pen = New-Object System.Drawing.Pen($col, 1)
    for ($i = 0; $i -lt $count; $i++) {
        $x = $rnd.Next(0, $bmp.Width); $y = $rnd.Next(0, $bmp.Height)
        $len = $rnd.Next(4, $maxLen)
        if ($rnd.Next(0, 2) -eq 0) { $g.DrawLine($pen, $x, $y, $x + $len, $y + $rnd.Next(-2, 3) ) }
        else { $g.DrawLine($pen, $x, $y, $x + $rnd.Next(-2, 3), $y + $len) }
    }
    $pen.Dispose(); $g.Dispose()
}

# --- paper.png : old beige cardboard ---------------------------------------
$bmp = New-Object System.Drawing.Bitmap(128, 128)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(190, 180, 150))
$g.Dispose()
Add-Grain $bmp 5200 ([System.Drawing.Color]::FromArgb(240,232,205)) ([System.Drawing.Color]::FromArgb(80,70,52)) 24
$g = [System.Drawing.Graphics]::FromImage($bmp)
for ($i = 0; $i -lt 14; $i++) {
    $c = [System.Drawing.Color]::FromArgb($rnd.Next(8, 26), 88, 68, 40)
    $br = New-Object System.Drawing.SolidBrush($c)
    $w = $rnd.Next(10, 42); $h = $rnd.Next(8, 30)
    $g.FillEllipse($br, $rnd.Next(0, 128 - $w), $rnd.Next(0, 128 - $h), $w, $h)
    $br.Dispose()
}
$g.Dispose()
Add-Scratches $bmp 26 ([System.Drawing.Color]::FromArgb(18, 120, 108, 84)) 30
Save-Png $bmp "paper.png"

# --- plastic.png : scratched dark plastic ----------------------------------
$bmp = New-Object System.Drawing.Bitmap(128, 128)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(20, 23, 21))
$g.Dispose()
Add-Grain $bmp 4200 ([System.Drawing.Color]::FromArgb(88, 94, 84)) ([System.Drawing.Color]::FromArgb(0, 0, 0)) 16
Add-Scratches $bmp 55 ([System.Drawing.Color]::FromArgb(38, 96, 100, 92)) 40
Add-Scratches $bmp 16 ([System.Drawing.Color]::FromArgb(30, 8, 9, 8)) 26
Save-Png $bmp "plastic.png"

# --- metal.png : oxidized dark metal ---------------------------------------
$bmp = New-Object System.Drawing.Bitmap(128, 128)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(42, 48, 44))
$g.Dispose()
Add-Grain $bmp 5000 ([System.Drawing.Color]::FromArgb(110, 120, 108)) ([System.Drawing.Color]::FromArgb(12, 16, 14)) 22
$g = [System.Drawing.Graphics]::FromImage($bmp)
for ($i = 0; $i -lt 22; $i++) {
    $c = [System.Drawing.Color]::FromArgb($rnd.Next(20, 62), 118, 62, 30)
    $br = New-Object System.Drawing.SolidBrush($c)
    $w = $rnd.Next(2, 12); $h = $rnd.Next(2, 10)
    $g.FillEllipse($br, $rnd.Next(0, 128 - $w), $rnd.Next(0, 128 - $h), $w, $h)
    $br.Dispose()
}
$g.Dispose()
Add-Scratches $bmp 40 ([System.Drawing.Color]::FromArgb(46, 130, 138, 126)) 34
Save-Png $bmp "metal.png"

# --- book_cover.png : blank worn cardboard notebook cover -----------------
$bmp = New-Object System.Drawing.Bitmap(256, 320)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(186, 177, 151))
$g.Dispose()
Add-Grain $bmp 14000 ([System.Drawing.Color]::FromArgb(238, 230, 202)) ([System.Drawing.Color]::FromArgb(74, 66, 50)) 26
$g = [System.Drawing.Graphics]::FromImage($bmp)
for ($i = 0; $i -lt 40; $i++) {
    $c = [System.Drawing.Color]::FromArgb($rnd.Next(8, 28), 86, 66, 38)
    $br = New-Object System.Drawing.SolidBrush($c)
    $w = $rnd.Next(12, 70); $h = $rnd.Next(10, 46)
    $g.FillEllipse($br, $rnd.Next(0, 256 - $w), $rnd.Next(0, 320 - $h), $w, $h)
    $br.Dispose()
}
# frayed / darkened edges
$edge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 58, 52, 40), 6)
$g.DrawRectangle($edge, 2, 2, 252, 316)
$edge.Dispose()
# dog-eared (curled) corners
$br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 138, 112))
$g.FillPolygon($br, [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point(0,0)), (New-Object System.Drawing.Point(34,0)), (New-Object System.Drawing.Point(0,34))))
$g.FillPolygon($br, [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point(256,320)), (New-Object System.Drawing.Point(222,320)), (New-Object System.Drawing.Point(256,286))))
$br.Dispose()
$g.Dispose()
Add-Scratches $bmp 60 ([System.Drawing.Color]::FromArgb(20, 104, 94, 72)) 46
Save-Png $bmp "book_cover.png"

# --- bar_noise.png : speckled fill for the ANEURISM IV stat bars -----------
# Opaque black background + white/grey speckles. It is drawn tinted with the
# stat colour (black stays black, speckles become coloured noise), which is
# exactly the grimy CRT look of the original blood/air/... bars.
$bmp = New-Object System.Drawing.Bitmap(128, 32)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0))
$g.Dispose()
for ($y = 0; $y -lt 32; $y++) {
    # faint horizontal banding, like a dirty LCD
    $band = $rnd.Next(4, 15)
    for ($x = 0; $x -lt 128; $x++) {
        $v = $band + $rnd.Next(0, 26)
        if ($rnd.Next(0, 100) -lt 12) { $v = $rnd.Next(70, 190) }
        if ($rnd.Next(0, 100) -lt 2)  { $v = $rnd.Next(190, 255) }
        if ($v -gt 255) { $v = 255 }
        $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($v, $v, $v))
    }
}
Save-Png $bmp "bar_noise.png"
