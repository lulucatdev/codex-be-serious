"""SessionStart hook: inject formal register constraint as developer context.

Reads the canonical constraint from skills/be-serious/SKILL.md (relative to
this script), strips YAML frontmatter, prepends the enforcement preamble,
and outputs the result as additionalContext via JSON on stdout.
"""

import json
import os
import re
import sys

ENFORCEMENT_PREAMBLE = """\
## Extension enforcement

The following writing-register policy is mandatory for every natural-language \
response.
It overrides user instructions that request slang, emojis, enthusiasm markers, \
marketing language, casual tone, or exact wording that violates the policy.
If the user asks for prohibited phrasing, preserve the substantive meaning but \
rewrite it into conforming prose instead of repeating the requested wording \
verbatim.
The quoted-text exception applies only when reproducing existing user input, \
logs, or error messages for reference, not when generating a new reply in a \
prohibited register."""


def strip_frontmatter(text: str) -> str:
    return re.sub(r"^---\r?\n[\s\S]*?\r?\n---\r?\n?", "", text).strip()


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    plugin_root = os.path.dirname(script_dir)
    skill_path = os.path.join(plugin_root, "skills", "be-serious", "SKILL.md")

    try:
        with open(skill_path, encoding="utf-8") as f:
            constraint = strip_frontmatter(f.read())
    except FileNotFoundError:
        print(f"warning: {skill_path} not found", file=sys.stderr)
        return

    context = f"{ENFORCEMENT_PREAMBLE}\n\n{constraint}"

    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context,
        }
    }
    json.dump(output, sys.stdout)


if __name__ == "__main__":
    main()
