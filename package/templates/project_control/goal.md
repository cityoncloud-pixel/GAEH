# goal.md (Owner-owned)

> 说明：这是 GAEH 的“最高优先级输入”。如果你不确定怎么写，先运行 GGS（`project_control/.ggs/templates/runner.prompt.md`）让系统帮你生成/补全。

## 1) Intent / 原始意图
（你为什么要做这个？要解决什么问题？一句话即可）

## 2) Target Outcome / 目标交付物
（最终要交付什么：功能/代码/文档/可运行程序/可演示页面？尽量具体到“有哪些文件/模块/入口”。）

## 3) Success Criteria / 成功标准（可验证）
（至少 3 条；至少 1 条可以用命令或明确行为验证，例如：`npm test` / `pytest` / “打开页面能完成 X”。）

## 4) Scope / 范围
### In Scope
- 

### Out of Scope
- 

## 5) Constraints / 约束
（技术栈、平台、性能、兼容性、风格、时间/成本限制；不确定可写 UNKNOWN，后续由 GGS 记录假设。）

## 6) Inputs / 输入材料与上下文
（已有仓库/现有系统/参考资料/设计稿/接口文档/数据来源；从零开始也要说明。）

## 7) UI / Interaction Requirements（如涉及 UI）
（你希望用户怎么操作？关键交互流程是什么？有哪些页面/对话框/表单/快捷键等？不确定可写 UNKNOWN。）

## 8) Boundary & Edge Cases / 边界与模糊点（重要）
（任何可能引发歧义的边界：角色权限、数据边界、异常流程、兼容性、业务规则冲突等；不确定可写 UNKNOWN。）

## 9) Output Format / 输出格式
（GAEH 最终应该产出什么：哪些文件/目录、可运行命令、可演示路径、发布物等。）

## 10) Risks / 风险与未知
（至少 1 条不确定/决策点；没有也写“无明显风险”并解释。）

## 11) Approval Policy / 同意门禁（Owner 决策）
当目标清晰后，AI 必须先征得你同意再开始连续实现。你可以：
- 在对话里回复：`APPROVE`（或 `APPROVE <task_id>`）
- 或更新：`project_control/approval.json`

