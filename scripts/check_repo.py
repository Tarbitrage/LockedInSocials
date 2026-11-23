#!/usr/bin/env python3
"""Dependency-free repository structure, icon and embedded JS syntax checks.

Run from the repository root: python3 scripts/check_repo.py
If Node.js or Swift are not available, those optional checks are skipped.
"""

from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import json

ROOT = Path(__file__).resolve().parents[1]


def fail(message):
    raise AssertionError(message)


def parse_png_size(path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        fail(f"Not a PNG: {path}")
    return struct.unpack(">II", data[16:24])


def get_js(swift_source):
    match = re.search(r'return #"""(.*?)"""#', swift_source, flags=re.DOTALL)
    if not match:
        fail("Missing embedded JavaScript raw string")
    return re.sub(r'\\#\([A-Za-z][A-Za-z0-9_]*\)', 'true', match.group(1))


def main():
    assert (ROOT / 'LockIn.xcworkspace/contents.xcworkspacedata').is_file()
    ET.parse(ROOT / 'LockIn.xcworkspace/contents.xcworkspacedata')
    for app in ['LockInGram', 'LockInTube']:
        base = ROOT / 'apps' / app
        src_dir = base / app
        proj = base / f'{app}.xcodeproj/project.pbxproj'
        assert proj.is_file(), proj
        assert 'org.example.' + app in proj.read_text(), 'Personal bundle ID found or placeholder absent'
        assert (src_dir / f'{app}App.swift').is_file()
        swift_file = src_dir / 'ContentView.swift'
        swift_text = swift_file.read_text()
        assert 'WKWebView' in swift_text
        assert 'MutationObserver' in swift_text
        assert 'UIViewRepresentable' in swift_text
        assert 'var webView: WKWebView?' in swift_text
        assert swift_text.count('return #"""') == 1

        scheme = base / f'{app}.xcodeproj/xcshareddata/xcschemes/{app}.xcscheme'
        ET.parse(scheme)
        icon_dir = src_dir / 'Assets.xcassets/AppIcon.appiconset'
        icon_info = json.loads((icon_dir / 'Contents.json').read_text())
        icon_path = icon_dir / icon_info['images'][0]['filename']
        assert parse_png_size(icon_path) == (1024, 1024), f'Wrong icon size: {app}'

        if shutil.which('node'):
            completed = subprocess.run(['node', '--check'], input=get_js(swift_text), text=True, capture_output=True)
            if completed.returncode:
                fail(f'JavaScript syntax for {app}: {completed.stderr}')
        if shutil.which('swiftc'):
            completed = subprocess.run(['swiftc', '-frontend', '-parse', str(swift_file), str(src_dir / f'{app}App.swift')], capture_output=True, text=True)
            if completed.returncode:
                fail(f'Swift source parse for {app}: {completed.stderr}')
        print(f'{app}: files, app icon and syntax checks passed')
    print('Static checks passed. iOS SDK compilation and live website behaviour not tested here.')


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        sys.exit(1)
