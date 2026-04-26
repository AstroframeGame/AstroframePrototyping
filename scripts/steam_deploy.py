import os
import subprocess
import argparse
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

PLATFORMS = ["win", "linux", "mac"]
DEPOT_IDS = {
    "win":   os.getenv("STEAM_DEPOT_WIN"),
    "linux": os.getenv("STEAM_DEPOT_LINUX"),
    "mac":   os.getenv("STEAM_DEPOT_MAC"),
}

def get_path(platform):
    project_name = os.getenv("PROJECT_NAME")
    return f"builds/{project_name}_{platform}" # Folder

def build_vdf(platform, version):
    app_id      = os.getenv("STEAM_APP_ID").strip()
    depot_id    = DEPOT_IDS[platform].strip()
    build_path  = os.path.abspath(get_path(platform))  # used as ContentRoot
    description = f"{platform} build {version}"

    return f""""appbuild"
{{
    "appid"         "{app_id}"
    "desc"          "{description}"
    "buildoutput"   "./steam_output/"
    "contentroot"   "{build_path}\\"
    "setlive"       ""
    "preview"       "0"
    "depots"
    {{
        "{depot_id}"
        {{
            "FileMapping"
            {{
                "LocalPath"  "*"
                "DepotPath"  "."
                "recursive"  "1"
            }}
        }}
    }}
}}
"""

def deploy(platform="win", version="unknown"):
    steamcmd_exec = os.getenv("STEAMCMD_EXEC").strip()
    steam_user = os.getenv("STEAM_USER").strip()

    if not os.path.exists(steamcmd_exec):
        print(f"Error: Could not find steamcmd at: {steamcmd_exec}")
        return

    if platform not in PLATFORMS:
        print(f"Error: Unknown platform '{platform}'. Choose from: {PLATFORMS}")
        return

    build_path = get_path(platform)
    if not os.path.exists(build_path):
        print(f"Error: Could not find build folder at: {build_path}")
        return
    
    vdf_path = f"builds/steam_build_{platform}.vdf"
    with open(vdf_path, "w") as f:
        f.write(build_vdf(platform, version))

    try:
        subprocess.run([
            steamcmd_exec,
            "+login", steam_user,
            "+run_app_build", os.path.abspath(vdf_path),
            "+quit"
        ], check=True)
        print(f"Deployed -> Steam app {os.getenv('STEAM_APP_ID')} [{platform}]")
    except:
        print("There was an error with running SteamCMD")

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