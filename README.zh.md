[English](README.md) | [한국어](README.ko.md) | 中文 | [日本語](README.ja.md) | [Español](README.es.md)

# gaseo (가세요)

<p align="center">
  <img src="assets/gaseo-hero-01.png" alt="gaseo" width="320">
</p>

> **把你此刻正在聊的这个会话送进 Paseo —— 换个地方接着聊。**

[Paseo](https://paseo.app) 的列表里只有它自己启动的 agent。你在终端敲 `claude` 开的会话根本不会出现，也没有办法从 App 里恢复。`gaseo` 补上了这个缺口：说一句「가세요」，你这一秒正在进行的对话就会以原来的标题出现在 Paseo 里，可以直接接着说下去。

[快速开始](#快速开始) • [为什么用 gaseo](#为什么用-gaseo) • [工作原理](#工作原理) • [主要功能](#主要功能) • [命令](#命令) • [环境要求](#环境要求)

---

## 快速开始

### 1. 添加市场

```
/plugin marketplace add https://github.com/fivetaku/gptaku_plugins.git
```

### 2. 安装

```
/plugin install gaseo
```

### 3. 重启 Claude Code

（新命令需要重启后才会注册。）

### 4. 运行

```
/gaseo
```

就这样，你所在的会话已经进了 Paseo。打开 App 继续聊即可。

想把这个文件夹里以前的对话拿进来：

```
/gaseo past
```

直接说也行：

- 「이 세션 파세오로 가세요」
- 「가세요 해줘」
- "register this session to paseo"
- "import my past sessions into paseo"

---

## 为什么用 gaseo

**终端会话对 Paseo 是隐形的。** Paseo 只列出自己启动的 agent。你从 shell 里自己跑起来的那些 —— 也就是实际工作的大部分 —— 不在列表里，界面上连一个导入按钮都没有。

**这是链接，不是复制。** `gaseo` 调用的 `paseo import` 只写下一个指向会话 ID 的指针。对话记录仍然待在 Claude Code 放它的地方。以后就算在 Paseo 里归档这个 agent，原始对话也毫发无损。

**可以在任务中途离开工位。** 注册好会话，合上笔记本，从 Paseo App 接着做。同一段对话、同一份历史，不用重新交代来龙去脉。

**不会重复注册。** Paseo 已经认识的会话（包括它自己启动的）会被识别并跳过。

**Paseo 没见过的文件夹也没问题。** 导入时会自动创建工作区。

---

## 工作原理

```
/gaseo
  → 找到这个文件夹的会话目录
      ~/.claude/projects/<绝对路径中非字母数字字符替换为 '-'>/
  → 若 $CLAUDE_CODE_SESSION_ID 的记录在此则用它，否则用最新的 .jsonl
  → 已经在 ~/.paseo/agents 里了？→ 跳过并报告，结束
  → paseo import <会话ID> --provider claude --cwd <文件夹>
  → 以原标题出现在 Paseo 中
```

Paseo 本身不存储对话。每条 agent 记录里只有一个指向 Claude 会话 ID 的 `persistence.nativeHandle` 指针 —— 这正是导入瞬间完成、无需重启守护进程、也绝不会产生重复数据的原因。

---

## 主要功能

| 功能 | 说明 |
|------|------|
| 注册当前会话 | `/gaseo` 自动认出你正在聊的这个会话，不需要输入 ID |
| 挑选历史会话 | `/gaseo past` 列出带首条消息、时间和注册状态的清单供你选择 |
| 防重复 | 已注册的会话只报告，不会再次导入 |
| 新建工作区 | 对 Paseo 从未见过的文件夹，会连同工作区一起创建 |
| 链接而非复制 | 不移动、不修改、不复制原始对话记录 |
| 可确认的识别 | 先展示所选会话的首条消息，再往下走 |

---

## 命令

| 命令 | 说明 |
|------|------|
| `/gaseo` | 注册当前会话 |
| `/gaseo past` | 从本文件夹的历史会话中挑选并注册 |
| `/gaseo <文件夹>` | 注册另一个文件夹的当前会话 |
| `/gaseo past <文件夹>` | 挑选另一个文件夹的历史会话 |

### 自然语言触发词

- 「이 세션 파세오로 가세요」「가세요 해줘」「파세오에 등록해줘」
- 「과거 세션 파세오로 가져와줘」
- "register this session to paseo", "send this session to paseo"
- "import my past sessions into paseo"

---

## 注意事项

**如何确定当前会话。** `gaseo` 会读取 Claude Code 为活动会话导出的 `$CLAUDE_CODE_SESSION_ID`，并确认对应的对话记录确实在该文件夹里。只有在拿不到它时，才退回到「取最近写入的那份对话」——这是一种猜测，因为后台子 agent 和钩子启动的会话也会往同一目录写记录，而且往往更新。输出会标明走了哪条路径（`via=env` 或 `via=mtime`）；如果是 `via=mtime` 的猜测，请核对它一并打印的首条消息，或用 `/gaseo past` 明确挑选。

**仅支持 Claude 会话。** codex 的会话按日期而非文件夹存放，本插件所依赖的「文件夹 → 会话」映射暂时不适用。

**不会替你重启守护进程。** 如果守护进程挂了导致 `paseo import` 失败，`gaseo` 只会报告情况然后停下。重启会杀掉所有正在运行的 agent，这个决定留给你。

---

## 环境要求

- [Claude Code](https://docs.anthropic.com/claude-code) CLI
- 已安装 [Paseo](https://paseo.app)，且守护进程在运行（用 `paseo status` 确认）
- `paseo` CLI 在 `PATH` 中，或位于默认安装路径

---

## 许可证

MIT —— 参见 [LICENSE](LICENSE) 与 [DISCLAIMER.md](DISCLAIMER.md)。

---

<div align="center">

**会话没必要被困在终端里。**

</div>
