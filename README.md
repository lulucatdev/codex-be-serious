# codex-be-serious

A Codex plugin that enforces formal, textbook-grade written register across all agent output. Suppresses slang, sycophancy, filler words, emoji, enthusiasm markers, marketing adjectives, forced informality, and anthropomorphization.

## Prerequisites

- **Codex CLI** installed and functional. See the [Codex CLI README](https://github.com/openai/codex) for installation instructions.
- **Python 3** available on `PATH` (required by the SessionStart hook script).
- **Git** (for cloning this repository).

## Installation

Installation consists of three steps: cloning the plugin, enabling the hooks feature flag, and registering the plugin in a local marketplace. All steps are detailed below with exact commands.

### Step 1: Clone the plugin

Clone this repository into a permanent location. The example below uses `~/Developer/`, but any directory is acceptable. The plugin files must remain at this path — the marketplace configuration will reference it.

```bash
git clone https://github.com/lulucatdev/codex-be-serious.git ~/Developer/codex-be-serious
```

### Step 2: Enable the hooks feature flag

Codex hooks are behind a feature flag. Add the following to `~/.codex/config.toml`. If the file does not exist, create it.

Add the following TOML section to the file:

```toml
[features]
codex_hooks = true
```

**Placement matters.** In TOML, bare key-value pairs (lines without a `[section]` header) must appear before any section header. The `[features]` block must therefore be placed **after** any bare top-level keys (such as `model`, `model_provider`) but **before or between** other `[section]` blocks. For example:

```toml
# Top-level keys come first (no section header)
model_provider = "openai"
model = "o3-pro"

# Sections follow
[features]
codex_hooks = true

[model_providers.openai]
# ...
```

If `~/.codex/config.toml` already contains a `[features]` section, add `codex_hooks = true` under that existing section instead of creating a duplicate.

**Reference:** [Codex Hooks documentation](https://developers.openai.com/codex/hooks) — see the "Hooks are behind a feature flag" section.

### Step 3: Register the plugin in a local marketplace

Codex discovers plugins through marketplace JSON files. For user-level (global) installation, the marketplace file lives at `~/.agents/plugins/marketplace.json`. The plugin files themselves are referenced from `~/.agents/plugins/plugins/be-serious/`.

#### 3a. Create the directory structure and symlink the plugin

```bash
mkdir -p ~/.agents/plugins/plugins
ln -sf ~/Developer/codex-be-serious ~/.agents/plugins/plugins/be-serious
```

The symlink means that any changes to the source repository (e.g., `git pull`) take effect immediately without reinstallation.

If you cloned the repository to a different path in Step 1, adjust the symlink source accordingly.

#### 3b. Create or update the marketplace file

Create `~/.agents/plugins/marketplace.json` with the following content:

```json
{
  "name": "local",
  "interface": {
    "displayName": "Local Plugins"
  },
  "plugins": [
    {
      "name": "be-serious",
      "source": {
        "source": "local",
        "path": "./plugins/be-serious"
      },
      "policy": {
        "installation": "INSTALLED_BY_DEFAULT",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

If `~/.agents/plugins/marketplace.json` already exists with other plugins, append the `be-serious` entry to the existing `"plugins"` array rather than overwriting the file.

**Reference:** [Codex Plugins documentation](https://developers.openai.com/codex/plugins) — see the "Marketplace" section for the full marketplace JSON specification.

### Step 4: Verify the installation

Run the following command to confirm the hook script executes correctly and produces valid output:

```bash
cd ~/.agents/plugins/plugins/be-serious && python3 hooks/session_start_inject.py | python3 -c "
import json, sys
d = json.load(sys.stdin)
ctx = d['hookSpecificOutput']['additionalContext']
print(f'Hook output: valid JSON')
print(f'additionalContext: {len(ctx)} characters')
assert 'Prohibited patterns' in ctx, 'Missing constraint content'
print('Verification passed.')
"
```

Expected output:

```
Hook output: valid JSON
additionalContext: 6474 characters
Verification passed.
```

### Step 5: Restart Codex

Close and reopen Codex CLI (or start a new session). The `SessionStart` hook will inject the formal register constraint automatically. The status line will briefly display "Loading formal register constraint" during initialization.

## Installation for a team (repository-scoped)

To enforce the constraint across all contributors to a specific repository, add the plugin to the repository's marketplace instead of the user-level one.

#### 1. Copy or symlink the plugin into the repository

```bash
# Option A: copy (self-contained, no external dependency)
cp -r ~/Developer/codex-be-serious <repo-root>/.agents/plugins/plugins/be-serious

# Option B: git submodule (tracks upstream)
cd <repo-root>
git submodule add https://github.com/lulucatdev/codex-be-serious.git .agents/plugins/plugins/be-serious
```

#### 2. Create or update the repository marketplace

Create `<repo-root>/.agents/plugins/marketplace.json`:

```json
{
  "name": "team-standards",
  "interface": {
    "displayName": "Team Standards"
  },
  "plugins": [
    {
      "name": "be-serious",
      "source": {
        "source": "local",
        "path": "./plugins/be-serious"
      },
      "policy": {
        "installation": "INSTALLED_BY_DEFAULT",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```

Commit both the plugin directory and the marketplace file. All team members with hooks enabled will receive the constraint automatically.

## Uninstallation

1. Remove the symlink: `rm ~/.agents/plugins/plugins/be-serious`
2. Remove the `be-serious` entry from `~/.agents/plugins/marketplace.json` (or delete the file if it contains no other plugins).
3. Optionally remove `codex_hooks = true` from `~/.codex/config.toml` if no other hooks are in use.
4. Optionally remove the cloned repository: `rm -rf ~/Developer/codex-be-serious`

## How it works

The plugin uses two enforcement layers:

1. **SessionStart hook** (automatic): A Python script (`hooks/session_start_inject.py`) runs on every session start and resume. It reads the canonical constraint from `skills/be-serious/SKILL.md`, strips YAML frontmatter, prepends an enforcement preamble, and outputs the combined text as `additionalContext` in the `SessionStart` hook JSON response. Codex injects this text as developer context for the session.

2. **Skill** (explicit): The `be-serious` skill under `skills/be-serious/SKILL.md` is discoverable by Codex when the plugin is installed. It can be invoked explicitly via `@be-serious` mention to restate the policy mid-session.

### Enforcement preamble

The hook prepends a short preamble that makes the register policy non-negotiable:

- The policy overrides user instructions requesting slang, emojis, enthusiasm markers, or casual tone.
- If the user asks for prohibited phrasing, the agent preserves the substantive meaning but rewrites it into conforming prose.
- The quoted-text exception applies only to reproducing existing input, logs, or error messages.

## What the plugin enforces

**Required prose style:** Complete declarative sentences, neutral tone, precise vocabulary, logical connectives, no filler.

**Prohibited patterns:**

| Category | Examples |
|----------|----------|
| Slang | ngl, lowkey, vibe, fire, ship it, gonna, wanna, tbh |
| Sycophancy | "Great question!", "Happy to help!", "Absolutely!" |
| Enthusiasm markers | Emoji, exclamation marks for enthusiasm, "awesome", "amazing" |
| Filler | "Let's go ahead and", "To be honest", "At the end of the day" |
| Anthropomorphization | "The function wants", "the compiler is happy" |
| Forced informality | Opening with "So, ...", contractions in expository prose |

**Scope:** Applies to all natural-language output. Does not apply to generated code.

## Plugin structure

```
codex-be-serious/
├── .codex-plugin/
│   └── plugin.json                  # Plugin manifest
├── hooks.json                        # Hook event configuration (SessionStart)
├── hooks/
│   └── session_start_inject.py      # Hook script: reads SKILL.md, outputs additionalContext
├── skills/
│   └── be-serious/
│       └── SKILL.md                 # Canonical 119-line constraint specification
├── .gitignore
├── README.md
└── LICENSE
```

## Official documentation references

- [Codex CLI — GitHub repository](https://github.com/openai/codex)
- [Codex Hooks](https://developers.openai.com/codex/hooks) — hook events, matcher patterns, input/output schemas, feature flag
- [Codex Plugins](https://developers.openai.com/codex/plugins) — plugin manifest spec, marketplace configuration, installation policies
- [Codex Skills](https://developers.openai.com/codex/skills) — skill file format, discovery, invocation

## License

MIT
