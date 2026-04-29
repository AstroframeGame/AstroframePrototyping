import os
import shutil
import subprocess
import argparse
import scripts.itch_deploy as itch
import scripts.steam_deploy as steam
from scripts.info_git import write_build_info, get_version
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

PRESETS = {
    "win": "Windows Desktop",
    "linux": "Linux",
    "mac": "macOS",
    "win32": "Windows 32 Bit"
}
EXE_EXTENTIONS = {
    "win": ".exe",
    "linux": "",
    "mac": ".app",
    "win32": ".exe"
}
DEPLOY_PLATFORM = [
    "itch",
    "steam"
]

def clean():
    if os.path.exists("builds"):
        shutil.rmtree("builds")
        print("Deleted builds folder.")
    else:
        print("No builds folder to delete.")

def build_and_zip(platform="win"):
    if platform not in PRESETS:
        raise ValueError(f"Unknown platform '{platform}'. Choose from: {list(PRESETS.keys())}")
    
    project_name = os.getenv("PROJECT_NAME")
    godot_path = os.getenv("GODOT_PATH")
    write_build_info(platform)
    build_dir = os.path.join("builds", project_name + "_" + platform)
    os.makedirs(build_dir, exist_ok=True)
    gdignore_path = os.path.join("builds", ".gdignore")
    if not os.path.exists(gdignore_path):
        open(gdignore_path, "w").close()
        print("Created .gdignore in builds folder.")

    exe_path = os.path.join(build_dir, project_name + EXE_EXTENTIONS[platform])

    subprocess.run([godot_path, "--headless", "--export-release", PRESETS[platform], exe_path], check=True)
    shutil.copy("scripts/run_instructions.md", build_dir)
    
    zip_name = f"builds/{project_name}_{platform}"
    shutil.make_archive(zip_name, 'zip', build_dir)
    print(f"{platform} built to {zip_name}.zip")

def deploy(platform, deploy_platform):
    version = get_version()
    if deploy_platform == "all":
        for d in DEPLOY_PLATFORM:
            if d == "itch":
                itch.deploy(platform=platform,version=version)
            elif d == "steam":
                steam.deploy(platform=platform,version=version)
    else:
        d = deploy_platform
        if d == "itch":
            itch.deploy(platform=platform,version=version)
        elif d == "steam":
            steam.deploy(platform=platform,version=version)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--platform", default="win", choices=list(PRESETS.keys()) + ["all"])
    parser.add_argument("-c","--clean", action="store_true", help="Delete the builds folder")
    parser.add_argument("-d", "--deploy", default=None, choices=DEPLOY_PLATFORM + ["all"])
    args = parser.parse_args()

    if args.clean:
        clean()
    if args.platform == "all":
        for platform in PRESETS:
            build_and_zip(platform=platform)
        for platform in PRESETS:
            if args.deploy:
                deploy(platform=platform, deploy_platform=args.deploy)
        shutil.copy("scripts/run_instructions.md", "./builds")
    else:
        build_and_zip(platform=args.platform)
        if args.deploy:
            deploy(platform=args.platform, deploy_platform=args.deploy)