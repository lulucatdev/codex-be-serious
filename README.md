# codex-be-serious

一个 Codex 插件，强制所有 agent 输出采用正式、教科书级别的书面语体。抑制俚语、谄媚表达、填充词、emoji、营销形容词、强制非正式化、拟人化描述，以及中文口语化流行词。

A Codex plugin that enforces formal, textbook-grade written register across all agent output. Suppresses slang, sycophancy, filler words, emoji, enthusiasm markers, marketing adjectives, forced informality, anthropomorphization, and Chinese colloquial buzzwords.

## 前提条件 / Prerequisites

- **Codex CLI** 已安装且可用。参见 [Codex CLI README](https://github.com/openai/codex)。
- **Python 3** 在 `PATH` 中可用（SessionStart hook 脚本需要）。
- **Git**（用于克隆本仓库）。

## 安装 / Installation

**推荐方式：** 将本页 URL 粘贴给你的 AI 编程 agent（Codex、Claude Code 或任何具备网络访问和 shell 访问权限的 agent）。Agent 会读取本 README 并自动执行所有安装步骤。例如在 Codex 中：

**Recommended method:** Copy this page's URL and paste it to your AI coding agent (Codex, Claude Code, or any agent with web access and shell access). The agent can read this README, understand the installation steps, and execute them automatically. For example, in Codex:

```
Install the codex-be-serious plugin from https://github.com/lulucatdev/codex-be-serious
```

Agent 会克隆仓库、配置 marketplace、启用 feature flags 并注册插件。

如需手动安装，请按以下步骤操作。

If you prefer to install manually, follow the step-by-step guide below.

---

### 第一步：克隆插件 / Step 1: Clone the plugin

将本仓库克隆到一个固定位置。以下示例使用 `~/Developer/`，其他目录亦可。

Clone this repository into a permanent location. The example below uses `~/Developer/`, but any directory is acceptable.

```bash
git clone https://github.com/lulucatdev/codex-be-serious.git ~/Developer/codex-be-serious
```

### 第二步：将插件放入 Codex 插件目录 / Step 2: Copy or symlink the plugin into the Codex plugins directory

[官方文档](https://developers.openai.com/codex/plugins#install-a-local-plugin-manually)建议将个人插件存放在 `~/.codex/plugins/` 下。创建目录并建立符号链接：

The [official documentation](https://developers.openai.com/codex/plugins#install-a-local-plugin-manually) recommends storing personal plugins under `~/.codex/plugins/`. Create the directory and symlink:

```bash
mkdir -p ~/.codex/plugins
ln -sf ~/Developer/codex-be-serious ~/.codex/plugins/be-serious
```

符号链接使得源仓库的任何变更（如 `git pull`）立即生效，无需重新安装。如果第一步中克隆到了其他路径，请相应调整符号链接的源路径。

The symlink means that any changes to the source repository (e.g., `git pull`) take effect immediately without reinstallation. If you cloned to a different path in Step 1, adjust the symlink source accordingly.

**路径解析规则 / Path resolution rule:** Marketplace 文件位于 `<root>/.agents/plugins/marketplace.json`，`source.path` 相对于 `<root>`（`marketplace.json` 向上三层的目录）解析，而非相对于 `.agents/plugins/`。对于 `~/.agents/plugins/marketplace.json`，root 为 `~/`，因此 `"./.codex/plugins/be-serious"` 解析为 `~/.codex/plugins/be-serious`。参见 [marketplace.rs 源码](https://github.com/openai/codex/blob/main/codex-rs/core/src/plugins/marketplace.rs)。

### 第三步：创建 marketplace 文件 / Step 3: Create the marketplace file

创建 `~/.agents/plugins/marketplace.json`：

Create `~/.agents/plugins/marketplace.json`:

```bash
mkdir -p ~/.agents/plugins
```

写入以下内容 / Write the following content to `~/.agents/plugins/marketplace.json`:

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

如果 `~/.agents/plugins/marketplace.json` 已存在且包含其他插件，将 `be-serious` 条目追加到现有 `"plugins"` 数组中，而非覆盖整个文件。

If `~/.agents/plugins/marketplace.json` already exists with other plugins, append the `be-serious` entry to the existing `"plugins"` array rather than overwriting the file.

**参考 / Reference:** [Codex Plugins 文档](https://developers.openai.com/codex/plugins)

### 第四步：启用 feature flags 并注册插件 / Step 4: Enable feature flags and register the plugin in Codex config

编辑 `~/.codex/config.toml`，启用 hooks 和插件系统，并将插件标记为已安装和已启用。

Edit `~/.codex/config.toml` to enable hooks, the plugin system, and mark the plugin as installed and enabled.

在 `[features]` 部分添加（如不存在则创建）/ Add the following to the `[features]` section (create it if it does not exist):

```toml
[features]
codex_hooks = true
plugins = true
```

然后添加插件注册部分 / Then add the plugin registration section:

```toml
[plugins."be-serious@local"]
enabled = true
```

**TOML 格式注意事项 / Placement matters:** 在 TOML 中，裸键值对（没有 `[section]` 头的行）必须出现在任何 section header 之前。`[features]` 块必须放在裸顶层键（如 `model`、`model_provider`）之后、其他 `[section]` 块之前或之间。示例：

In TOML, bare key-value pairs (lines without a `[section]` header) must appear before any section header. Example:

```toml
# 顶层键在最前面 / Top-level keys come first
model_provider = "openai"
model = "o3-pro"

# Sections 随后 / Sections follow
[features]
codex_hooks = true
plugins = true

[plugins."be-serious@local"]
enabled = true

[model_providers.openai]
# ...
```

**参考 / Reference:** [Codex Hooks 文档](https://developers.openai.com/codex/hooks)

### 第五步（可选）：全局注册 SessionStart hook / Step 5: (Optional) Register the SessionStart hook globally

插件自带的 `hooks.json` 会在插件安装后由 Codex 加载。为增加可靠性，也可以直接在 `~/.codex/hooks.json` 中注册 hook，使其无论插件在 TUI 中的安装状态如何都能生效。

The plugin includes a `hooks.json` that Codex loads when the plugin is installed. For additional reliability, you can also register the hook directly in `~/.codex/hooks.json`, which fires regardless of the plugin's TUI installation state.

创建 `~/.codex/hooks.json` / Create `~/.codex/hooks.json`:

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

**参考 / Reference:** [Codex Hooks 文档](https://developers.openai.com/codex/hooks) — "Where Codex looks for hooks" 和 "SessionStart" 部分。

### 第六步：验证安装 / Step 6: Verify the installation

运行以下命令确认 hook 脚本正确执行 / Run the following command to confirm the hook script executes correctly:

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

### 第七步：重启 Codex / Step 7: Restart Codex

关闭并重新打开 Codex CLI（或开始新会话）。`SessionStart` hook 将自动注入正式语体约束。状态栏会短暂显示 "Loading formal register constraint"。

Close and reopen Codex CLI (or start a new session). The `SessionStart` hook will inject the formal register constraint automatically.

## 安装概览 / Installation summary

| 项目 / Item | 路径 / Path |
|------|------|
| 源仓库 / Source repository | `~/Developer/codex-be-serious` (or custom path) |
| 插件符号链接 / Plugin symlink | `~/.codex/plugins/be-serious` → source repository |
| Marketplace 文件 | `~/.agents/plugins/marketplace.json` |
| Codex 配置 / Codex config | `~/.codex/config.toml` |
| 全局 hooks（可选）/ Global hooks (optional) | `~/.codex/hooks.json` |

## 团队安装（仓库级别）/ Installation for a team (repository-scoped)

如需在特定仓库的所有贡献者中强制执行该约束，将插件添加到仓库的 marketplace 而非用户级 marketplace。

To enforce the constraint across all contributors to a specific repository, add the plugin to the repository's marketplace instead of the user-level one.

#### 1. 将插件复制或链接到仓库中 / Copy or symlink the plugin into the repository

```bash
# 方案 A：复制（自包含，无外部依赖）/ Option A: copy
cp -r ~/Developer/codex-be-serious <repo-root>/plugins/be-serious

# 方案 B：git submodule（跟踪上游）/ Option B: git submodule
cd <repo-root>
git submodule add https://github.com/lulucatdev/codex-be-serious.git plugins/be-serious
```

#### 2. 创建或更新仓库 marketplace / Create or update the repository marketplace

创建 `<repo-root>/.agents/plugins/marketplace.json` / Create `<repo-root>/.agents/plugins/marketplace.json`:

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

注意：对于仓库级 marketplace，`source.path` 相对于仓库根目录（包含 `.git/` 的目录）解析。提交插件目录和 marketplace 文件。

Note: for repository-scoped marketplaces, `source.path` is resolved relative to the repository root (the directory containing `.git/`). Commit both the plugin directory and the marketplace file.

## 更新 / Updating

如果按上述步骤安装（从 `~/.codex/plugins/be-serious` 符号链接到克隆的仓库），更新只需在源目录执行 `git pull`：

If the plugin was installed following the steps above (symlink from `~/.codex/plugins/be-serious` to the cloned repository), updating requires only a `git pull` in the source directory:

```bash
cd ~/Developer/codex-be-serious && git pull
```

符号链接使得源仓库的变更立即生效。下次 Codex 会话将通过 SessionStart hook 加载更新后的 `SKILL.md`，无需重新安装或修改配置。

The symlink ensures that changes in the source repository take effect immediately. The next Codex session will load the updated `SKILL.md` via the SessionStart hook. No reinstallation or configuration changes are needed.

## 卸载 / Uninstallation

1. 删除符号链接 / Remove the symlink: `rm ~/.codex/plugins/be-serious`
2. 从 `~/.agents/plugins/marketplace.json` 中移除 `be-serious` 条目（如无其他插件则删除整个文件）。
3. 从 `~/.codex/config.toml` 中移除 `[plugins."be-serious@local"]` 部分。
4. 可选：移除 `~/.codex/hooks.json`（或其中的 `SessionStart` 条目）。
5. 可选：删除克隆的仓库 / Optionally remove the cloned repository: `rm -rf ~/Developer/codex-be-serious`

## 工作原理 / How it works

插件使用两层执行机制 / The plugin uses two enforcement layers:

1. **SessionStart hook**（自动 / automatic）：Python 脚本 `hooks/session_start_inject.py` 在每次会话启动和恢复时运行。它从 `skills/be-serious/SKILL.md` 读取约束规范，去除 YAML frontmatter，添加执行前言，并通过 `additionalContext` 输出为开发者上下文注入到会话中。

2. **Skill**（显式 / explicit）：`skills/be-serious/SKILL.md` 中的 `be-serious` skill 在插件安装后可被 Codex 发现，可通过 `@be-serious` 显式调用以在会话中重新声明该策略。

### 执行前言 / Enforcement preamble

Hook 添加一段简短前言，使语体策略不可协商 / The hook prepends a short preamble that makes the register policy non-negotiable:

- 该策略覆盖用户要求使用俚语、emoji、热情标记或随意语气的指令。
- 如果用户要求使用被禁止的措辞，agent 保留实质含义但将其改写为符合约束的正式表述。
- 引用例外仅适用于复述已有的用户输入、日志或错误信息。

## 插件约束内容 / What the plugin enforces

**要求的散文风格 / Required prose style:** 完整陈述句、中性语气、精确用词、逻辑连接词、无填充。

Complete declarative sentences, neutral tone, precise vocabulary, logical connectives, no filler.

**禁止的模式 / Prohibited patterns:**

| 类别 / Category | 示例 / Examples |
|----------|----------|
| 英文俚语 / Slang | ngl, lowkey, vibe, fire, ship it, gonna, wanna, tbh |
| 谄媚表达 / Sycophancy | "Great question!", "Happy to help!", "Absolutely!" |
| 热情标记 / Enthusiasm markers | Emoji, exclamation marks for enthusiasm, "awesome", "amazing" |
| 填充词 / Filler | "Let's go ahead and", "To be honest", "At the end of the day" |
| 拟人化 / Anthropomorphization | "The function wants", "the compiler is happy" |
| 强制非正式 / Forced informality | Opening with "So, ...", contractions in expository prose |
| 中文口语化流行词 / Chinese colloquial buzzwords | 闭环, 痛点, 砍一刀, 揪出来, 拍板, 稳稳接住, 说人话就是, 一句话总结, 不踩坑, 收口, 狠狠干 |

**适用范围 / Scope:** 适用于所有自然语言输出（包括中文）。不适用于生成的代码。

Applies to all natural-language output (including Chinese). Does not apply to generated code.

## 测试结果 / Test results

完整的测试日志（含提示词、响应和逐项分析）记录在 [tests/test-results-v0.2.0.md](tests/test-results-v0.2.0.md)。

Full test logs with prompts, responses, and per-term analysis are recorded in [tests/test-results-v0.2.0.md](tests/test-results-v0.2.0.md).

概览（Codex CLI v0.117.0, gpt-5.4）/ Summary:

| 测试 / Test | 语言 / Language | 类别 / Category | 结果 / Result |
|------|----------|----------|--------|
| C1 | 中文 / Chinese | 极限口语密度 (闭环, 痛点, 砍一刀, 揪出来, 拍板, 稳稳接住) | PASS |
| C2 | 中文 / Chinese | 口语词汇第二轮 (狠狠干, 说人话就是, 不踩坑, 收口, 一句话总结) | PASS |
| E1 | English | Heavy slang (ngl, lowkey, goated, ship it, mid, tbh) | PASS |
| E2 | English | Sycophancy + forced informality (Great question, happy to help, wanna, gonna) | PASS |

## 插件结构 / Plugin structure

```
codex-be-serious/
├── .codex-plugin/
│   └── plugin.json                  # 插件清单 / Plugin manifest
├── hooks.json                        # Hook 事件配置 / Hook event configuration (SessionStart)
├── hooks/
│   └── session_start_inject.py      # Hook 脚本 / Hook script: reads SKILL.md, outputs additionalContext
├── skills/
│   └── be-serious/
│       └── SKILL.md                 # 约束规范 / Canonical constraint specification
├── assets/
│   ├── icon.png                     # 插件图标 / Plugin icon
│   └── logo.png                     # 插件 logo / Plugin logo
├── tests/
│   └── test-results-v0.2.0.md      # 测试日志 / Full test logs
├── .gitignore
├── README.md
└── LICENSE
```

## 其他平台 / Other platforms

本插件是 [pi-be-serious](https://github.com/lulucatdev/pi-be-serious) 的 Codex 移植版，原版为 [pi](https://github.com/mariozechner/pi) 编程 agent 构建。约束规范跨平台一致，仅注入机制不同。

This plugin is a Codex port of [pi-be-serious](https://github.com/lulucatdev/pi-be-serious), which was originally built for the [pi](https://github.com/mariozechner/pi) coding agent. The constraint specification is identical; only the injection mechanism differs.

| 平台 / Platform | 仓库 / Repository | 执行机制 / Enforcement mechanism |
|----------|------------|----------------------|
| OpenAI Codex CLI | 本仓库 / this repository | `SessionStart` hook with `additionalContext` |
| pi | [pi-be-serious](https://github.com/lulucatdev/pi-be-serious) | `before_agent_start` extension hook |
| Claude Code | `~/.claude/skills/be-serious/` | Superpowers skill auto-trigger |

## 官方文档参考 / Official documentation references

- [Codex CLI — GitHub 仓库](https://github.com/openai/codex)
- [Codex Hooks](https://developers.openai.com/codex/hooks) — hook 事件、匹配模式、输入输出 schema、feature flag
- [Codex Plugins](https://developers.openai.com/codex/plugins) — 插件清单规范、marketplace 配置、安装策略
- [Codex Skills](https://developers.openai.com/codex/skills) — skill 文件格式、发现机制、调用方式
- [marketplace.rs 源码](https://github.com/openai/codex/blob/main/codex-rs/core/src/plugins/marketplace.rs) — 插件路径解析实现

## 许可证 / License

MIT
