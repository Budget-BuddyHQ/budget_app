# Packs the loose villager frames into one sprite sheet per (gender, variant),
# written to assets/self_made_skins/.
#
# Motivation: the loose layout was ~680 individual PNGs, which bloats the asset
# manifest, needs a pubspec entry per folder, and costs one image decode per
# frame at runtime. One sheet per character is a single decode and a single
# pubspec directory.
#
# Layout is a fixed grid, row-per-direction, so a frame's cell is pure
# arithmetic with no metadata lookup needed:
#
#   row 0: south 1..8
#   row 1: north 1..7   (last cell empty)
#   row 2: west  1..8
#   row 3: east  1..8
#
# Cell size is the source frame size (416x608), so sheets are 8 cols x 4 rows.
#
# Run under Windows PowerShell 5.1 (ships System.Drawing):
#   %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -File tool\pack_skin_sheets.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$humansDir = Join-Path $root 'assets\images\humans'
$outDir = Join-Path $root 'assets\self_made_skins'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# Must match AppAssets.humanVariantIds plus the unprefixed base character.
$variants = @(
    '', 'emerald_scout', 'gold_banker', 'crimson_trader', 'violet_scholar',
    'teal_analyst', 'sand_saver', 'rose_planner', 'slate_investor',
    'midnight_ledger', 'aurora_prime'
)

$directions = @(
    @{ Name = 'south'; Count = 8 },
    @{ Name = 'north'; Count = 7 },
    @{ Name = 'west'; Count = 8 },
    @{ Name = 'east'; Count = 8 }
)

$cols = 8
$rows = $directions.Count

# The source art is 20 screen px per art pixel, but nothing displays these
# larger than ~100px. Dividing by 4 keeps 5px per art pixel — still far above
# any display size — and cuts the packed bundle roughly 16x. Nearest-neighbour
# on an exact divisor of the block size stays pixel-perfect.
$scaleDivisor = 4

function Build-Sheet($srcDir, $outPath) {
    # Measure the first frame to size the grid.
    $probe = Join-Path $srcDir 'south1.png'
    if (-not (Test-Path $probe)) { throw "Missing $probe" }
    $first = [System.Drawing.Bitmap]::FromFile($probe)
    $cw = [int]($first.Width / $scaleDivisor)
    $ch = [int]($first.Height / $scaleDivisor)
    $first.Dispose()

    $sheet = New-Object System.Drawing.Bitmap(($cw * $cols), ($ch * $rows))
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    for ($r = 0; $r -lt $rows; $r++) {
        $dir = $directions[$r]
        for ($c = 0; $c -lt $dir.Count; $c++) {
            $framePath = Join-Path $srcDir ("{0}{1}.png" -f $dir.Name, ($c + 1))
            if (-not (Test-Path $framePath)) { throw "Missing $framePath" }
            $img = [System.Drawing.Bitmap]::FromFile($framePath)
            try {
                $g.DrawImage($img, ($c * $cw), ($r * $ch), $cw, $ch)
            }
            finally { $img.Dispose() }
        }
    }

    $g.Dispose()
    $sheet.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $sheet.Dispose()
    return "$($cw)x$($ch)"
}

$made = 0
foreach ($gender in @('male', 'female')) {
    $genderRoot = if ($gender -eq 'male') { $humansDir } else { Join-Path $humansDir 'female' }

    foreach ($variant in $variants) {
        $srcDir = if ($variant -eq '') { $genderRoot } else { Join-Path $genderRoot $variant }
        if (-not (Test-Path $srcDir)) { throw "Missing variant dir: $srcDir" }

        $name = if ($variant -eq '') { 'classic' } else { $variant }
        $outPath = Join-Path $outDir ("villager_{0}_{1}.png" -f $gender, $name)
        $cell = Build-Sheet $srcDir $outPath
        $made++
        Write-Host ("  villager_{0}_{1}.png  (cell {2})" -f $gender, $name, $cell)
    }
}

Write-Host ""
Write-Host ("Packed {0} sheets into {1}" -f $made, $outDir)
$total = (Get-ChildItem $outDir -Filter '*.png' | Measure-Object Length -Sum).Sum
Write-Host ("Total sheet size: {0:N0} KB" -f ($total / 1KB))
