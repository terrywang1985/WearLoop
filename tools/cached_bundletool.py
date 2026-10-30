"""Run the official bundletool already in this workstation's Gradle cache.

This never downloads tools or dependencies. The cached Gradle module is not a
fat JAR; its manifest dependencies and AGP 9.1's aapt2-proto must be on the
classpath. Pass normal bundletool arguments, e.g. `version` or
`validate --bundle=build/app/outputs/bundle/release/app-release.aab`.
"""

import os
import re
import subprocess
import sys
import zipfile
from pathlib import Path


def resolve_classpath():
    cache = Path.home() / ".gradle/caches/modules-2/files-2.1"
    candidates = list((cache / "com.android.tools.build/bundletool/1.18.3").glob("*/*.jar"))
    if len(candidates) != 1:
        raise FileNotFoundError("Expected cached official bundletool 1.18.3; no download is attempted.")
    bundletool = candidates[0]
    with zipfile.ZipFile(bundletool) as archive:
        manifest = archive.read("META-INF/MANIFEST.MF").decode().replace("\r", "").replace("\n ", "")
    match = re.search(r"^Class-Path: (.+)$", manifest, re.MULTILINE)
    if not match:
        raise ValueError("Cached bundletool has no dependency manifest.")
    filenames = match.group(1).split()
    cached_jars = {p.name: p for p in cache.rglob("*.jar")}
    selected = [bundletool]
    for name in filenames:
        if name.startswith("aapt2-proto-"):
            # Matches the project's installed AGP 9.1.0 dependency resolution.
            aapt = list((cache / "com.android.tools.build/aapt2-proto").glob("9.1.0-*/*/*.jar"))
            if len(aapt) != 1:
                raise FileNotFoundError("AGP 9.1.0 aapt2-proto is not uniquely available in the local cache.")
            selected.append(aapt[0])
        elif name in cached_jars:
            selected.append(cached_jars[name])
        else:
            raise FileNotFoundError(f"Missing local dependency {name}; no download is attempted.")
    return os.pathsep.join(map(str, selected))


def main():
    java_home = os.environ.get("JAVA_HOME", r"D:\Program Files\Android\Android Studio\jbr")
    java = Path(java_home) / "bin/java.exe"
    if not java.is_file():
        raise FileNotFoundError("Set JAVA_HOME to the installed Android Studio JBR/JDK; java.exe was not found.")
    arguments = sys.argv[1:] or ["version"]
    command = [str(java), "-cp", resolve_classpath(),
               "com.android.tools.build.bundletool.BundleToolMain", *arguments]
    return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
