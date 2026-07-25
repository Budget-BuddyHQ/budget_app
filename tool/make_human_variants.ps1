# Generates recoloured character variants from the cropped human walk frames
# in assets/images/humans/ (produced by crop_human_skins.ps1).
#
# The source art uses a tight 9-colour palette, so each variant is an exact
# colour->colour remap: shirt (base + shade), pants, hair (base + highlight)
# and skin tone. Outline, shoes and blush are left alone.
#
# Output: assets/images/humans/<variant>/<frame>.png
#
# Run under Windows PowerShell 5.1, which ships System.Drawing:
#   %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File tool\make_human_variants.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class Recolor
{
    // map: "RRGGBB" -> "RRGGBB". Pixels whose colour is not in the map are copied as-is.
    public static void Apply(string srcPath, string dstPath, Dictionary<string, string> map)
    {
        var lut = new Dictionary<int, int>();
        foreach (var kv in map)
        {
            lut[Convert.ToInt32(kv.Key, 16)] = Convert.ToInt32(kv.Value, 16);
        }

        using (var bmp = new Bitmap(srcPath))
        {
            var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
            var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int bytes = data.Stride * bmp.Height;
            var buf = new byte[bytes];
            Marshal.Copy(data.Scan0, buf, 0, bytes);

            for (int y = 0; y < bmp.Height; y++)
            {
                int row = y * data.Stride;
                for (int x = 0; x < bmp.Width; x++)
                {
                    int i = row + (x * 4);
                    if (buf[i + 3] < 8) continue;
                    int key = (buf[i + 2] << 16) | (buf[i + 1] << 8) | buf[i];
                    int repl;
                    if (lut.TryGetValue(key, out repl))
                    {
                        buf[i + 2] = (byte)((repl >> 16) & 0xFF);
                        buf[i + 1] = (byte)((repl >> 8) & 0xFF);
                        buf[i] = (byte)(repl & 0xFF);
                    }
                }
            }

            Marshal.Copy(buf, 0, data.Scan0, bytes);
            bmp.UnlockBits(data);
            bmp.Save(dstPath, ImageFormat.Png);
        }
    }
}
'@

$root = Split-Path -Parent $PSScriptRoot
$baseDir = Join-Path $root 'assets\images\humans'
if (-not (Test-Path $baseDir)) { throw "Run crop_human_skins.ps1 first: $baseDir not found" }

# Source palette (see tool/README notes): shirt base/shade, pants, hair base/highlight, skin.
$SHIRT = '4A7FBF'; $SHIRT_DK = '345C8C'
$PANTS = '3A3A3A'
$HAIR = '4A3222'; $HAIR_HI = '6B4A32'
$SKIN = 'F2C29A'

# Each variant remaps a subset of the palette. Anything omitted keeps the original colour.
$variants = [ordered]@{
    'emerald_scout' = @{ $SHIRT = '2FA36B'; $SHIRT_DK = '1F7049'; $PANTS = '2A3B33' }
    'gold_banker'   = @{ $SHIRT = 'E0A93B'; $SHIRT_DK = 'A87828'; $PANTS = '2B3140'; $HAIR = '2E2119'; $HAIR_HI = '4A3626' }
    'crimson_trader' = @{ $SHIRT = 'C4483F'; $SHIRT_DK = '8E2F28'; $PANTS = '31292B'; $HAIR = '1F1A16'; $HAIR_HI = '382E26' }
    'violet_scholar' = @{ $SHIRT = '8B5CC7'; $SHIRT_DK = '623E8F'; $PANTS = '2F2B3A'; $HAIR = '5A3A2A'; $HAIR_HI = '7D5438' }
    'teal_analyst'  = @{ $SHIRT = '2FA3A3'; $SHIRT_DK = '1F7272'; $PANTS = '2A3538'; $HAIR = '3A2A1E'; $HAIR_HI = '57402D' }
    'sand_saver'    = @{ $SHIRT = 'D9B98C'; $SHIRT_DK = 'A88A63'; $PANTS = '3B3630'; $HAIR = '17140F'; $HAIR_HI = '2E2820'; $SKIN = '8D5A3B' }
    'rose_planner'  = @{ $SHIRT = 'D9668C'; $SHIRT_DK = 'A34567'; $PANTS = '352E33'; $HAIR = '17140F'; $HAIR_HI = '33291F'; $SKIN = '6B4230' }
    'slate_investor' = @{ $SHIRT = '5C6B7A'; $SHIRT_DK = '3E4A57'; $PANTS = '2A2E33'; $HAIR = '6E6A63'; $HAIR_HI = '96918A'; $SKIN = 'C98F63' }
    # High-rarity drops get deliberately louder palettes so a lucky pull reads
    # as special at thumbnail size.
    'midnight_ledger' = @{ $SHIRT = '1E2A4A'; $SHIRT_DK = '141C33'; $PANTS = '11141F'; $HAIR = 'C9CEDB'; $HAIR_HI = 'EDF1F7'; $SKIN = 'E8C4A0' }
    'aurora_prime'  = @{ $SHIRT = 'FFD45C'; $SHIRT_DK = 'C79A1F'; $PANTS = '1F7049'; $HAIR = 'EDF1F7'; $HAIR_HI = 'FFFFFF'; $SKIN = 'F7DFC4' }
}

$frames = Get-ChildItem $baseDir -Filter '*.png' -File | Sort-Object Name
Write-Host ("Source frames: {0}" -f $frames.Count)

foreach ($name in $variants.Keys) {
    $outDir = Join-Path $baseDir $name
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    $map = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    foreach ($k in $variants[$name].Keys) { $map[$k] = $variants[$name][$k] }

    foreach ($f in $frames) {
        [Recolor]::Apply($f.FullName, (Join-Path $outDir $f.Name), $map)
    }
    Write-Host ("  {0}: {1} frames" -f $name, $frames.Count)
}

Write-Host 'Done.'
