"""Compare two 8-bit PNG screenshots without loading account content into logs."""

from __future__ import annotations

import json
import struct
import sys
import zlib
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"Not a PNG file: {path}")

    offset = len(PNG_SIGNATURE)
    idat = bytearray()
    width = height = bit_depth = color_type = None
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
            if bit_depth != 8 or compression != 0 or filtering != 0 or interlace != 0:
                raise ValueError("Only non-interlaced 8-bit PNGs are supported")
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break

    if width is None or height is None or color_type is None:
        raise ValueError("PNG is missing IHDR")
    bytes_per_pixel = {0: 1, 2: 3, 4: 2, 6: 4}.get(color_type)
    if bytes_per_pixel is None:
        raise ValueError(f"Unsupported PNG color type: {color_type}")

    raw = zlib.decompress(bytes(idat))
    stride = width * bytes_per_pixel
    expected = height * (stride + 1)
    if len(raw) != expected:
        raise ValueError("PNG scanline data length does not match IHDR")

    rows: list[bytearray] = []
    cursor = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        encoded = raw[cursor : cursor + stride]
        cursor += stride
        row = bytearray(stride)
        for index, value in enumerate(encoded):
            left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            up = previous[index]
            upper_left = previous[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = up
            elif filter_type == 3:
                predictor = (left + up) // 2
            elif filter_type == 4:
                estimate = left + up - upper_left
                distances = (abs(estimate - left), abs(estimate - up), abs(estimate - upper_left))
                predictor = (left, up, upper_left)[distances.index(min(distances))]
            else:
                raise ValueError(f"Unsupported PNG filter: {filter_type}")
            row[index] = (value + predictor) & 0xFF
        rows.append(row)
        previous = row

    pixels = bytearray(width * height * 4)
    destination = 0
    for row in rows:
        for index in range(0, len(row), bytes_per_pixel):
            if color_type == 6:
                rgba = row[index : index + 4]
            elif color_type == 2:
                rgba = row[index : index + 3] + b"\xff"
            elif color_type == 4:
                rgba = bytes((row[index], row[index], row[index], row[index + 1]))
            else:
                rgba = bytes((row[index], row[index], row[index], 255))
            pixels[destination : destination + 4] = rgba
            destination += 4
    return width, height, bytes(pixels)


def compare(left_path: Path, right_path: Path) -> dict[str, object]:
    left_width, left_height, left = read_png(left_path)
    right_width, right_height, right = read_png(right_path)
    if (left_width, left_height) != (right_width, right_height):
        raise ValueError("Screenshots must have identical dimensions")

    errors = []
    differing_pixels = 0
    for index in range(0, len(left), 4):
        error = sum(abs(left[index + channel] - right[index + channel]) for channel in range(4)) / 4
        errors.append(error)
        if error > 0:
            differing_pixels += 1
    errors.sort()
    total_pixels = left_width * left_height
    p95_index = min(len(errors) - 1, int(len(errors) * 0.95))
    return {
        "left": str(left_path),
        "right": str(right_path),
        "width": left_width,
        "height": left_height,
        "pixels": total_pixels,
        "differingPixels": differing_pixels,
        "differingPixelPercent": round(differing_pixels / total_pixels * 100, 4),
        "meanAbsoluteChannelError": round(sum(errors) / len(errors), 4),
        "p95PixelError": round(errors[p95_index], 4),
        "maximumPixelError": round(errors[-1], 4),
    }


if len(sys.argv) != 3:
    raise SystemExit("Usage: python tools/Compare-DiscordScreenshots.py official.png track-b.png")

print(json.dumps(compare(Path(sys.argv[1]), Path(sys.argv[2])), indent=2))
