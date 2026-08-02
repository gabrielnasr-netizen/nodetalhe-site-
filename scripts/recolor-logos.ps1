Add-Type -AssemblyName System.Drawing

function Recolor-Image {
    param(
        [string]$SrcPath,
        [string]$DstPath,
        [System.Drawing.Color]$FromColor,
        [System.Drawing.Color]$ToColor,
        [int]$Tolerance = 40
    )
    $src = [System.Drawing.Bitmap]::FromFile($SrcPath)
    $bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $src.Width, $src.Height)
    $srcData = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $dstData = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bytesPerPixel = 4
    $stride = $srcData.Stride
    $byteCount = $stride * $src.Height
    $srcBytes = New-Object byte[] $byteCount
    [System.Runtime.InteropServices.Marshal]::Copy($srcData.Scan0, $srcBytes, 0, $byteCount)
    $dstBytes = New-Object byte[] $byteCount

    $fr = $FromColor.R; $fg = $FromColor.G; $fb = $FromColor.B
    $tr = $ToColor.R; $tg = $ToColor.G; $tb = $ToColor.B

    for ($y = 0; $y -lt $src.Height; $y++) {
        $row = $y * $stride
        for ($x = 0; $x -lt $src.Width; $x++) {
            $i = $row + $x * $bytesPerPixel
            $b = $srcBytes[$i]; $g = $srcBytes[$i+1]; $r = $srcBytes[$i+2]; $a = $srcBytes[$i+3]
            if ($a -eq 0) {
                $dstBytes[$i]=0; $dstBytes[$i+1]=0; $dstBytes[$i+2]=0; $dstBytes[$i+3]=0
            } else {
                $dr = [Math]::Abs($r - $fr); $dg = [Math]::Abs($g - $fg); $db = [Math]::Abs($b - $fb)
                if ($dr -le $Tolerance -and $dg -le $Tolerance -and $db -le $Tolerance) {
                    $dstBytes[$i] = $tb; $dstBytes[$i+1] = $tg; $dstBytes[$i+2] = $tr; $dstBytes[$i+3] = $a
                } else {
                    $dstBytes[$i] = $b; $dstBytes[$i+1] = $g; $dstBytes[$i+2] = $r; $dstBytes[$i+3] = $a
                }
            }
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($dstBytes, 0, $dstData.Scan0, $byteCount)
    $src.UnlockBits($srcData)
    $bmp.UnlockBits($dstData)
    $bmp.Save($DstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $src.Dispose()
}

$black = [System.Drawing.Color]::FromArgb(0,0,0)
$white = [System.Drawing.Color]::FromArgb(255,255,255)
$yellow = [System.Drawing.Color]::FromArgb(0xFE,0xCA,0x40)
$offwhite = [System.Drawing.Color]::FromArgb(0xF5,0xF5,0xF3)

$srcDir = "C:\Users\User\Downloads\ND"
$dstDir = "C:\Users\User\Downloads\ND\claude\assets"

# 1. Badge: solid mark (black disc + white gauge lines) -> keep black disc, recolor white lines to yellow
Recolor-Image -SrcPath "$srcDir\ND simbolo 2.png" -DstPath "$dstDir\ND_badge_yellowblack.png" -FromColor $white -ToColor $yellow -Tolerance 30

# 2. Outline mark (black line art, transparent bg) -> yellow version
Recolor-Image -SrcPath "$srcDir\ND simbolo 4.png" -DstPath "$dstDir\ND_outline_yellow.png" -FromColor $black -ToColor $yellow -Tolerance 30

# 3. Outline mark -> white version
Recolor-Image -SrcPath "$srcDir\ND simbolo 4.png" -DstPath "$dstDir\ND_outline_white.png" -FromColor $black -ToColor $offwhite -Tolerance 30

# 4. Wordmark (black fill, transparent bg) -> white version
Recolor-Image -SrcPath "$srcDir\ND 2.png" -DstPath "$dstDir\ND_wordmark_white.png" -FromColor $black -ToColor $offwhite -Tolerance 30

Write-Output "done"
