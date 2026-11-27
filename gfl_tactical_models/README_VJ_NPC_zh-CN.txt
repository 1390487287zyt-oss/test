[GFL] Tactical NPC

安装

1. 安装并启用 VJ Base。
2. 退出 GMod，把旧的 gfl_tactical_models 移出 garrysmod/addons/，再把解压出来的新版 gfl_tactical_models 放入该目录。
3. 启动 GMod，在 Q 菜单的「NPC」中打开「[GFL] Tactical NPC」。

名单与行为

39 个角色各有友军和敌军两版，共 78 个 NPC 菜单条目。角色名和对应的模型路径见 README_zh-CN.txt。
KCCO - Yegor 使用定稿裸头与 KCCO 男性士兵 1 型身体。友军和敌军版的 KCCO 阵营标签分别与原班同版本一致。
友军默认携带 VJ SMG1，按 E 可让其跟随玩家。
敌军默认携带 VJ AR2，在正常 AI 设置下会把玩家当作敌人。
Yegor 两版的基础生命值为 500，自身承受的伤害减少 50%。其他单位的基础生命值为 100。VJ Base 的难度和全局血量设置可以调整实际数值。
Yegor 的主武器子弹伤害乘 2。默认难度时 SMG1 为 10／发、AR2 为 24／发，徒手近战基础伤害为 20。
Yegor 第一次看到敌人时召唤四名 KCCO 男性士兵，每名从 1～4 型中独立随机抽取，沿用 Yegor 的友军或敌军版本。成功召唤后冷却 45 秒，结束后须看到敌人才能再召唤。附近空间不足时，技能等到有足够的落脚位置再释放。

KCCO 女性士兵 1 型与 2 型的左肩佩戴医疗袖章。友军版和敌军版均可治疗受伤盟友。每次恢复最多 25 点生命值，搜索距离 600 游戏单位，治疗结束后冷却约 10～15 秒。沿用 VJ Base 的医疗兵行为，通常在脱离交战后为盟友 NPC 治疗。

两版都保留角色本来的阵营。KCCO 使用前一版 KCCO／KSSO 的标签，与旧版 Hydra、AA-02、已有 KCCO 和支持相应标签的 HECU 互相友好。
格里芬与克鲁格、Gunfox Carp、Lab Ingrid 与附件 Lua 的 CLASS_GIRLS_FRONTLINE_ELMO 友好。
The Elmo 的 18 名角色统一使用「The Elmo」菜单前缀。两版均与合集里的 G&K、Gunfox Carp、Lab Ingrid 和 GMod 自带的反抗军 NPC 友好。友军和敌军以后缀区分对玩家的关系。
The Elmo 敌军不呼叫盟友支援，The Elmo 友军不接受 VJ 的盟友支援指令，以免同阵营的敌军把友军拉入对玩家的战斗。
其他七种战术角色各有阵营。Gunfox Carp 与 Lab Ingrid 各自有独立标签，互相中立。不同阵营的友军版可以都对玩家友好，阵营之间的关系仍按各自标签处理。

NPC 使用角色模型的原男女骨骼与模型引用的动作库。Yegor 保留 KCCO 男兵的原骨架、武器挂点与动作库。VJ 根据当前模型选择可用的动作。
若生成后没有活动武器，NPC 会补发该版本的 VJ 默认武器。已经选中的有效武器会保留。
原有条目使用绿色「友」和红色「敌」标识。The Elmo 使用原模组的 Friendly / Enemy 缩略图。
The Elmo 的 18 套玩家模型和第一人称手臂沿用原登记名。更新后可在玩家模型菜单选择。
本包已包含 The Elmo 模型和材质。若同时启用原 Fire Group 模组，其原版 NPC 仍会显示在原分类。多人游戏请在服务端和客户端安装同一合包。
源资源中仍缺的材质与独立动画见 README_zh-CN.txt。Lab Ingrid 的基础动作使用模型已经引用的标准女性动作库。原模型另有一份自定义动画引用，源包未包含该文件。
