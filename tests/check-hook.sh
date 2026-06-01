#!/bin/sh
set -eu

plugin_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

PLUGIN_ROOT=$plugin_root /bin/sh "$plugin_root/hooks/session_start_inject.sh" | node -e '
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", chunk => input += chunk);
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const output = payload.hookSpecificOutput;
  if (!output || output.hookEventName !== "SessionStart") {
    throw new Error("invalid hook event payload");
  }
  const context = output.additionalContext;
  if (typeof context !== "string" || context.length < 1000) {
    throw new Error("missing register constraint context");
  }
  for (const needle of [
    "serious scholar",
    "textbook-grade prose",
    "Register constraint",
    "Prohibited patterns",
    "Calibration examples: serious scholarly prose",
    "The correction is warranted.",
    "这个修正成立。",
  ]) {
    if (!context.includes(needle)) {
      throw new Error(`missing expected phrase: ${needle}`);
    }
  }
  console.log(`Hook output valid: ${context.length} characters`);
});
'
