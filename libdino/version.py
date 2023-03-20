import argparse
import subprocess
VERSION_VALA = """\
namespace Dino {{

public const string VERSION = "{}";

}}
"""

def compute_version(file, git_repo, git):
    try:
        with open(file) as f:
            return f.read().strip()
    except FileNotFoundError:
        pass
    return subprocess.check_output([git, "describe", "--tags"], cwd=git_repo, text=True).strip()

def generate_version_vala(version):
    if "\\" in version or "\"" in version:
        raise ValueError(f"invalid version {version!r}")
    return VERSION_VALA.format(version)

def main():
    p = argparse.ArgumentParser(description="Compute the Dino version")
    p.add_argument("--git-repo", help="Path to checked out git repository")
    p.add_argument("--git", help="Path to git executable", default="git")
    p.add_argument("version_file", metavar="VERSION_FILE", help="Use this file's contents as version if the file exists")
    p.add_argument("output", metavar="OUTPUT", help="Vala file to output to")
    args = p.parse_args()
    out = generate_version_vala(compute_version(args.version_file, args.git_repo, args.git))
    with open(args.output, "w") as f:
        f.write(out)

if __name__ == "__main__":
    main()
