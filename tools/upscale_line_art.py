"""Re-inks small black-and-white line art at a higher resolution.

    python tools/upscale_line_art.py sprites/switch.png sprites/switch_hd.png 4

The SWITCH! stamp was drawn at 172 px and gets blown up to roughly three times
that on screen, where every stair-step in the outline showed. This scales it
up, blurs the steps into ramps, then pulls the ramps back into hard edges:

- alpha is re-thresholded, so the silhouette gets a clean one-pixel edge;
- the black ink outline is snapped away from the fill, since the source only
  ever uses pure black for ink;
- the light grey shading inside the letters (everything at or above
  SHADE_FLOOR) is left exactly as drawn.

Needs numpy and Pillow. The source file is never modified.
"""

import sys

import numpy as np
from PIL import Image, ImageFilter

## Blur radius in source pixels. Enough to melt a one-pixel stair-step, not so
## much that corners go soft.
SIGMA = 0.7
## The source shades its fills between this and white; below it is ink.
SHADE_FLOOR = 0.75


def smoothstep(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def upscale(source, scale):
    big = source.resize((source.width * scale, source.height * scale), Image.BICUBIC)

    # Premultiplied, or the transparent (black) surround bleeds into the edges.
    pixels = np.asarray(big).astype(float) / 255.0
    pixels[..., :3] *= pixels[..., 3:4]
    blurred = Image.fromarray((pixels * 255.0).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(scale * SIGMA)
    )
    pixels = np.asarray(blurred).astype(float) / 255.0

    alpha = smoothstep(0.42, 0.58, pixels[..., 3])
    lum = np.clip(pixels[..., :3].mean(axis=2) / np.maximum(pixels[..., 3], 1e-3), 0.0, 1.0)
    lum = np.where(lum >= SHADE_FLOOR, lum, smoothstep(0.32, 0.48, lum) * SHADE_FLOOR)

    out = np.dstack([lum, lum, lum, alpha])
    return Image.fromarray((out * 255.0).round().astype(np.uint8))


def main():
    source_path, output_path, scale = sys.argv[1], sys.argv[2], int(sys.argv[3])
    upscale(Image.open(source_path).convert("RGBA"), scale).save(output_path)
    print("wrote", output_path)


if __name__ == "__main__":
    main()
