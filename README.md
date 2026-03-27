# codex-be-serious

A Codex plugin that enforces formal, textbook-grade written register across all agent output. Suppresses slang, sycophancy, filler words, emoji, enthusiasm markers, marketing adjectives, forced informality, and anthropomorphization.

## Installation

### From the Codex CLI

```bash
codex install <path-to-this-plugin>
```

### Local marketplace

Add an entry to `~/.agents/plugins/marketplace.json`:

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

### Repository marketplace

Add to `<repo-root>/.agents/plugins/marketplace.json` to enforce the constraint across a team:

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

## How it works

The plugin uses two enforcement layers:

1. **SessionStart hook** (automatic): A Python script runs on every session start and resume. It reads the canonical constraint from `skills/be-serious/SKILL.md`, prepends an enforcement preamble, and injects the full policy as developer context via the `additionalContext` output field. This is the primary enforcement mechanism.

2. **Skill** (explicit): The `be-serious` skill is available for manual invocation or `@be-serious` mention when the user wants to restate the policy mid-session.

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

## Requirements

- Python 3 (for the SessionStart hook script)
- Codex CLI with `codex_hooks = true` in `config.toml`

## License

MIT
