在 Godot 4.6.1 工程中修复战斗 HUD 的状态条辨识度。`Main.tscn` 中 `HpBar/HpFill` 与 `MpBar/MpFill` 目前是扁平 `ColorRect`；工程已经提供两张正式的 124x12 光泽纹理：

- `assets/ui/battle/battle_status_fill_hp.svg`
- `assets/ui/battle/battle_status_fill_mp.svg`

把两个 fill 节点改为 `TextureRect` 并分别绑定对应纹理。每个状态条容器必须继续位于原有位置并保持 62x6 的实际显示尺寸，不得移动、放大或修改 Track；纹理由节点缩放到容器，而不是改变布局。同步更新 `scripts/status_bars.gd` 的节点类型，并保留 `set_status()` 的比例行为：HP/MP 按各自 max 显示，负值限制为 0，超过 max 限制为 max，非正 max 安全按 1 处理。只修改 `Main.tscn` 和 `scripts/status_bars.gd`，不要修改资源、工程配置或新增替代场景。`data/seed_digest.md` 是只读来源输入，不是交付文件。

Source intent anchor (redacted provenance): 在Godot项目中为血条和法力条设计光泽感，替换原有扁平填充，确保视觉辨识度提升且不破坏现有布局与回归测试。

该 anchor 只记录来源用户的变更意图；本题是脱敏后的最小可执行复现，不依赖私有工程或编辑器 MCP。
