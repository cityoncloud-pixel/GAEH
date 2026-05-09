# GAEH Package (Agent Kit)

GAEH 是一套“目标驱动的工程协作协议 + 目录骨架 + 状态文件 + 安装/校验脚本”，用于在 Codex / Cursor 里稳定推进：澄清目标 → 征得同意 → 持续实现 → 验证 → 汇报 → 迭代。

## What You Get
- 一键初始化目标项目骨架：`project_control/`、`ai_harness/`、`plans/`、`reviews/`、`reports/`、`specs/`
- 上游目标生成器（GGS）：把想法编译为高质量 `project_control/goal.md`
- 适配器：Codex skill + Cursor rule
- Doctor：安装自检
- Approval Gate：目标清晰后必须先征得 Owner 同意才开始连续实现

## Install (Optional, one-time)
在 kit 目录执行：
```powershell
powershell -ExecutionPolicy Bypass -File .\gaeh.ps1 install
```
把 shim 加到当前会话 PATH（可选）：
```powershell
$env:PATH = "$env:USERPROFILE\.gaeh\bin;$env:PATH"
```

## Init a Project (One Command)
在目标项目根目录执行（推荐安装后用 shim 跑）：
```powershell
gaeh init -Adapters codex,cursor
```
或直接在 kit 目录指定目标路径：
```powershell
powershell -ExecutionPolicy Bypass -File .\gaeh.ps1 init -TargetPath D:\path\to\your-project -Adapters codex,cursor
```

## Verify Install
```powershell
gaeh doctor -TargetPath D:\path\to\your-project
```

## Goal Generation (GGS)
1) 编辑：`project_control/.ggs/idea.md`
2) 把：`project_control/.ggs/templates/runner.prompt.md` 全文粘贴给 Codex/Cursor 执行一次

也可以让 CLI 打印入口路径：
```powershell
gaeh ggs -TargetPath D:\path\to\your-project
```

## Start Execution (Consent Gate)
把下面这句话发给 Codex/Cursor：
```text
gaeh start
```
当 AI 给出计划并准备开始实现时，你需要明确同意：
- 对话中回复：`APPROVE`（或 `APPROVE <task_id>`），或
- 运行：`gaeh approve -TargetPath <PROJECT> -Scope start_execution -Note "ok"`

