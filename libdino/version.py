import argparse
import subprocess
import re


def compute_version_from_file(file):
    try:
        with open(file) as f:
            version_from_file = f.read().strip()
        if version_from_file != "":
            if version_from_file.startswith("RELEASE "):
                return version_from_file[8:].strip()
            if version_from_file.startswith("PRERELEASE "):
                return version_from_file[11:].strip()
            return version_from_file
    except FileNotFoundError:
        pass
    return None


def compute_version_from_git(git_repo, git):
    try:
        git_release_tag = subprocess.check_output([git, "describe", "--tags", "--abbrev=0"],
                                                  cwd=git_repo, text=True).strip()
        if re.match("^v?([0-9]+[.]?[0-9]*[.]?[0-9]*)(-[.0-9A-Za-z-]+)?([+][.0-9A-Za-z-]+)?$", git_release_tag) is None:
            return None
        git_describe = subprocess.check_output([git, "describe", "--tags"], cwd=git_repo, text=True).strip()
        if git_release_tag == git_describe:
            return git_release_tag[1:]
        matches = re.match("^.*-([0-9]+)-g([0-9a-f]+)$", git_describe)
        if matches is None:
            return None
        git_tag_offset = matches.groups()[0]
        git_commit_hash = matches.groups()[1]
        git_commit_time = subprocess.check_output([git, "show", "--format=%cd", "--date=format:%Y%m%d", "-s"],
                                                  cwd=git_repo, text=True).strip()
        return "%s~git%s.%s.%s" % (git_release_tag[1:], git_tag_offset, git_commit_time, git_commit_hash)
    except subprocess.CalledProcessError:
        pass
    return None


def compute_version(file, git_repo, git):
    version_from_file = compute_version_from_file(file)
    if version_from_file is not None:
        return version_from_file
    version_from_git = compute_version_from_git(git_repo, git)
    if version_from_git is not None:
        return version_from_git
    return ""


def main():
    p = argparse.ArgumentParser(description="Compute the Dino version")
    p.add_argument("--git-repo", help="Path to checked out git repository")
    p.add_argument("--git", help="Path to git executable", default="git")
    p.add_argument("version_file", metavar="VERSION_FILE",
                   help="Use this file's contents as version if the file exists")
    p.add_argument("ignored", nargs="*", help=argparse.SUPPRESS)
    args = p.parse_args()
    version = compute_version(args.version_file, args.git_repo, args.git)
    print(version)


if __name__ == "__main__":
    main()
