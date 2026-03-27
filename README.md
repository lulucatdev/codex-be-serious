# codex-be-serious

A Codex plugin that enforces formal, textbook-grade written register across all agent output. Suppresses slang, sycophancy, filler words, emoji, enthusiasm markers, marketing adjectives, forced informality, and anthropomorphization.

## Prerequisites

- **Codex CLI** installed and functional. See the [Codex CLI README](https://github.com/openai/codex) for installation instructions.
- **Python 3** available on `PATH` (required by the SessionStart hook script).
- **Git** (for cloning this repository).

## Installation

**Recommended method:** Copy this page's URL and paste it to your AI coding agent (Codex, Claude Code, or any agent with web access and shell access). The agent can read this README, understand the installation steps, and execute them automatically. For example, in Codex:

```
Install the codex-be-serious plugin from https://github.com/lulucatdev/codex-be-serious
```

The agent will clone the repository, configure the marketplace, enable the feature flags, and register the plugin — all from the instructions below.

If you prefer to install manually, follow the step-by-step guide below.

---

### Step 1: Clone the plugin

Clone this repository into a permanent location. The example below uses `~/Developer/`, but any directory is acceptable.

```bash
git clone https://github.com/lulucatdev/codex-be-serious.git ~/Developer/codex-be-serious
```

### Step 2: Copy or symlink the plugin into the Codex plugins directory

The [official documentation](https://developers.openai.com/codex/plugins#install-a-local-plugin-manually) recommends storing personal plugins under `~/.codex/plugins/`. Create the directory and symlink:

```bash
mkdir -p ~/.codex/plugins
ln -sf ~/Developer/codex-be-serious ~/.codex/plugins/be-serious
```

The symlink means that any changes to the source repository (e.g., `git pull`) take effect immediately without reinstallation. If you cloned to a different path in Step 1, adjust the symlink source accordingly.

**Path resolution rule:** The marketplace file lives at `<root>/.agents/plugins/marketplace.json`, and `source.path` values are resolved relative to `<root>` (three levels above `marketplace.json`), NOT relative to `.agents/plugins/`. For a personal marketplace at `~/.agents/plugins/marketplace.json`, the root is `~/`, so `"./.codex/plugins/be-serious"` resolves to `~/.codex/plugins/be-serious`. See [marketplace.rs in codex-rs](https://github.com/openai/codex/blob/main/codex-rs/core/src/plugins/marketplace.rs) for the implementation.

### Step 3: Create the marketplace file

Create `~/.agents/plugins/marketplace.json`:

```bash
mkdir -p ~/.agents/plugins
```

Write the following content to `~/.agents/plugins/marketplace.json`:

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
        "path": "./.codex/plugins/be-serious"
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

### Step 4: Enable feature flags and register the plugin in Codex config

Edit `~/.codex/config.toml` to enable hooks, the plugin system, and mark the plugin as installed and enabled.

Add the following to the `[features]` section (create it if it does not exist):

```toml
[features]
codex_hooks = true
plugins = true
```

Then add the plugin registration section:

```toml
[plugins."be-serious@local"]
enabled = true
```

**Placement matters.** In TOML, bare key-value pairs (lines without a `[section]` header) must appear before any section header. The `[features]` block must be placed **after** any bare top-level keys (such as `model`, `model_provider`) but **before or between** other `[section]` blocks. For example:

```toml
# Top-level keys come first (no section header)
model_provider = "openai"
model = "o3-pro"

# Sections follow
[features]
codex_hooks = true
plugins = true

[plugins."be-serious@local"]
enabled = true

[model_providers.openai]
# ...
```

If `~/.codex/config.toml` already contains a `[features]` section, add the keys under that existing section instead of creating a duplicate.

**Reference:** [Codex Hooks documentation](https://developers.openai.com/codex/hooks) — see the "Hooks are behind a feature flag" section.

### Step 5: (Optional) Register the SessionStart hook globally

The plugin includes a `hooks.json` that Codex loads when the plugin is installed. For additional reliability, you can also register the hook directly in `~/.codex/hooks.json`, which fires regardless of the plugin's TUI installation state.

Create `~/.codex/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.codex/plugins/be-serious/hooks/session_start_inject.py",
            "statusMessage": "Loading formal register constraint"
          }
        ]
      }
    ]
  }
}
```

If `~/.codex/hooks.json` already exists with other hooks, merge the `SessionStart` entry into the existing structure.

**Reference:** [Codex Hooks documentation](https://developers.openai.com/codex/hooks) — see the "Where Codex looks for hooks" and "SessionStart" sections.

### Step 6: Verify the installation

Run the following command to confirm the hook script executes correctly:

```bash
cd ~/.codex/plugins/be-serious && python3 hooks/session_start_inject.py | python3 -c "
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

### Step 7: Restart Codex

Close and reopen Codex CLI (or start a new session). The `SessionStart` hook will inject the formal register constraint automatically. The status line will briefly display "Loading formal register constraint" during initialization.

## Installation summary

| Item | Path |
|------|------|
| Source repository | `~/Developer/codex-be-serious` (or custom path) |
| Plugin symlink | `~/.codex/plugins/be-serious` → source repository |
| Marketplace file | `~/.agents/plugins/marketplace.json` |
| Codex config | `~/.codex/config.toml` |
| Global hooks (optional) | `~/.codex/hooks.json` |

## Installation for a team (repository-scoped)

To enforce the constraint across all contributors to a specific repository, add the plugin to the repository's marketplace instead of the user-level one.

#### 1. Copy or symlink the plugin into the repository

```bash
# Option A: copy (self-contained, no external dependency)
cp -r ~/Developer/codex-be-serious <repo-root>/plugins/be-serious

# Option B: git submodule (tracks upstream)
cd <repo-root>
git submodule add https://github.com/lulucatdev/codex-be-serious.git plugins/be-serious
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

Note: for repository-scoped marketplaces, `source.path` is resolved relative to the repository root (the directory containing `.git/`). Commit both the plugin directory and the marketplace file.

## Updating

If the plugin was installed following the steps above (symlink from `~/.codex/plugins/be-serious` to the cloned repository), updating requires only a `git pull` in the source directory:

```bash
cd ~/Developer/codex-be-serious && git pull
```

The symlink ensures that changes in the source repository take effect immediately. The next Codex session will load the updated `SKILL.md` via the SessionStart hook. No reinstallation or configuration changes are needed.

## Uninstallation

1. Remove the symlink: `rm ~/.codex/plugins/be-serious`
2. Remove the `be-serious` entry from `~/.agents/plugins/marketplace.json` (or delete the file if it contains no other plugins).
3. Remove the `[plugins."be-serious@local"]` section from `~/.codex/config.toml`.
4. Optionally remove `~/.codex/hooks.json` (or the `SessionStart` entry within it).
5. Optionally remove the cloned repository: `rm -rf ~/Developer/codex-be-serious`

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
| Chinese colloquial buzzwords | 闭环, 痛点, 砍一刀, 揪出来, 拍板, 稳稳接住, 说人话就是, 一句话总结 |

**Scope:** Applies to all natural-language output (including Chinese). Does not apply to generated code.

## Test results

Full test logs with prompts, responses, and per-term analysis are recorded in [tests/test-results-v0.2.0.md](tests/test-results-v0.2.0.md).

Summary (Codex CLI v0.117.0, gpt-5.4):

| Test | Language | Category | Result |
|------|----------|----------|--------|
| C1 | Chinese | Maximum colloquial density (闭环, 痛点, 砍一刀, 揪出来, 拍板, 稳稳接住) | PASS |
| C2 | Chinese | Colloquial terms round 2 (狠狠干, 说人话就是, 不踩坑, 收口, 一句话总结) | PARTIAL PASS |
| E1 | English | Heavy slang (ngl, lowkey, goated, ship it, mid, tbh) | PASS |
| E2 | English | Sycophancy + forced informality (Great question, happy to help, wanna, gonna) | PASS |

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
│       └── SKILL.md                 # Canonical constraint specification
├── tests/
│   └── test-results-v0.2.0.md      # Full test logs
├── .gitignore
├── README.md
└── LICENSE
```

## Other platforms

This plugin is a Codex port of [pi-be-serious](https://github.com/lulucatdev/pi-be-serious), which was originally built for the [pi](https://github.com/mariozechner/pi) coding agent. The constraint specification and enforcement preamble are identical; only the injection mechanism differs.

| Platform | Repository | Enforcement mechanism |
|----------|------------|----------------------|
| OpenAI Codex CLI | this repository | `SessionStart` hook with `additionalContext` |
| pi | [pi-be-serious](https://github.com/lulucatdev/pi-be-serious) | `before_agent_start` extension hook |
| Claude Code | Built-in skill at `~/.claude/skills/be-serious/` | Superpowers skill auto-trigger |

## Official documentation references

- [Codex CLI — GitHub repository](https://github.com/openai/codex)
- [Codex Hooks](https://developers.openai.com/codex/hooks) — hook events, matcher patterns, input/output schemas, feature flag
- [Codex Plugins](https://developers.openai.com/codex/plugins) — plugin manifest spec, marketplace configuration, installation policies
- [Codex Skills](https://developers.openai.com/codex/skills) — skill file format, discovery, invocation
- [marketplace.rs source](https://github.com/openai/codex/blob/main/codex-rs/core/src/plugins/marketplace.rs) — plugin path resolution implementation

## License

MIT
