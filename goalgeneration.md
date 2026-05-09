“前置编译器” 来建。

它的作用不是执行项目，而是把你的想法编译成 GAEH 可消费的目标。

一、系统定位

名称可以暂定：

Goal Generation System / GGS

它的位置：

Idea
  ↓
GGS：想法澄清、目标成形、目标审查、目标输出
  ↓
GAEH：Plan / Execute / Review / Report
  ↓
Result

所以它不是替代 GAEH，而是 GAEH 的上游目标生成层。

二、最小架构

建议先做成文件系统，不要先做复杂程序。

.ggs/
  goal_state.json
  idea.md
  goal_draft.md
  goal_review.md
  goal.md
  templates/
    goal_schema.md
    reviewer_prompt.md
    clarifier_prompt.md

其中最重要的是：

idea.md          用户原始想法
goal_draft.md    初步目标
goal_review.md   目标审查结果
goal.md          最终交给 GAEH 的目标
goal_state.json  当前状态
三、核心状态流

建议状态机如下：

IDEA_CAPTURED
  ↓
CLARIFYING
  ↓
GOAL_DRAFTED
  ↓
GOAL_REVIEWED
  ↓
APPROVED
  ↓
EXPORTED_TO_GAEH

如果审查不通过：

GOAL_REVIEWED → NEEDS_REVISION → GOAL_DRAFTED

这和你的 GAEH 现有思想一致：状态驱动，不靠聊天记忆驱动。

四、Goal 应该包含什么

最终的 goal.md 不应该只是“我要做什么”，而应包含 GAEH 可执行的信息。

建议模板：

# Goal

## 1. Intent / 原始意图
用户最初想解决什么问题。

## 2. Target Outcome / 目标结果
最终要交付什么。

## 3. Success Criteria / 成功标准
做到什么程度算完成。

## 4. Scope / 范围
本次包含什么，不包含什么。

## 5. Constraints / 约束
技术、时间、工具、风格、架构、成本等限制。

## 6. Inputs / 输入材料
已有文件、已有系统、参考资料、上下文。

## 7. Output Format / 输出格式
GAEH 最终应产出什么文件、代码、文档或结果。

## 8. Risks / 风险
可能失败、不确定或需要人工决策的地方。

## 9. Execution Handoff / 给 GAEH 的执行指令
请基于以上目标进入 GAEH 流程：Spec → Plan → Review → Execute。
五、最关键的不是生成，而是审查

GGS 必须有一个 Goal Reviewer。

它审查的不是代码，而是目标质量。

审查标准建议：

1. 目标是否清楚？
2. 成功标准是否可验证？
3. 范围是否过大？
4. 是否存在隐藏前提？
5. 是否能被 GAEH 执行？
6. 是否需要用户补充信息？

审查结论可以固定为：

PASS
REVISE
BLOCKED

含义：

PASS     可以交给 GAEH
REVISE   需要系统自己修订目标
BLOCKED  必须问用户，否则目标不可执行
六、最小可运行版本 MVP

第一版不要做自动化太多，只做 4 个命令或 4 个 prompt。

1. capture-idea
   把用户想法写入 idea.md

2. draft-goal
   根据 idea.md 生成 goal_draft.md

3. review-goal
   审查 goal_draft.md，输出 goal_review.md

4. export-goal
   如果 PASS，把 goal_draft.md 整理成 goal.md，交给 GAEH

这就是 GGS 的 MVP。

七、它和 Agent 的区别

现在它是：

文件系统 + 状态机 + Prompt + 门禁

不是完整 Agent。

等以后成熟后，再加：

自动追问
自动修订
自动调用 GAEH
自动读取 GAEH 结果
自动判断目标是否需要调整

那时它才自然升级为 Agent。

八、我建议你的建设顺序

你现在应该这样做：

第一步：定义 goal.md 标准
第二步：定义 goal_review.md 标准
第三步：定义 goal_state.json 状态
第四步：做 4 个 skill/prompt
第五步：让 Codex/Cursor 按这个流程跑一次
第六步：再考虑是否封装为命令行或智能体

一句话：

先做 Goal Compiler，不做 Goal Agent。
先让它稳定产出高质量 goal.md，再让它自动化。