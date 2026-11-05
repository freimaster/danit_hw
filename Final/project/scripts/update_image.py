"""Update only the Kustomize image after a successful Docker Hub push."""

import argparse
import re
from pathlib import Path


def update_image(path, image, tag):
    if not re.fullmatch(r"[a-z0-9]+(?:[._-][a-z0-9]+)*/[a-z0-9]+(?:[._-][a-z0-9]+)*", image):
        raise ValueError("Expected a Docker Hub image: username/repository")
    if not re.fullmatch(r"[0-9a-f]{40}", tag):
        raise ValueError("Expected a full Git commit SHA")
    content = path.read_text(encoding="utf-8")
    content, names = re.subn(r"(?m)^(    newName: ).+$", lambda m: m[1] + image, content)
    content, tags = re.subn(r"(?m)^(    newTag: ).+$", lambda m: m[1] + f'"{tag}"', content)
    if names != 1 or tags != 1:
        raise ValueError("Expected exactly one Kustomize image entry")
    path.write_text(content, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--file", type=Path, default=Path("k8s/kustomization.yaml"))
    args = parser.parse_args()
    update_image(args.file, args.image, args.tag)
