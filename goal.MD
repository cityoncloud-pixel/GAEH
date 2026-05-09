你的思路是对的，而且结构上很清楚：

你现在其实已经拆出了两个不同层级的 Agent：

---

## 一、你现在已有的：GAEH（执行层）

它本质上是：

**Goal → Analyze → Execute → Heal**

或者按你的实际流程：

```text
Goal
 ↓
Spec
 ↓
Plan
 ↓
Review Gate
 ↓
Execute
 ↓
Debug/Fix
 ↓
State Update
 ↓
Next Task
```

它的职责是：

* 消费目标（consume goal）
* 把目标变成工程动作
* 持续推进直到完成

这属于：

**Execution Agent（执行智能体）**

不是 Goal Agent。

---

## 二、你现在缺的：Goal Generation Agent（目标生成层）

这个层级更上游。

职责不是写代码，而是：

把用户模糊意图：

> 我想做一个故事转视频软件

转成：

GAEH 可消费目标。

比如：

```yaml
goal:
  id: md-001
  type: software_project
  objective: 构建一个工业级 Story-to-Video 导演工作台
  success_criteria:
    - 支持 story → adaptation → beats → shots
    - 支持 asset management
    - 支持 storyboard generation
    - 支持 video rendering
    - 支持 timeline editing
    - 支持 voice generation
    - 支持 export
  constraints:
    - React + FastAPI
    - SQLite persistence
    - local-first
  milestones:
    - phase_1 narrative
    - phase_2 assets
    - phase_3 shots
```

这就是：

**Structured Goal Artifact**

供 GAEH 使用。

---

## 本质架构

建议你这样分：

```text
User Intent
    ↓
GGA (Goal Generation Agent)
    ↓
Goal Artifact
    ↓
GAEH (Execution Agent)
    ↓
Implementation
```

即：

双智能体架构。

而不是一个智能体。

原因：

目标生成和目标执行是不同认知模式。

---

# Goal Agent 应该做什么？

建议定义成：

---

## Layer 1：Intent Clarifier（意图澄清）

输入：

```text
我想做一个AI导演系统
```

输出：

```text
目标领域：
软件产品

核心问题：
故事结构化到视频生成

用户类型：
创作者
```

作用：

消除模糊。

---

## Layer 2：Goal Structurer（目标结构化）

把模糊目标结构化：

```yaml
goal:
  name:
  domain:
  problem:
  outcome:
  constraints:
```

作用：

形成基础目标模型。

---

## Layer 3：Feasibility Analyzer（可行性分析）

分析：

```text
是否可做？
难点是什么？
依赖是什么？
风险是什么？
```

输出：

```yaml
risks:
dependencies:
unknowns:
```

作用：

避免伪目标。

---

## Layer 4：Goal Refiner（目标精修）

把目标拆成：

```yaml
epics:
features:
phases:
```

作用：

可执行化。

---

## Layer 5：Goal Contract Generator（目标契约生成）

生成最终：

GAEH Goal Contract

例如：

```yaml
goal_contract:
  objective:
  success_criteria:
  milestones:
  acceptance:
  priority:
```

这是给 GAEH 的输入。

---

# 与 GAEH 的接口怎么定义？

接口要固定。

比如：

```text
/goals/
    active_goal.yaml
```

GAEH 只认这个。

这样：

Goal Agent 输出：

```text
active_goal.yaml
```

GAEH 消费：

```text
active_goal.yaml
```

解耦。

---

# 状态机设计（推荐）

Goal Agent 也要状态驱动：

```text
INTENT_CAPTURED
↓
INTENT_CLARIFIED
↓
GOAL_STRUCTURED
↓
FEASIBILITY_CHECKED
↓
GOAL_REFINED
↓
GOAL_CONTRACT_READY
↓
HANDOFF_TO_GAEH
```

这和你的 GAEH 风格一致。

统一哲学。

---

# 最关键的一点

Goal Agent 不应该直接生成 Spec。

Goal Agent 只生成：

**Goal Contract**

GAEH 才生成：

Spec。

边界：

```text
Goal Agent:
负责定义正确的问题

GAEH:
负责正确地解决问题
```

这是核心边界。

---

我建议下一步直接做：

**GGA v1 Spec（Goal Generation Agent Specification）**

把它正式规格化：

包括：

1. 状态机
2. 文件结构
3. goal contract schema
4. handoff protocol
5. 与 GAEH 的集成方式
6. 在 Cursor 和 OpenAI Codex CLI 中如何落地运行

这个 spec 做出来，你就有完整双层系统了：

**Goal Brain + Execution Brain**。

