# RadishGame 游戏开发大纲 - 工程与风险

返回：[RadishGame 游戏开发大纲](cultivation-game-outline.md)

## 7. 目录与工程建议

### 7.1 推荐目录

```text
RadishGame/
  docs/
    product/cultivation-game-outline.md
    product/worldbuilding-cultivation.md
    design/core-systems.md
    planning/development-milestones.md
    design/balance-draft.md
  client/
    godot-project/
  server/
  tools/
  assets/
    temp/
    final/
```

### 7.2 文档优先级

建议先写这几份文档：

- 世界观设定
- 核心玩法循环
- 核心系统设计
- MVP 范围说明
- 里程碑计划

## 8. 技术设计原则

### 8.1 开发原则

- 先做最小可玩，不做大而全
- 先做单机闭环，再做联网
- 优先验证玩法，不优先堆内容
- 优先跑通体验，不优先写复杂框架

### 8.2 工程原则

- 数据驱动优先
- 系统模块解耦
- 尽量避免过度抽象
- 战斗、成长、家园、任务分模块实现
- 配置与逻辑分离

### 8.3 平台原则

- 首先保证 Windows 可稳定运行
- 其次保证 Web 可打开试玩
- 最后再处理 Android 适配

## 9. 风险与应对

### 9.1 最大风险

- 目标体量过大
- 美术资源产能不足
- 联网系统复杂度失控
- 内容生产速度远慢于系统开发

### 9.2 应对策略

- 严格控制 MVP
- 不在首版做真 MMORPG
- 前期使用占位资源
- 尽量复用现成工具和资产
- 每个阶段都做可运行版本

## 10. 当前建议的下一步

### 10.1 立刻开始的工作

- 确定世界观主线和主角成长主线
- 明确首个纵向切片范围
- 建立 Godot 4 项目
- 先实现移动、战斗、掉落和存档

### 10.2 第一批文档输出建议

- `product/worldbuilding-cultivation.md`
- `product/mvp-feature-list-cultivation.md`
- `design/core-gameplay-loop-cultivation.md`
- `design/character-progression.md`
- `design/combat-system-draft.md`

---

这份大纲采用的总策略是：

**Godot 4.x + GDScript + 单机 / 弱联网起步 + 后续逐步 MMO 化。**
