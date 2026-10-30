"""Inspect an APK/AAB's native 16KB alignment and bundled ONNX provenance.

No third-party Python packages are required. For an AAB, Play-generated APK
packaging and compressed download sizes still need bundletool/Play validation.
"""

import argparse
import hashlib
import json
import struct
import zipfile
from pathlib import Path


def varint(data, offset):
    value = shift = 0
    while True:
        byte = data[offset]
        offset += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, offset
        shift += 7
        if shift > 70:
            raise ValueError("Malformed protobuf varint")


def protobuf_fields(data):
    offset = 0
    while offset < len(data):
        tag, offset = varint(data, offset)
        field, wire = tag >> 3, tag & 7
        if wire == 0:
            value, offset = varint(data, offset)
        elif wire in (1, 5):
            size = 8 if wire == 1 else 4
            value = data[offset : offset + size]
            offset += size
        elif wire == 2:
            size, offset = varint(data, offset)
            value = data[offset : offset + size]
            offset += size
        else:
            raise ValueError(f"Unsupported protobuf wire type {wire}")
        yield field, wire, value


def model_metadata(data):
    info = {"sha256": hashlib.sha256(data).hexdigest(), "sizeBytes": len(data)}
    metadata = {}
    for field, wire, value in protobuf_fields(data):
        if wire != 2:
            continue
        if field in (2, 3, 6):
            info[{2: "producer", 3: "producerVersion", 6: "description"}[field]] = value.decode("utf-8")
        elif field == 14:
            pair = {k: v.decode("utf-8") for k, w, v in protobuf_fields(value) if w == 2}
            if 1 in pair and 2 in pair:
                metadata[pair[1]] = pair[2]
    info["metadata"] = metadata
    return info


def elf_info(data):
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        raise ValueError("Expected a little-endian 64-bit ELF library")
    offset = struct.unpack_from("<Q", data, 32)[0]
    size, count = struct.unpack_from("<HH", data, 54)
    headers = [struct.unpack_from("<IIQQQQQQ", data, offset + i * size) for i in range(count)]
    loads = [h for h in headers if h[0] == 1]
    relros = [h for h in headers if h[0] == 0x6474E552]
    relro_checks = []
    for r in relros:
        own_segment = any(h[3] == r[3] and h[6] == r[6] for h in loads)
        relro_checks.append(own_segment or (r[3] + r[6]) % 16384 == 0)
    return {
        "loadAlignments": [h[7] for h in loads],
        "loadAlignment16KB": bool(loads) and all(h[7] >= 16384 for h in loads),
        "relro16KB": all(relro_checks),
    }


def audit(path):
    report = {"artifact": str(path.resolve()), "sizeBytes": path.stat().st_size,
              "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "native64": [], "models": {}}
    is_apk = path.suffix.lower() == ".apk"
    with zipfile.ZipFile(path) as archive, path.open("rb") as raw:
        for entry in archive.infolist():
            name = entry.filename
            if name.endswith(".so") and any(f"/{abi}/" in name for abi in ("arm64-v8a", "x86_64")):
                details = {"path": name, "sizeBytes": entry.file_size, **elf_info(archive.read(entry))}
                if is_apk and entry.compress_type == zipfile.ZIP_STORED:
                    raw.seek(entry.header_offset)
                    header = raw.read(30)
                    filename_length, extra_length = struct.unpack_from("<HH", header, 26)
                    data_offset = entry.header_offset + 30 + filename_length + extra_length
                    details["apkUncompressed16KB"] = data_offset % 16384 == 0
                report["native64"].append(details)
            elif name.endswith(".onnx"):
                report["models"][name] = model_metadata(archive.read(entry))
    report["native64ChecksPass"] = bool(report["native64"]) and all(
        row["loadAlignment16KB"] and row["relro16KB"] and row.get("apkUncompressed16KB", True)
        for row in report["native64"]
    )
    report["limitations"] = [
        "Static alignment checks do not replace a 16KB emulator/device runtime test.",
        "AAB compressed per-device download size and generated APK alignment require bundletool or Play Console.",
        "Model metadata is provenance evidence, not proof of distribution rights.",
    ]
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output", type=Path)
    arguments = parser.parse_args()
    result = audit(arguments.artifact)
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if arguments.output:
        arguments.output.parent.mkdir(parents=True, exist_ok=True)
        arguments.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    print(f"64-bit native checks: {'PASS' if result['native64ChecksPass'] else 'FAIL'}; "
          f"{len(result['native64'])} libraries; {len(result['models'])} models")
    raise SystemExit(0 if result["native64ChecksPass"] else 1)
