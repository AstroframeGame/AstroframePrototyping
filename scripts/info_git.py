import subprocess
import json
from datetime import datetime

BUILD_INFO_PATH = "build_info.json"

def get_version_from_tag():
    try:
        tag = subprocess.check_output(
            ["git", "describe", "--tags", "--abbrev=0", "--match", "v*.*"]
        ).decode().strip()  # e.g. "v0.2"
        parts = tag.lstrip("v").split(".")
        return int(parts[0]), int(parts[1]), tag
    except subprocess.CalledProcessError:
        return 0, 0, None

# when committing git tag va.b
# where A is major and B is minor. this will compute the version number

def get_git_info():
    try:
        commit = subprocess.check_output(["git", "rev-parse", "--short=6", "HEAD"]).decode().strip()
        branch = subprocess.check_output(["git", "rev-parse", "--abbrev-ref", "HEAD"]).decode().strip()
        return commit, branch
    except subprocess.CalledProcessError:
        return "unknown", "unknown"

def get_commit_count(version_tag):
    try:
        count = subprocess.check_output(
            ["git", "rev-list", f"{version_tag}..HEAD", "--count"]
        ).decode().strip()
        return int(count)
    except subprocess.CalledProcessError:
        return 0

def get_version():
    commit, branch = get_git_info()
    major, minor, tag = get_version_from_tag()
    count = get_commit_count(tag) if tag else 0
    return f"{major}.{minor}.{branch}.{count:03d}"

def write_build_info(platform="win"):
    commit, branch = get_git_info()
    version = get_version()
    data = {
        "commit": commit,
        "branch": branch,
        "platform": platform,
        "version": version,
        "date": datetime.now().strftime('%Y-%m-%d %H:%M'),
    }
    with open(BUILD_INFO_PATH, "w") as f:
        json.dump(data, f, indent=2)
    print(f"Wrote build info: {platform} | {branch}@{commit} | {version}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true", help="Write build_info.json")
    parser.add_argument("-p", "--platform", default="win")
    args = parser.parse_args()

    if args.refresh:
        write_build_info(platform=args.platform)
    else:
        print(f"{get_version()}")