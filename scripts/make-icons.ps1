Add-Type -AssemblyName System.Drawing

function New-CompassIcon {
    param(
        [int]$Size,
        [string]$OutPath,
        [bool]$Maskable = $false
    )

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $ink = [System.Drawing.ColorTranslator]::FromHtml('#1F3049')
    $paper = [System.Drawing.ColorTranslator]::FromHtml('#F5F2EA')
    $brass = [System.Drawing.ColorTranslator]::FromHtml('#B8863B')
    $teal = [System.Drawing.ColorTranslator]::FromHtml('#4A7C74')

    $bgBrush = New-Object System.Drawing.SolidBrush($ink)
    if ($Maskable) {
        $g.FillRectangle($bgBrush, 0, 0, $Size, $Size)
    } else {
        [int]$radius = [Math]::Floor($Size * 0.22)
        [int]$d = $radius * 2
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc(($Size - $d), 0, $d, $d, 270, 90)
        $path.AddArc(($Size - $d), ($Size - $d), $d, $d, 0, 90)
        $path.AddArc(0, ($Size - $d), $d, $d, 90, 90)
        $path.CloseFigure()
        $g.FillPath($bgBrush, $path)
    }

    [single]$cx = $Size / 2.0
    [single]$cy = $Size / 2.0
    [single]$scale = if ($Maskable) { 0.30 } else { 0.36 }
    [single]$r = $Size * $scale

    $ringPen = New-Object System.Drawing.Pen($paper, [Math]::Max(2, $Size * 0.018))
    $g.DrawEllipse($ringPen, ($cx - $r), ($cy - $r), ($r * 2), ($r * 2))

    [single]$needleW = $r * 0.32

    $northPts = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($cx, ($cy - $r * 0.92)),
        [System.Drawing.PointF]::new(($cx - $needleW), $cy),
        [System.Drawing.PointF]::new(($cx + $needleW), $cy)
    )
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($brass)), $northPts)

    $southPts = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($cx, ($cy + $r * 0.92)),
        [System.Drawing.PointF]::new(($cx - $needleW), $cy),
        [System.Drawing.PointF]::new(($cx + $needleW), $cy)
    )
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($teal)), $southPts)

    [single]$dotR = $r * 0.14
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($paper)), ($cx - $dotR), ($cy - $dotR), ($dotR * 2), ($dotR * 2))

    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

$root = "c:\Users\Admin\Desktop\Projekt Reiseroute Claude\icons"
New-Item -ItemType Directory -Force -Path $root | Out-Null

New-CompassIcon -Size 192 -OutPath "$root\icon-192.png" -Maskable $false
New-CompassIcon -Size 512 -OutPath "$root\icon-512.png" -Maskable $false
New-CompassIcon -Size 512 -OutPath "$root\icon-maskable-512.png" -Maskable $true
New-CompassIcon -Size 180 -OutPath "$root\apple-touch-icon.png" -Maskable $false

Write-Output "Icons erstellt in $root"
