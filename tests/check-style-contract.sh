#!/bin/sh
set -eu

plugin_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

PLUGIN_ROOT=$plugin_root node <<'NODE'
const fs = require("fs");
const path = require("path");

const root = process.env.PLUGIN_ROOT;
const read = (relative) => fs.readFileSync(path.join(root, relative), "utf8");

const files = {
  skill: read("skills/be-serious/SKILL.md"),
  profile: read("skills/be-serious/style-profile.md"),
  core: read("skills/be-serious/examples.md"),
  extended: read("skills/be-serious/examples-extended.md"),
  review: read("skills/be-serious-review/SKILL.md"),
};

function requireIncludes(label, text, needles) {
  for (const needle of needles) {
    if (!text.includes(needle)) {
      throw new Error(`${label} is missing expected text: ${needle}`);
    }
  }
}

requireIncludes("style profile", files.profile, [
  "Measurable Tendencies",
  "English Lexical Preferences",
  "Chinese Lexical Preferences",
  "Register Boundaries",
]);

requireIncludes("core examples", files.core, [
  "Core calibration examples",
  "The correction is warranted.",
  "这个修正成立。",
]);

requireIncludes("extended examples", files.extended, [
  "Extended calibration examples",
  "Documentation Introduction",
  "文档导言",
]);

requireIncludes("active skill", files.skill, [
  "style-profile.md",
  "examples.md",
  "examples-extended.md",
]);

requireIncludes("review skill", files.review, [
  "../be-serious/style-profile.md",
  "../be-serious/examples.md",
  "../be-serious/examples-extended.md",
  "Assessment:",
  "Revision:",
]);

const prohibited = [
  /\bGreat question\b/i,
  /\bNice find\b/i,
  /\bHappy to help\b/i,
  /\bAbsolutely\b/i,
  /\bbasically\b/i,
  /\bship it\b/i,
  /\bawesome\b/i,
  /\bamazing\b/i,
  /\bkind of annoying\b/i,
  /\bEasy fix\b/i,
  /[🚀😊🙂😉]/u,
  /好，简单的说/,
  /痛点/,
  /闭环/,
  /揪出来/,
  /顺手/,
  /一句话总结/,
  /搞定了/,
  /要不要/,
];

const badSamples = [
  "Great question. Basically, the server is angry because the cache is stale. Easy fix.",
  "This PR is awesome. Ship it. 🚀",
  "好，简单的说，痛点就是 API 太慢了。我们先闭环一下，揪出来瓶颈。",
  "搞定了，你要不要我顺手再优化一下？",
];

const goodSamples = [
  "The server rejects the request because the cache contains stale authorization data.",
  "This change revises the dashboard data-loading path and removes two sources of inconsistent state.",
  "API 响应延迟过高。分析应从可复现的性能基线开始。",
  "实现现在会在每次成功写入后更新缓存记录，回归测试覆盖创建和更新两条路径。",
];

for (const sample of badSamples) {
  if (!prohibited.some((pattern) => pattern.test(sample))) {
    throw new Error(`bad sample did not trigger scanner: ${sample}`);
  }
}

for (const sample of goodSamples) {
  const hit = prohibited.find((pattern) => pattern.test(sample));
  if (hit) {
    throw new Error(`good sample triggered scanner ${hit}: ${sample}`);
  }
}

console.log("Style contract valid");
NODE
