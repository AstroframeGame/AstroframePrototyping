import os
import subprocess
import argparse
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

PLATFORMS = ["win", "linux", "mac", "win32"]

def get_path(platform):
    project_name = os.getenv("PROJECT_NAME")
    return f"builds/{project_name}_{platform}.zip" # Zip File

def deploy(platform="win", version="unknown"):
    butler_exec = os.getenv("BUTLER_EXEC").strip()
    itch_user = os.getenv("ITCH_USER").strip()
    itch_game = os.getenv("ITCH_GAME").strip()
    print(itch_game, itch_user)

    if not os.path.exists(butler_exec):
        print(f"Error: Could not find butler.exe at: {butler_exec}")
        return

    if platform not in PLATFORMS:
        print(f"Error: Unknown platform '{platform}'. Choose from: {PLATFORMS}")
        return

    zip_path = get_path(platform)
    if not os.path.exists(zip_path):
        print(f"Error: Could not find build zip at: {zip_path}")
        return
    
    subprocess.run([
        butler_exec, "push",
        zip_path,
        f"{itch_user}/{itch_game}:{platform}",
        "--userversion", version
    ], check=True)
    print(f"Deployed -> {itch_user}/{itch_game}:{platform}")

def deploy_all(version):
    for platform in PLATFORMS:
        deploy(platform, version)

if __name__ == "__main__":
    from info_git import get_version
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--platform", default=None, choices=PLATFORMS + ["all"])
    args = parser.parse_args()

    if args.platform == "all":
        deploy_all(get_version())
    elif args.platform:
        version = get_version()
        deploy(args.platform, version)