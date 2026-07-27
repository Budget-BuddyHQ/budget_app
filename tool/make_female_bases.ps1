# Generates female-presenting base frames from the male villager frames by
# actually editing the sprite silhouette — extending the hair down past the
# shoulders — rather than recolouring, which would not read as a different
# character at all.
#
# Runs BEFORE make_human_variants.ps1 so every colour variant gets both a
# male and a female version. Reads assets/images/humans/<dir><n>.png and
# writes assets/images/humans/female/<dir><n>.png.
#
# The art is 20px-per-art-pixel at 416x608. Hair silhouette bounds per
# direction were measured from the source frames (see tool/README notes):
#   south: side columns at x=[88,108) and [308,328), hair ends y=147
#   north: full-width hair mass x=[88,328), ends y=187
#   west:  back-of-head mass reaching x=388, ends y=167
#
# Run under Windows PowerShell 5.1 (ships System.Drawing):
#   %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File tool\make_female_bases.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class FemaleGen
{
    const int HairBase  = 0x4A3222;  // dark brown
    const int HairHi    = 0x6B4A32;  // light brown highlight
    const int Outline   = 0x212823;  // near-black outline
    const int Block     = 20;

    // rects: each is {x, y, w, h} filled with hair; the tool then outlines
    // the union of the added region.
    public static void Apply(string srcPath, string dstPath, int[][] rects, bool mirror)
    {
        using (var bmp = new Bitmap(srcPath))
        {
            var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
            var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int bytes = data.Stride * bmp.Height;
            var buf = new byte[bytes];
            Marshal.Copy(data.Scan0, buf, 0, bytes);

            var added = new bool[bmp.Width, bmp.Height];

            foreach (var r in rects)
            {
                int rx = r[0], ry = r[1], rw = r[2], rh = r[3];
                for (int y = ry; y < ry + rh && y < bmp.Height; y++)
                {
                    for (int x = rx; x < rx + rw && x < bmp.Width; x++)
                    {
                        if (x < 0 || y < 0) continue;
                        // Single highlight column on the right edge, matching
                        // the light direction of the source art. Repeating
                        // stripes across a wide mass made it read as a barrel
                        // rather than hair.
                        bool rightEdge = x >= rx + rw - Block;
                        int colour = rightEdge ? HairHi : HairBase;
                        SetPixel(buf, data.Stride, x, y, colour);
                        added[x, y] = true;
                    }
                }
            }

            // Outline the outer boundary of everything we added, so the new
            // hair matches the chunky outlined style of the source art.
            var outlineCells = new List<int[]>();
            for (int y = 0; y < bmp.Height; y += Block)
            {
                for (int x = 0; x < bmp.Width; x += Block)
                {
                    if (!added[x, y]) continue;
                    // A block is on the boundary if any 4-neighbour block is
                    // outside the added region.
                    bool boundary =
                        !InAdded(added, bmp, x - Block, y) ||
                        !InAdded(added, bmp, x + Block, y) ||
                        !InAdded(added, bmp, x, y - Block) ||
                        !InAdded(added, bmp, x, y + Block);
                    if (boundary) outlineCells.Add(new[] { x, y });
                }
            }
            foreach (var c in outlineCells)
            {
                // Only outline the bottom and outer sides — outlining the top
                // would draw a seam across the join with the original hair.
                bool topJoin = InAdded(added, bmp, c[0], c[1] - Block);
                if (!topJoin && c[1] > 0 && IsHair(buf, data.Stride, c[0], c[1] - 1)) continue;
                FillBlock(buf, data.Stride, bmp, c[0], c[1], Outline, added);
            }

            Marshal.Copy(buf, 0, data.Scan0, bytes);
            bmp.UnlockBits(data);

            if (mirror) bmp.RotateFlip(RotateFlipType.RotateNoneFlipX);
            bmp.Save(dstPath, ImageFormat.Png);
        }
    }

    static bool InAdded(bool[,] added, Bitmap bmp, int x, int y)
    {
        if (x < 0 || y < 0 || x >= bmp.Width || y >= bmp.Height) return false;
        return added[x, y];
    }

    static bool IsHair(byte[] buf, int stride, int x, int y)
    {
        int i = (y * stride) + (x * 4);
        if (i < 0 || i + 3 >= buf.Length) return false;
        int k = (buf[i + 2] << 16) | (buf[i + 1] << 8) | buf[i];
        return k == HairBase || k == HairHi;
    }

    // Paints only the 1-block-thick rim of the block, preserving the hair fill
    // inside so the outline reads as a border rather than a solid square.
    static void FillBlock(byte[] buf, int stride, Bitmap bmp, int bx, int by, int colour, bool[,] added)
    {
        for (int y = by; y < by + Block && y < bmp.Height; y++)
        {
            for (int x = bx; x < bx + Block && x < bmp.Width; x++)
            {
                bool edge =
                    !InAdded(added, bmp, x - 1, y) || !InAdded(added, bmp, x + 1, y) ||
                    !InAdded(added, bmp, x, y - 1) || !InAdded(added, bmp, x, y + 1);
                if (edge) SetPixel(buf, stride, x, y, colour);
            }
        }
    }

    static void SetPixel(byte[] buf, int stride, int x, int y, int colour)
    {
        int i = (y * stride) + (x * 4);
        if (i < 0 || i + 3 >= buf.Length) return;
        buf[i + 2] = (byte)((colour >> 16) & 0xFF);
        buf[i + 1] = (byte)((colour >> 8) & 0xFF);
        buf[i]     = (byte)(colour & 0xFF);
        buf[i + 3] = 255;
    }
}
'@

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root 'assets\images\humans'
$outDir = Join-Path $srcDir 'female'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# Long-hair rectangles per facing, in source pixel coordinates.
#   south -> two curtains framing the face, falling to chest height
#   north -> full mass down the back (most legible "long hair" read)
#   west  -> back-of-head mass falling behind the shoulder
# NOTE: a single-element array-of-arrays collapses in PowerShell
# (@( @(1,2) ) becomes @(1,2)), so single-rect plans need the unary comma
# operator to stay nested.
#   south: curtains anchored ON the existing sideburns ([88,108)/[308,328))
#          and widened inward, so they stay flush against the head instead of
#          floating with a transparent channel between hair and face.
#   north: a narrower, shorter mass — full head width read as a solid slab.
#   west:  falls behind the shoulder, clear of the face.
$plans = @{}
#          Starts at y=108 (not 148) so the curtain merges into the existing
#          hair mass over the ear instead of leaving a transparent notch.
$plans['south'] = @( @(88, 108, 40, 190), @(288, 108, 40, 190) )
$plans['north'] = , @(128, 148, 160, 120)
$plans['west'] = , @(248, 168, 100, 115)

$counts = @{ 'south' = 8; 'north' = 7; 'west' = 8 }

foreach ($dir in @('south', 'north', 'west')) {
    $rects = $plans[$dir]
    for ($i = 1; $i -le $counts[$dir]; $i++) {
        $src = Join-Path $srcDir "$dir$i.png"
        if (-not (Test-Path $src)) { throw "Missing $src" }
        [FemaleGen]::Apply($src, (Join-Path $outDir "$dir$i.png"), $rects, $false)
        # East is the mirror of west, matching crop_human_skins.ps1.
        if ($dir -eq 'west') {
            [FemaleGen]::Apply($src, (Join-Path $outDir "east$i.png"), $rects, $true)
        }
    }
    Write-Host ("  {0}: {1} frames" -f $dir, $counts[$dir])
}

Write-Host "Wrote female base frames to $outDir"
