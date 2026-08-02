Add-Type -AssemblyName System.Drawing

function Get-OpaqueBounds {
    param([System.Drawing.Bitmap]$bmp)
    $minX=$bmp.Width; $maxX=0; $minY=$bmp.Height; $maxY=0
    $rect = New-Object System.Drawing.Rectangle(0,0,$bmp.Width,$bmp.Height)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $bmp.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    $bmp.UnlockBits($data)
    for ($y=0; $y -lt $bmp.Height; $y+=2) {
        $row = $y*$stride
        for ($x=0; $x -lt $bmp.Width; $x+=2) {
            $a = $bytes[$row + $x*4 + 3]
            if ($a -gt 10) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    return @($minX,$minY,$maxX,$maxY)
}

$srcPath = "C:\Users\User\Downloads\ND\claude\assets\ND_wordmark_white.png"
$src = [System.Drawing.Bitmap]::FromFile($srcPath)
$b = Get-OpaqueBounds $src
Write-Output "bounds: $($b -join ',')"
$cropRect = New-Object System.Drawing.Rectangle($b[0], $b[1], ($b[2]-$b[0]), ($b[3]-$b[1]))
$cropped = New-Object System.Drawing.Bitmap($cropRect.Width, $cropRect.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($cropped)
$g.DrawImage($src, (New-Object System.Drawing.Rectangle(0,0,$cropRect.Width,$cropRect.Height)), $cropRect, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

# canvas
$canvasSize = 1200
$canvas = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$cg = [System.Drawing.Graphics]::FromImage($canvas)
$cg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$blackBrush = [System.Drawing.Brushes]::Black
$cg.FillRectangle($blackBrush, 0, 0, $canvasSize, $canvasSize)

# tile grid: glyph cell width, keep aspect ratio of cropped glyph, small gap between tiles
$cols = 6
$gap = 14
$cellW = [int]([Math]::Floor($canvasSize / $cols)) - $gap
$aspect = $cropRect.Height / $cropRect.Width
$cellH = [int]($cellW * $aspect)
$stepX = $cellW + $gap
$stepY = $cellH + $gap
$rows = [int]([Math]::Ceiling($canvasSize / $stepY)) + 1

for ($r = 0; $r -lt $rows; $r++) {
    $yOff = $r * $stepY
    for ($c = 0; $c -lt $cols; $c++) {
        $x = $c * $stepX
        $destRect = New-Object System.Drawing.Rectangle($x, $yOff, $cellW, $cellH)
        $cg.DrawImage($cropped, $destRect)
    }
}
$cg.Dispose()
$canvas.Save("C:\Users\User\Downloads\ND\claude\assets\textura.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
$canvas.Dispose()
$cropped.Dispose()
$src.Dispose()
Write-Output "texture done"
