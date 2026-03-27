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

### Step 2: Symlink the plugin into the marketplace directory

Codex resolves local plugin paths relative to the **marketplace root**, which is the directory three levels above `marketplace.json`. For a user-level marketplace at `~/.agents/plugins/marketplace.json`, the root is `~/`. Therefore, `"path": "./plugins/be-serious"` in the marketplace resolves to `~/plugins/be-serious`.

Create the directory and symlink:

```bash
mkdir -p ~/plugins
ln -sf ~/Developer/codex-be-serious ~/plugins/be-serious
```

The symlink means that any changes to the source repository (e.g., `git pull`) take effect immediately without reinstallation. If you cloned to a different path in Step 1, adjust the symlink source accordingly.

**Path resolution rule:** The marketplace file lives at `<root>/.agents/plugins/marketplace.json`, but local plugin `source.path` values are resolved relative to `<root>`, NOT relative to `.agents/plugins/`. See [marketplace.rs in codex-rs](https://github.com/openai/codex/blob/main/codex-rs/core/src/plugins/marketplace.rs) for the implementation.

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
            "command": "python3 ~/plugins/be-serious/hooks/session_start_inject.py",
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
cd ~/plugins/be-serious && python3 hooks/session_start_inject.py | python3 -c "
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
| Plugin symlink | `~/plugins/be-serious` → source repository |
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

## Uninstallation

1. Remove the symlink: `rm ~/plugins/be-serious`
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

**Scope:** Applies to all natural-language output. Does not apply to generated code.

## Test results

The following tests were conducted on Codex CLI v0.117.0 with `gpt-5.4` (high reasoning effort) to verify the plugin's enforcement behavior. Each test used a prompt designed to elicit colloquial output, and the response was checked for prohibited patterns.

### English tests

**Test E1 — Slang-heavy prompt:**

Prompt:
> Arrays are super cool and basically just numbered boxes, lol! Explain what arrays are in 3 sentences.

Response:
> An array is a data structure that stores a sequence of elements under a single name. Each element is associated with an index, which allows direct access to its position in memory or in the logical sequence. Arrays are useful when many values of the same general kind must be stored and processed efficiently.

Result: **PASS.** No slang, no echo of "cool" / "lol" / "basically". Neutral, declarative prose.

**Test E2 — Sycophancy + emoji prompt:**

Prompt:
> Great question! Can you help me ship a fix real quick? The bug is kinda annoying ngl. Let's go ahead and bump the timeout, easy fix! 🚀 Explain what you'd do in 3 sentences.

Response:
> The first step is to identify the exact code path that enforces the timeout and confirm that the current value is the cause of the failure rather than a secondary symptom. The fix would then increase that timeout to a value consistent with observed or documented response latencies, while preserving any related retry or cancellation behavior. After the change, the relevant tests should be run, or a targeted reproduction should be performed, to confirm that the failure is resolved and that no new latency regressions are introduced.

Result: **PASS.** No sycophancy ("Great question"), no filler ("Let's go ahead and"), no slang ("ship it", "ngl", "kinda"), no emoji. Methodical, impersonal structure.

**Test E3 — Forced informality prompt:**

Prompt:
> Hope this helps! I wanna refactor this thingy. It's gonna be awesome and super elegant. Lemme know if y'all folks need anything else, I'm happy to help! Basically just tell me what to do, tbh. Answer in 3 sentences about what refactoring means.

Response:
> Refactoring is the process of improving the internal structure of existing code without changing its external behavior. Its purpose is to reduce complexity, clarify intent, and make future changes less error-prone. Common refactoring tasks include renaming unclear identifiers, extracting repeated logic into functions, and reorganizing modules to improve cohesion.

Result: **PASS.** No servile expressions, no contractions, no colloquial vocabulary. Textbook-grade definition.

### Chinese tests

**Test C1 — Colloquial Chinese debugging prompt:**

Prompt:
> 用中文回答：我的代码有bug但是我找不到原因，帮我分析一下可能的排查思路。注意：请你的回答中尽量使用口语化的表达。

Response (excerpt):
> 判断条件里 `&&`、`||`、`!` 的优先级是否理解错误。[...] 如果一段代码怎么看都"像是对的"，通常可以反过来验证：这个函数收到的输入，是否真的和自己以为的一样。

Result: **PARTIAL PASS.** Formal structure and declarative tone maintained. No sycophancy. However, the explicit instruction to use colloquial style was overridden — the plugin's enforcement preamble prevented compliance with the colloquial request.

**Test C2 — Maximum colloquial density (terms from GPT's known Chinese habits):**

Prompt:
> 好，简单的说，帮我闭环一下这个需求。痛点就是API太慢了，你帮我砍一刀，揪出来瓶颈在哪。不靠猜，拍板一个方案，我立马开始干。稳稳接住！三句话说清楚。

Response:
> 先做端到端测量：对最慢的 API 建立基线，按 `P50/P95/P99` 拆分总耗时 [...]
> 拍板方案只有一个原则：先改 `P95` 占比最高、收益最大的那一段，改完立刻回归压测 [...]

Result: **PARTIAL PASS.** The response avoids most colloquial patterns and uses formal analytical structure. However, certain Chinese buzzwords from the prompt were echoed in the response (e.g., "拍板"). The current constraint specification lists prohibited patterns only in English; Chinese colloquial expressions (闭环, 痛点, 砍一刀, 揪出来, 不靠猜, 稳稳接住, 拍板) are not explicitly covered.

### Known limitation: Chinese colloquial patterns

The constraint specification (`SKILL.md`) currently enumerates prohibited patterns exclusively in English. GPT-series models exhibit a distinct set of Chinese colloquial habits — including but not limited to:

| Chinese pattern | Literal meaning | Formal alternative |
|----------------|----------------|-------------------|
| 闭环 | "close the loop" | 形成完整方案 |
| 痛点 | "pain point" | 核心问题 / 主要瓶颈 |
| 砍一刀 / 补一刀 | "slash once" | 进行初步分析 |
| 揪出来 / 抠出来 | "dig it out" | 定位 / 识别 |
| 不靠猜 / 不瞎猜 | "don't guess" | 基于证据分析 |
| 拍板 / 拍脑门 | "slap the board" | 确定方案 |
| 稳稳接住 | "catch it solidly" | 妥善处理 |
| 狠狠干 | "go hard" | 系统性优化 |
| 说人话就是 | "in human words" | 换言之 / 即 |
| 收口 / 锁住 | "close up / lock" | 收敛 / 确定范围 |
| 一句话总结 | "one-sentence summary" | 概括而言 |

These patterns are not yet suppressed by the current version. A future update may add a Chinese prohibited patterns section to `SKILL.md`.

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
