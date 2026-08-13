# Pi Codex 通道

从 Codex Desktop 把边界明确的任务委派给指定模型的 Pi 命名通道，session 可持久保留、可续接、可交接。

[English](README.md) · 简体中文

## 解决什么问题

Codex 原生子代理是临时的：每次派生都从零开始，把指定任务路由到指定外部模型也需要额外配置。本技能给每个（Codex 任务 × 模型角色）组合一个**命名且持久的 Pi session**，跨调用保留历史，因此可以：

- 把边界明确的任务发给指定模型，结果直接回到 Codex。
- 稍后在同一 session 中带着完整上下文继续追问。
- 模型出错时由另一个模型接管同一份历史继续。
- 新开 Codex 任务时，从旧任务 fork 通道而不是搬移。

## 快速开始

```bash
git clone https://github.com/roanpy/pi-codex-channels pi-codex-channels
cd pi-codex-channels

# 把通道映射到你本机 Pi 已配置的模型：
cp scripts/channels.conf.example scripts/channels.conf
chmod 600 scripts/channels.conf
# 编辑 scripts/channels.conf；用 `pi models` 查看本机可用模型

# 在 Codex Desktop 终端中：
./scripts/pi-codex-channel glm52 "支付模块" \
  --prompt "实施已确认的支付重试修复并运行相关测试；不要扩大范围。"
```

作为 Codex skill 安装：把仓库内容复制到 `~/.codex/skills/pi-codex-channels/`。

## 两种生命周期

| 模式 | 参数 | 行为 |
| --- | --- | --- |
| 一次性（默认） | `--prompt "<任务>"` | 非交互执行，输出结果后退出；session 历史保留可续接 |
| 交互式（显式启用） | `--interactive` | 在命名 tmux 会话 `pi-cdx-<线程>-<通道>` 中打开持久 TUI |

## 通道与模型

六个命名通道，内置默认值是作者自己的订阅渠道；在 `channels.conf` 中覆盖任意通道，无需改脚本。你不需要这些特定的 provider——任何你本机 Pi 认识的 `provider/model` 都可以，见 `scripts/channels.conf.example`。

## 会话交接

```bash
# 让另一个模型接管失败通道的历史：
./scripts/pi-codex-channel ds4pro "支付模块" --continue-from glm52 \
  --prompt "继续未完成部分；先核对已有改动，避免重复写入。"

# 新 Codex 任务从旧任务 fork 通道：
./scripts/pi-codex-channel glm52 "支付跟进" \
  --fork-from <旧完整线程ID> glm52 \
  --prompt "审查上一轮遗留的跟进项。"
```

## 安全特性

- 每 session 原子锁，拒绝两个写者同时写一个会话文件。
- 一次性任务不会打到正在运行的交互 tmux 通道上。
- 删除只进 macOS 废纸篓、必须显式 `--yes`、相关进程存活时拒绝执行。
- session 目录与运行时标记均为 `700`/`600`。
- 任何位置都不放 API key：模型通过 Pi 自己的本地 provider 配置解析。

## 会话管理

```bash
./scripts/pi-codex-sessions list
./scripts/pi-codex-sessions delete <完整Codex线程ID> --yes
```

## 依赖

- macOS，本机已安装 Pi（`pi` coding agent CLI）且在 `PATH` 上。
- Codex Desktop，命令须在其集成终端中运行（启动器要求 `CODEX_THREAD_ID`）。
- `--interactive` 通道需要 `tmux`；`pi-codex-sessions list` 需要 `jq`。

## 许可证

[MIT](LICENSE)
