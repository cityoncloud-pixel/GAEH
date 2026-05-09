# Command List (GAEH + GGS)

> 约定：
> - “PowerShell 命令”在系统终端执行（Windows）。
> - “Codex/Cursor 指令”在 Codex 或 Cursor 的对话输入框执行（一次一条）。

---

## A)（推荐）GitHub Release 安装（适合换机器/异地）

### A1) 打包（在本仓库执行）
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```
输出在 `dist/`，例如：`gaeh-kit-v0.3.zip`

### A2) 发布到 GitHub（你操作）
- 创建私有仓库（例如：`GAEH`）
- 创建 Release（tag 建议：`v0.3`）
- 上传 `dist/gaeh-kit-v0.3.zip` 作为 Release 资产

### A3) 新机器安装（仅需一个脚本）
把本仓库里的 `install-gaeh.ps1` 拷到新机器任意目录后执行：
```powershell
powershell -ExecutionPolicy Bypass -File .\install-gaeh.ps1 -RepoOwner <OWNER> -RepoName <REPO> -Tag v0.3 -Token <PAT> -InstallShim -AddToPathCurrentSession
```

> 说明：
> - 私有仓库通常需要 `-Token <PAT>`（Personal Access Token，建议只给 read 权限）。
> - `-InstallShim` 会安装到 `~/.gaeh`，以后命令更短。

---

## B)（推荐）全局安装 GAEH Kit（一次性）

在 `<KIT>` 目录执行（`<KIT>` 是解压后的 kit 目录，里面应有 `gaeh.ps1`）：
```powershell
powershell -ExecutionPolicy Bypass -File .\gaeh.ps1 install
```

把 shim 加到当前会话 PATH（可选）：
```powershell
$env:PATH = "$env:USERPROFILE\.gaeh\bin;$env:PATH"
```

验证 shim 是否可用：
```powershell
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\.gaeh\bin\gaeh.ps1 doctor -TargetPath .
```

---

## C) 初始化新项目（GAEH 骨架 + 适配器 + GGS）

### C1) 用 kit 目录直接初始化（不要求全局安装）
```powershell
powershell -ExecutionPolicy Bypass -File .\gaeh.ps1 init -TargetPath <PROJECT> -Adapters codex,cursor
```

### C2) 用全局 shim 初始化（推荐）
```powershell
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\.gaeh\bin\gaeh.ps1 init -TargetPath <PROJECT> -Adapters codex,cursor
```

---

## D) 安装/结构校验（Doctor）
```powershell
powershell -ExecutionPolicy Bypass -File $env:USERPROFILE\.gaeh\bin\gaeh.ps1 doctor -TargetPath <PROJECT>
```

（不使用全局 shim 时）
```powershell
powershell -ExecutionPolicy Bypass -File <KIT>\gaeh-doctor.ps1 -TargetPath <PROJECT>
```

---

## E) GGS：一条指令跑到底（目标生成）

### E1) 先写想法（文件输入）
编辑并填写：
- `<PROJECT>\project_control\.ggs\idea.md`

### E2) Codex/Cursor Runner（单入口）
把下面这句话发给 Codex 或 Cursor（只发一次）：
> 请作为 GGS（Goal Generation System）运行，并严格按 `project_control/.ggs/templates/runner.prompt.md` 执行：只读写 prompt 指定的文件，自动完成“澄清 → 起草 → 结构化评审 → 自动修订循环 → 导出”，最终生成可供 GAEH 消费的 `project_control/goal.md`，并生成 `project_control/.ggs/goal.review.json`。

执行完成后应得到：
- `<PROJECT>\project_control\goal.md`
- `<PROJECT>\project_control\.ggs\goal.review.json`

---

## F) GAEH：从 goal 到落地实现（执行阶段）

在 Codex/Cursor 里发（推荐第一条）：
1)
> 按 GAEH 流程开始：先检查 goal 是否清晰（尤其边界与 UI 交互），再给出最小问题清单；目标清晰后必须先征得我同意（等待我回复 APPROVE）再开始连续实现到验收完成，并把过程落盘到 plans/reviews/reports 与 project_control/*.md。
2)
> 我已确认 `project_control/goal.md`，请按 GAEH 进行路由、拆任务、实现、验证与审查，并把每一步落盘到对应目录与状态文件（同时更新 task_queue/decision_log）。

