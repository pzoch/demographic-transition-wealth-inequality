"""Patch path strings in a Stata .stpr (Java ObjectOutputStream) in place.

Java serialization string format (TC_STRING): 0x74 <uint16 BE length> <utf8 bytes>.
We locate each known bad path string (preceded by 0x74 + correct length prefix)
and replace both the length prefix and the bytes with the new path.

This is safe because:
- Each target string is unique in the file.
- We do not add/remove items — handle-table offsets stay consistent.
- No back-references (q ~ XX) point to these strings; they're referenced by value.
"""
import sys
import struct
from pathlib import Path

REWRITES = [
    # (old_path, new_path)
    (r"..\..\_Paper_16_EJ_replication\inputs_stata_code\tfp\M02robustness_prepare_gamma.do",
     r"..\inputs_stata_code\tfp\M02robustness_prepare_gamma.do"),
]

TC_STRING = 0x74

def build_tcstring(s: str) -> bytes:
    utf8 = s.encode("utf-8")
    if len(utf8) > 0xFFFF:
        raise ValueError("string too long for TC_STRING")
    return bytes([TC_STRING]) + struct.pack(">H", len(utf8)) + utf8

def patch(data: bytes, old: str, new: str) -> bytes:
    old_block = build_tcstring(old)
    new_block = build_tcstring(new)
    count = data.count(old_block)
    if count != 1:
        raise RuntimeError(f"expected exactly 1 occurrence of {old!r}, got {count}")
    return data.replace(old_block, new_block, 1)

def main(path_str: str):
    path = Path(path_str)
    data = path.read_bytes()
    backup = path.with_suffix(path.suffix + ".bak")
    if not backup.exists():
        backup.write_bytes(data)
        print(f"backup saved: {backup}")
    for old, new in REWRITES:
        print(f"rewriting: {old}")
        print(f"     ->    {new}")
        data = patch(data, old, new)
    path.write_bytes(data)
    print(f"wrote: {path} ({len(data)} bytes)")

if __name__ == "__main__":
    main(sys.argv[1])
