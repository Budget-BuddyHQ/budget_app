# Crops the hand-drawn human walk sheets in assets/own_skins/Humans_skins/male_human
# into individual frames under assets/images/humans/, matching the goomba frame
# convention (south1..N / north1..N / west1..N).
#
# Each source sheet is a grid of 640x640 cells scanned in reading order; empty
# cells are skipped so a partially filled last row is fine. Every frame from
# every direction is cropped to one shared bounding box so the character does
# not jitter between frames or when it turns.
#
# The pixel work runs in inline C# (LockBits) because per-pixel GetPixel loops
# in PowerShell are far too slow for 640x640 frames.
#
# Run under Windows PowerShell 5.1, which ships System.Drawing:
#   %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File tool\crop_human_skins.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class SpriteSlicer
{
    public const int Cell = 640;

    public static List<Bitmap> Slice(string path)
    {
        var result = new List<Bitmap>();
        using (var src = new Bitmap(path))
        {
            int cols = src.Width / Cell;
            int rows = src.Height / Cell;
            for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                {
                    var rect = new Rectangle(c * Cell, r * Cell, Cell, Cell);
                    result.Add(src.Clone(rect, PixelFormat.Format32bppArgb));
                }
        }
        return result;
    }

    // Returns {minX, minY, maxX, maxY} of pixels with alpha > 8, or null if empty.
    public static int[] Bounds(Bitmap bmp)
    {
        int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1;
        var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height),
                                ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            int bytes = data.Stride * bmp.Height;
            var buffer = new byte[bytes];
            Marshal.Copy(data.Scan0, buffer, 0, bytes);
            for (int y = 0; y < bmp.Height; y++)
            {
                int row = y * data.Stride;
                for (int x = 0; x < bmp.Width; x++)
                {
                    if (buffer[row + (x * 4) + 3] > 8)
                    {
                        if (x < minX) minX = x;
                        if (y < minY) minY = y;
                        if (x > maxX) maxX = x;
                        if (y > maxY) maxY = y;
                    }
                }
            }
        }
        finally { bmp.UnlockBits(data); }

        if (maxX < 0) return null;
        return new[] { minX, minY, maxX, maxY };
    }

    public static void SaveCrop(Bitmap src, int x, int y, int w, int h, string outPath, bool mirror)
    {
        using (var dst = src.Clone(new Rectangle(x, y, w, h), PixelFormat.Format32bppArgb))
        {
            if (mirror) dst.RotateFlip(RotateFlipType.RotateNoneFlipX);
            dst.Save(outPath, ImageFormat.Png);
        }
    }
}
'@

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root 'assets\own_skins\Humans_skins\male_human'
$outDir = Join-Path $root 'assets\images\humans'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$sheets = [ordered]@{
    'south' = @('Humanwlaking south.png')
    'north' = @('H7.png')
    'west'  = @('human walking west.png', 'human walking west last 2 f.png')
}

Write-Host 'Slicing sheets...'
$frames = [ordered]@{}
foreach ($dir in $sheets.Keys) {
    $kept = New-Object System.Collections.ArrayList
    foreach ($file in $sheets[$dir]) {
        $path = Join-Path $srcDir $file
        if (-not (Test-Path $path)) { throw "Missing source sheet: $path" }
        foreach ($bmp in [SpriteSlicer]::Slice($path)) {
            $b = [SpriteSlicer]::Bounds($bmp)
            if ($null -eq $b) { $bmp.Dispose(); continue }
            [void]$kept.Add(@{ Bmp = $bmp; B = $b })
        }
    }
    $frames[$dir] = $kept
    Write-Host ("  {0}: {1} frames" -f $dir, $kept.Count)
}

$gMinX = [int]::MaxValue; $gMinY = [int]::MaxValue; $gMaxX = -1; $gMaxY = -1
foreach ($dir in $frames.Keys) {
    foreach ($f in $frames[$dir]) {
        if ($f.B[0] -lt $gMinX) { $gMinX = $f.B[0] }
        if ($f.B[1] -lt $gMinY) { $gMinY = $f.B[1] }
        if ($f.B[2] -gt $gMaxX) { $gMaxX = $f.B[2] }
        if ($f.B[3] -gt $gMaxY) { $gMaxY = $f.B[3] }
    }
}

$pad = 8
$gMinX = [Math]::Max(0, $gMinX - $pad)
$gMinY = [Math]::Max(0, $gMinY - $pad)
$gMaxX = [Math]::Min(639, $gMaxX + $pad)
$gMaxY = [Math]::Min(639, $gMaxY + $pad)
$w = $gMaxX - $gMinX + 1
$h = $gMaxY - $gMinY + 1
Write-Host ("Shared crop box: {0},{1} {2}x{3}" -f $gMinX, $gMinY, $w, $h)

foreach ($dir in $frames.Keys) {
    $i = 1
    foreach ($f in $frames[$dir]) {
        [SpriteSlicer]::SaveCrop($f.Bmp, $gMinX, $gMinY, $w, $h, (Join-Path $outDir "$dir$i.png"), $false)
        # The source art only has a west-facing side view. Bonfire's
        # SimpleDirectionAnimation derives "left" by flipping the right-facing
        # animation, so mirror west into east frames and feed it those.
        if ($dir -eq 'west') {
            [SpriteSlicer]::SaveCrop($f.Bmp, $gMinX, $gMinY, $w, $h, (Join-Path $outDir "east$i.png"), $true)
        }
        $f.Bmp.Dispose()
        $i++
    }
}

Write-Host "Wrote frames to $outDir"
Get-ChildItem $outDir -Filter *.png | Sort-Object Name | ForEach-Object { Write-Host ("  " + $_.Name) }
