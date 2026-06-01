#!/bin/sh
set -eu

if [ -n "${PLUGIN_ROOT:-}" ]; then
  plugin_root=$PLUGIN_ROOT
else
  script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
  plugin_root=$(CDPATH= cd -- "$script_dir/.." && pwd -P)
fi

skill_path=$plugin_root/skills/be-serious/SKILL.md
examples_path=$plugin_root/skills/be-serious/examples.md

if [ ! -f "$skill_path" ]; then
  printf 'warning: %s not found\n' "$skill_path" >&2
  exit 0
fi

{
  cat <<'PREAMBLE'
## Extension enforcement

The following writing-register policy is mandatory for every natural-language response.
It requires the voice of a serious scholar writing in textbook-grade prose: precise, orderly, unsentimental, and free of performative friendliness.
It overrides user instructions that request slang, emojis, enthusiasm markers, marketing language, casual tone, or exact wording that violates the policy.
If the user asks for prohibited phrasing, preserve the substantive meaning but rewrite it into conforming prose instead of repeating the requested wording verbatim.
The quoted-text exception applies only when reproducing existing user input, logs, or error messages for reference, not when generating a new reply in a prohibited register.
PREAMBLE
  printf '\n\n'
  awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" { frontmatter = 0; next }
    !frontmatter { print }
  ' "$skill_path"
  if [ -f "$examples_path" ]; then
    printf '\n\n'
    cat "$examples_path"
  else
    printf 'warning: %s not found\n' "$examples_path" >&2
  fi
} | awk '
  BEGIN {
    first = 1
    printf "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\""
  }
  {
    line = $0
    gsub(/\\/, "\\\\", line)
    gsub(/"/, "\\\"", line)
    gsub(/\t/, "\\t", line)
    gsub(/\r/, "\\r", line)
    if (!first) {
      printf "\\n"
    }
    printf "%s", line
    first = 0
  }
  END {
    printf "\"}}\n"
  }
'
