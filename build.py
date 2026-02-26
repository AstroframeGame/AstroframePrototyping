import os
import shutil
import subprocess
from dotenv import load_dotenv

def build_and_zip(godot_bin, preset="astroframe-windows"):
    build_dir = os.path.join("build", "AstroFrame")
    os.makedirs(build_dir, exist_ok=True)
    
    exe_path = os.path.join(build_dir, "AstroFramePrototyping.exe")
    subprocess.run([godot_bin, "--headless", "--export-release", preset, exe_path], check=True)
    
    shutil.make_archive(build_dir, 'zip', build_dir)

if __name__ == "__main__":
    load_dotenv()
    godot_executable_path = os.getenv("GODOT_PATH")
    
    if godot_executable_path:
        build_and_zip(godot_bin=godot_executable_path)
    else:
        print("Error: GODOT_PATH not found in .env")