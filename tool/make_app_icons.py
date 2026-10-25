"""Builds every app icon from the Budget Buddy logo.

The launcher, the Android 12+ splash, the iOS home screen and the web tab all
still showed Flutter's default logo. This crops the turtle and coin out of
`assets/images/budgetbuddy_official_logo-removebg-preview.png` (the words are
unreadable at icon size) and writes:

  * android/app/src/main/res/mipmap-*/ic_launcher.png      (legacy icons)
  * android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
  * android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml (adaptive)
  * android/app/src/main/res/values/ic_launcher_background.xml
  * ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png     (no alpha)
  * web/favicon.png and web/icons/*.png
  * store_assets/play_store_icon_512.png  (upload in Play Console)

Run from the repo root:  python tool/make_app_icons.py
"""
import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO = os.path.join(ROOT, 'assets', 'images',
                    'budgetbuddy_official_logo-removebg-preview.png')
# Warm cream: the green turtle reads on it, and it is not the white of every
# other app on the shelf.
BG = (255, 246, 222)
BG_HEX = '#FFF6DE'


def turtle():
    im = Image.open(LOGO).convert('RGBA')
    alpha = im.split()[3]
    # The turtle and coin sit above the wordmark, which starts at row ~307.
    top = alpha.crop((0, 0, im.width, 305))
    box = top.getbbox()
    return im.crop(box)


def fit(art, size, share):
    """[art] scaled to [share] of a [size] square, centered, transparent."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    scale = share * size / max(art.size)
    w, h = round(art.width * scale), round(art.height * scale)
    small = art.resize((w, h), Image.LANCZOS)
    canvas.alpha_composite(small, ((size - w) // 2, (size - h) // 2))
    return canvas


def on_background(art, size, share, rounded=0.0, alpha=True):
    base = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if rounded:
        mask = Image.new('L', (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, size - 1, size - 1), radius=round(size * rounded), fill=255)
        base.paste(Image.new('RGBA', (size, size), BG + (255,)), (0, 0), mask)
    else:
        base = Image.new('RGBA', (size, size), BG + (255,))
    base.alpha_composite(fit(art, size, share))
    return base if alpha else base.convert('RGB')


def save(img, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    return path


def main():
    art = turtle()
    res = ('android', 'app', 'src', 'main', 'res')

    # Legacy launcher icons (before Android 8), rounded square.
    for folder, size in [('mipmap-mdpi', 48), ('mipmap-hdpi', 72),
                         ('mipmap-xhdpi', 96), ('mipmap-xxhdpi', 144),
                         ('mipmap-xxxhdpi', 192)]:
        save(on_background(art, size, 0.8, rounded=0.22),
             *res, folder, 'ic_launcher.png')

    # Adaptive icons (Android 8+, and the Android 12+ splash). The
    # foreground is 108dp with a 66dp safe zone the launcher never crops.
    for folder, size in [('mipmap-mdpi', 108), ('mipmap-hdpi', 162),
                         ('mipmap-xhdpi', 216), ('mipmap-xxhdpi', 324),
                         ('mipmap-xxxhdpi', 432)]:
        save(fit(art, size, 0.58), *res, folder, 'ic_launcher_foreground.png')
    adaptive = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon '
        'xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n')
    path = os.path.join(ROOT, *res, 'mipmap-anydpi-v26', 'ic_launcher.xml')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w', encoding='utf-8').write(adaptive)
    open(os.path.join(ROOT, *res, 'values', 'ic_launcher_background.xml'),
         'w', encoding='utf-8').write(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="ic_launcher_background">{BG_HEX}</color>\n'
        '</resources>\n')

    # iOS: every size its Contents.json asks for, flat with no transparency
    # (App Store Connect rejects an icon with an alpha channel).
    ios = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets',
                       'AppIcon.appiconset')
    if os.path.isdir(ios):
        spec = json.load(open(os.path.join(ios, 'Contents.json')))
        for img in spec.get('images', []):
            name = img.get('filename')
            if not name:
                continue
            pts = float(img['size'].split('x')[0])
            scale = int(img['scale'].rstrip('x'))
            px = round(pts * scale)
            on_background(art, px, 0.78, alpha=False).save(
                os.path.join(ios, name), optimize=True)

    # Web.
    save(on_background(art, 32, 0.9, rounded=0.2), 'web', 'favicon.png')
    for size in (192, 512):
        save(on_background(art, size, 0.8, rounded=0.22),
             'web', 'icons', f'Icon-{size}.png')
        # Maskable: full bleed, art inside the 80% safe circle.
        save(on_background(art, size, 0.6), 'web', 'icons',
             f'Icon-maskable-{size}.png')

    # Play Console store listing icon: 512 x 512, 32-bit PNG.
    print(save(on_background(art, 512, 0.8), 'store_assets',
               'play_store_icon_512.png'))
    print('done')


if __name__ == '__main__':
    main()
