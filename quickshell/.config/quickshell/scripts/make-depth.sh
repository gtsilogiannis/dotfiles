#!/usr/bin/env bash
# Cuts the subject out of a depth wallpaper, so the desktop can draw between them.
#
#   make-depth.sh <image>...      make the cutout of each image (skipped when
#                                 it is newer than the image)
#   make-depth.sh -f <image>...   make it again
#
# For each image it writes to ~/.local/share/depth/:
#   <name>.depth.png    the subject alone, RGBA, cropped to its bounding box
#   <name>.depth.json   the size of the image and where the crop sits in it,
#                       in pixels of the image, plus the layout preset of the
#                       widgets; a new run keeps the preset already there
#
# rembg runs in its own venv on a uv-managed Python, safe from system updates.
# The first run downloads the model (birefnet-general, ~1 GB; DEPTH_MODEL overrides).
set -euo pipefail

data="${XDG_DATA_HOME:-$HOME/.local/share}/depth"
venv="$data/venv"
py="$venv/bin/python"
export REMBG_HOME="$data/rembg"
export DEPTH_MODEL="${DEPTH_MODEL:-birefnet-general}"

force=0
if [[ "${1:-}" == -f ]]; then
    force=1
    shift
fi
if (( $# == 0 )); then
    echo "usage: make-depth.sh [-f] <image>..." >&2
    exit 1
fi
for file in "$@"; do
    [[ -f "$file" ]] || { echo "make-depth.sh: not a file: $file" >&2; exit 1; }
done

if [[ ! -x "$py" ]]; then
    command -v uv >/dev/null || { echo "make-depth.sh: uv is not installed" >&2; exit 1; }
    mkdir -p "$data"
    uv venv --python 3.13 "$venv"
    uv pip install --python "$py" "rembg[cpu]==2.0.87"
fi

mkdir -p "$data"
"$py" - "$data" "$force" "$@" <<'PY'
import json
import os
import sys

from PIL import Image, ImageOps
from rembg import new_session, remove

out_dir, force, files = sys.argv[1], sys.argv[2] == "1", sys.argv[3:]
session = None

for src in files:
    name = os.path.splitext(os.path.basename(src))[0]
    png = os.path.join(out_dir, name + ".depth.png")
    meta = os.path.join(out_dir, name + ".depth.json")
    if not force and os.path.exists(png) and os.path.exists(meta) \
            and os.path.getmtime(meta) >= os.path.getmtime(src):
        print(f"{name}: up to date")
        continue

    if session is None:
        session = new_session(os.environ["DEPTH_MODEL"])

    # Upright as QML shows it (autoTransform); read by content, not extension
    image = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
    # decontaminate removes the background color from soft edges (no halo)
    cut = remove(image, session=session, decontaminate=True)

    # Alpha up to 2% is mask noise
    box = cut.getchannel("A").point(lambda a: 255 if a > 5 else 0).getbbox()
    if box is None:
        print(f"{name}: no subject found", file=sys.stderr)
        continue
    cut.crop(box).save(png + ".part", format="PNG")
    os.replace(png + ".part", png)

    preset = "clock"
    if os.path.exists(meta):
        try:
            with open(meta) as f:
                preset = json.load(f).get("preset", preset)
        except (OSError, ValueError):
            pass
    info = {
        "version": 1,
        "source": os.path.abspath(src),
        "model": os.environ["DEPTH_MODEL"],
        "width": image.width,
        "height": image.height,
        "cutout": {"x": box[0], "y": box[1], "width": box[2] - box[0], "height": box[3] - box[1]},
        "preset": preset,
    }
    with open(meta + ".part", "w") as f:
        json.dump(info, f, indent=2)
        f.write("\n")
    os.replace(meta + ".part", meta)
    c = info["cutout"]
    print(f"{name}: {c['width']}x{c['height']} at {c['x']},{c['y']} of {image.width}x{image.height}")
PY
