import os
import shutil
import subprocess
import argparse
from dotenv import load_dotenv

TARGETS = {
    "windows": {"preset": "astroframe-windows", "dir": "build/windows", "exe": "AstroFramePrototyping.exe"},
    "mac": {"preset": "macOS", "dir": "build/mac", "exe": "AstroFramePrototyping.zip"},
    "linux": {"preset": "Linux", "dir": "build/linux", "exe": "AstroFramePrototyping.x86_64"},
    "android": {"preset": "Android", "dir": "build/android", "exe": "AstroFramePrototyping.apk"}
}

SHORTCUTS = {"w": "windows", "m": "mac", "l": "linux", "a": "android"}

def build_and_zip(godot_bin, target_key):
    target_info = TARGETS[target_key]
    build_dir = target_info["dir"]
    
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)
    os.makedirs(build_dir, exist_ok=True)
    
    exe_path = os.path.join(build_dir, target_info["exe"])
    subprocess.run([godot_bin, "--headless", "--export-release", target_info["preset"], exe_path], check=True)
    
    zip_path = os.path.join("build", f"AstroFrame-{target_key.capitalize()}")
    if target_key == "mac":
        shutil.copy(exe_path, f"{zip_path}.zip")
    else:
        shutil.make_archive(zip_path, 'zip', build_dir)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-t", "--target", type=str, default="w")
    args = parser.parse_args()
    
    load_dotenv()
    godot_executable_path = os.getenv("GODOT_PATH")
    
    if not godot_executable_path:
        exit(1)

    target_input = args.target.lower()
    if target_input == "all":
        platforms = ["windows", "mac", "linux", "android"]
    else:
        resolved_target = SHORTCUTS.get(target_input, target_input)
        if resolved_target not in TARGETS:
            exit(1)
        platforms = [resolved_target]

    for p in platforms:
        build_and_zip(godot_executable_path, p)