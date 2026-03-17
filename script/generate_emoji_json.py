#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path

GROUP_RE = re.compile(r"^#\s*group:\s*(.+)$")
SUBGROUP_RE = re.compile(r"^#\s*subgroup:\s*(.+)$")
ENTRY_RE = re.compile(r"^([0-9A-F ]+)\s*;\s*([a-z-]+)\s*#\s*(\S+)\s*E([0-9.]+)\s*(.+)$")


def slugify(short_name):
    name = short_name.lower()
    name = name.replace("#", "hash").replace("*", "asterisk")
    name = re.sub(r"[^a-z0-9]+", "_", name)
    return name.strip("_")


def words_from(text):
    if not text:
        return []
    return [w for w in re.split(r"[\s_\-]+", text.lower()) if w]


def parse_emoji_test(path):
    group = None
    subgroup = None
    entries = []
    seen_names = set()

    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.rstrip()
        if not line:
            continue

        group_match = GROUP_RE.match(line)
        if group_match:
            group = group_match.group(1)
            continue

        subgroup_match = SUBGROUP_RE.match(line)
        if subgroup_match:
            subgroup = subgroup_match.group(1)
            continue

        entry_match = ENTRY_RE.match(line)
        if not entry_match:
            continue

        status = entry_match.group(2)
        if status != "fully-qualified":
            continue

        emoji = entry_match.group(3)
        short_name = entry_match.group(5).strip()

        name = slugify(short_name)
        if name in seen_names:
            codepoints = entry_match.group(1).replace(" ", "_").lower()
            name = f"{name}_{codepoints}"

        seen_names.add(name)

        keywords = []
        for word in words_from(short_name):
            if word not in keywords:
                keywords.append(word)
        for word in words_from(group):
            if word not in keywords:
                keywords.append(word)
        for word in words_from(subgroup):
            if word not in keywords:
                keywords.append(word)

        description = " ".join(keywords)

        entries.append(
            {
                "name": name,
                "value": name,
                "label": f":{name}:",
                "emoji": emoji,
                "description": description,
            }
        )

    return entries


def main():
    parser = argparse.ArgumentParser(
        description="Generate emoji JSON from unicode emoji-test.txt"
    )
    parser.add_argument(
        "source",
        nargs="?",
        default="vendor/emoji/emoji-test.txt",
        help="Path to emoji-test.txt (default: vendor/emoji/emoji-test.txt)",
    )
    parser.add_argument(
        "dest",
        nargs="?",
        default="app/assets/emoji/emoji_list.json",
        help="Output JSON path (default: app/assets/emoji/emoji_list.json)",
    )
    args = parser.parse_args()

    source = Path(args.source)
    dest = Path(args.dest)

    if not source.exists():
        raise SystemExit(f"Source file not found: {source}")

    entries = parse_emoji_test(source)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote {len(entries)} emojis to {dest}")


if __name__ == "__main__":
    main()
