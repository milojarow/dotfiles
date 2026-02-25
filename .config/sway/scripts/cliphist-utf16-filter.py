#!/usr/bin/env python3
# Intercepts clipboard data from wl-paste, converts UTF-16 LE to UTF-8 if
# needed, then pipes the result to cliphist store.
import sys
import subprocess


def normalize(data: bytes) -> bytes:
    # BOM-prefixed UTF-16 (FF FE)
    if data.startswith(b'\xff\xfe'):
        try:
            return data.decode('utf-16').encode('utf-8')
        except Exception:
            return data

    # Heuristic: if >=80% of odd-indexed bytes in the first 64 bytes are null,
    # the data is almost certainly UTF-16 LE without BOM.
    sample = data[:64]
    if len(sample) >= 4:
        odd_nulls = sum(1 for i in range(1, len(sample), 2) if sample[i] == 0)
        odd_count = len(sample) // 2
        if odd_count > 0 and odd_nulls / odd_count >= 0.80:
            try:
                return data.decode('utf-16-le').encode('utf-8')
            except Exception:
                return data

    return data


def main():
    data = sys.stdin.buffer.read()
    if not data:
        return
    result = normalize(data)
    subprocess.run(['cliphist', 'store'], input=result, check=False)


if __name__ == '__main__':
    main()
