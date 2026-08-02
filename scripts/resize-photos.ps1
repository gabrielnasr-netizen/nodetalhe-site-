Add-Type -AssemblyName System.Drawing

function Resize-Photo {
    param([string]$Path, [int]$MaxWidth = 1920, [int]$Quality = 78)
    $img = [System.Drawing.Image]::FromFile($Path)
    if ($img.Width -le $MaxWidth) { $img.Dispose(); return }
    $ratio = $MaxWidth / $img.Width
    $newW = $MaxWidth
    $newH = [int]($img.Height * $ratio)
    $bmp = New-Object System.Drawing.Bitmap($newW, $newH)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($img, 0, 0, $newW, $newH)
    $g.Dispose()

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)
    $img.Dispose()
    $bmp.Save($Path, $codec, $params)
    $bmp.Dispose()
}

$dir = "C:\Users\User\Downloads\ND\claude\assets\photos"
Get-ChildItem "$dir\*.jpg" | ForEach-Object {
    Resize-Photo -Path $_.FullName -MaxWidth 1920 -Quality 78
    $sizeKb = [Math]::Round((Get-Item $_.FullName).Length / 1KB)
    Write-Output "$($_.Name): ${sizeKb}KB"
}
