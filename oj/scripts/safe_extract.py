#!/usr/bin/env python3
"""Extract a submission ZIP without allowing it to write outside its job directory."""
import os
import shutil
import stat
import sys
import zipfile
from pathlib import Path, PurePosixPath

archive = Path(sys.argv[1])
destination = Path(sys.argv[2]).resolve()
max_files = 200
max_size = 30 * 1024 * 1024

with zipfile.ZipFile(archive) as bundle:
    entries = bundle.infolist()
    if len(entries) > max_files:
        raise SystemExit("archive contains too many files")
    if sum(entry.file_size for entry in entries) > max_size:
        raise SystemExit("archive is too large after extraction")

    # Finder commonly wraps all files in one project directory and adds __MACOSX.
    # Accept that wrapper while keeping the task files at the extraction root.
    content_entries = [entry for entry in entries if PurePosixPath(entry.filename).parts[:1] != ("__MACOSX",)]
    roots = {PurePosixPath(entry.filename).parts[0] for entry in content_entries if PurePosixPath(entry.filename).parts}
    wrapper = next(iter(roots)) if len(roots) == 1 else None

    for entry in content_entries:
        path = PurePosixPath(entry.filename)
        mode = entry.external_attr >> 16
        if path.is_absolute() or ".." in path.parts or stat.S_ISLNK(mode):
            raise SystemExit(f"unsafe archive entry: {entry.filename}")

    for entry in content_entries:
        path = PurePosixPath(entry.filename)
        if wrapper:
            path = path.relative_to(wrapper)
        if not path.parts:
            continue
        target = (destination / path).resolve()
        if os.path.commonpath([destination, target]) != str(destination):
            raise SystemExit(f"unsafe archive entry: {entry.filename}")
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        with bundle.open(entry) as source, target.open("wb") as output:
            shutil.copyfileobj(source, output)
