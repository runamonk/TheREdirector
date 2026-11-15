$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assetDirectory = Join-Path $PSScriptRoot '../src/TheREdirector/Assets'
[IO.Directory]::CreateDirectory($assetDirectory) | Out-Null

# A bent arrow on a rounded tile: links going somewhere other than where Windows wanted.
function New-Icon([string]$name, [string]$tile) {
    $canvas = [Drawing.Bitmap]::new(1024, 1024)
    $graphics = [Drawing.Graphics]::FromImage($canvas)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.ScaleTransform(4, 4)

    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddArc(8, 8, 96, 96, 180, 90)
    $path.AddArc(152, 8, 96, 96, 270, 90)
    $path.AddArc(152, 152, 96, 96, 0, 90)
    $path.AddArc(8, 152, 96, 96, 90, 90)
    $path.CloseFigure()
    $brush = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($tile))
    $graphics.FillPath($brush, $path)
    $brush.Dispose(); $path.Dispose()

    $pen = [Drawing.Pen]::new([Drawing.Color]::White, 30)
    $pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
    $pen.CustomEndCap = [Drawing.Drawing2D.AdjustableArrowCap]::new(2.6, 2.4, $true)
    $graphics.DrawBezier($pen, 56, 196, 64, 110, 120, 84, 186, 84)
    $pen.Dispose()
    $graphics.Dispose()

    $sizes = @(16, 20, 24, 32, 40, 48, 64, 256)
    $frames = @()
    foreach ($size in $sizes) {
        $bitmap = [Drawing.Bitmap]::new($size, $size)
        $g = [Drawing.Graphics]::FromImage($bitmap)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($canvas, [Drawing.Rectangle]::new(0, 0, $size, $size))
        $stream = [IO.MemoryStream]::new()
        $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
        $frames += ,$stream.ToArray()
        $stream.Dispose(); $g.Dispose(); $bitmap.Dispose()
    }
    $canvas.Dispose()

    $file = [IO.File]::Create((Join-Path $assetDirectory "$name.ico"))
    $writer = [IO.BinaryWriter]::new($file)
    $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
        $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
        $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$frames[$i].Length); $writer.Write([uint32]$offset)
        $offset += $frames[$i].Length
    }
    foreach ($frame in $frames) { $writer.Write([byte[]]$frame) }
    $writer.Dispose()
}

New-Icon 'TheREdirector' '#E8743B'
# Grey when paused, so the tray shows at a glance whether it's working.
New-Icon 'TheREdirector-off' '#8A8A8A'
Write-Output 'Generated TheREdirector.ico and TheREdirector-off.ico.'
