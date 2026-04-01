# Drift Survivors — 技术架构文档

## 1. 项目概况

**类型：** Brotato 风格的俯视角生存游戏，玩家操控漂移赛车，武器自动射击
**引擎：** Godot 4.6.1 (GDScript)
**渲染器：** GL Compatibility（兼容移动端/Web）
**测试框架：** GUT 9.6.0
**平台集成：** GodotSteam GDExtension (Steam 成就 + 云存档)
**本地化：** 5 语言 (en, zh_CN, es, ja, ko)

---

## 2. 目录结构

```
g3/
├── addons/gut/              # GUT 测试框架
├── assets/                  # 媒体资源
│   ├── audio/              # 音乐与音效
│   ├── fonts/              # 自定义字体
│   └── sprites/            # 图片资源
├── data/                    # JSON 数据配置
│   ├── cars.json           # 4 辆车的属性定义
│   ├── weapons.json        # 6+ 种武器（每种 4 阶）
│   ├── enemies.json        # 7+ 种敌人（含精英/Boss）
│   ├── upgrades.json       # 15+ 个升级选项
│   ├── items.json          # 商店道具
│   ├── waves.json          # 20 波次配置 + 难度曲线
│   └── translations.csv    # 多语言翻译表
├── docs/                    # 文档
├── scenes/                  # .tscn 场景文件
│   ├── game/               # game_arena.tscn, hud.tscn
│   └── ui/                 # 所有 UI 场景
├── src/                     # 全部 GDScript 逻辑
│   ├── autoload/           # 8 个全局单例
│   ├── car/                # 车辆控制系统
│   ├── core/               # 通用基类（状态机、对象池）
│   ├── economy/            # 经济与商店
│   ├── enemies/            # 敌人行为与生成
│   ├── game/               # 竞技场协调器
│   ├── loot/               # 掉落物系统
│   ├── stats/              # 属性与升级
│   ├── ui/                 # UI 控制器
│   ├── waves/              # 波次管理
│   └── weapons/            # 武器系统
├── test/unit/               # 单元测试
└── project.godot            # 引擎配置
```

---

## 3. Autoload 单例（启动顺序）

| 顺序 | 单例 | 路径 | 职责 |
|------|------|------|------|
| 1 | **EventBus** | autoload/event_bus.gd | 全局信号中枢，49 个信号，模块间零耦合通信 |
| 2 | **DataLoader** | autoload/data_loader.gd | 启动时加载所有 JSON，提供类型化访问器 |
| 3 | **GameManager** | autoload/game_manager.gd | 顶层游戏状态机，管理场景切换 |
| 4 | **AudioManager** | autoload/audio_manager.gd | 集中化 SFX/BGM 播放 |
| 5 | **SteamManager** | autoload/steam_manager.gd | Steam SDK 封装（离线兼容） |
| 6 | **SaveManager** | autoload/save_manager.gd | 持久化存档（Steam Cloud 回退到本地） |
| 7 | **InputSetup** | autoload/input_setup.gd | 运行时注册手柄输入映射 |
| 8 | **LocaleManager** | autoload/locale_manager.gd | 语言切换，CSV 翻译加载 |

**依赖关系图：**
```
EventBus ← 所有模块都依赖
DataLoader ← GameManager, 所有游戏系统
SteamManager ← SaveManager
```

---

## 4. 游戏状态机 (GameManager)

```
┌──────┐   start_new_run    ┌────────────┐   select_car    ┌───────────────┐
│ MENU │ ─────────────────→ │ CAR_SELECT │ ──────────────→ │ WEAPON_SELECT │
└──────┘                    └────────────┘                 └───────┬───────┘
                                                                  │ select_weapon
                                                                  ▼
                                              ┌─────────────────────────┐
                                              │        PLAYING          │
                                              │  (波次循环: 1 → 20)      │
                                              └─────┬───────────┬───────┘
                                                    │           │
                                          wave_end  │           │ car_died
                                          (非最终波) │           │
                                                    ▼           ▼
                                              ┌──────────┐ ┌───────────┐
                                              │   SHOP   │ │ GAME_OVER │
                                              └────┬─────┘ └───────────┘
                                                   │ close_shop
                                                   ▼
                                              PLAYING (下一波)
                                                   │
                                          wave 20 completed
                                                   ▼
                                              ┌─────────┐
                                              │ VICTORY │
                                              └─────────┘

  PLAYING ⇄ PAUSED (pause/resume)
  PLAYING → LEVEL_UP → PLAYING (升级时暂停)
```

---

## 5. 核心系统详解

### 5.1 竞技场协调器 (GameArena)

`src/game/game_arena.gd` — 继承 Node3D，是游戏运行时的中枢。

**职责：**
- 实例化并连接所有游戏子系统
- 创建 3D 环境（灯光、地面、雾效）
- 处理波次间的过渡逻辑（商店开关、车辆重生）

**实例化的子系统：**
```
GameArena (Node3D)
├── WorldEnvironment          # 环境光、雾效、Glow
├── DirectionalLight3D × 3    # 主光 / 填充光 / 边缘光
├── Ground (MeshInstance3D)    # 150×150 沥青地面
├── CarController              # 玩家车辆
│   ├── DriftStateMachine
│   ├── NitroSystem
│   └── WeaponMountManager
│       └── WeaponMount × N
├── EnemySpawner               # 敌人工厂
├── WaveManager                # 波次计时与调度
├── LootSpawner                # 掉落物生成
├── LevelUpManager             # 经验与升级
├── EconomyManager             # 材料货币
├── PlayerStats                # 属性聚合
├── Inventory                  # 道具背包
├── ShopManager                # 商店生成
├── CameraController           # 3D 相机
├── HUD (CanvasLayer)          # 游戏 HUD
├── ShopScreenUI               # 商店界面
├── LevelUpUI                  # 升级界面
└── PauseMenuUI                # 暂停菜单
```

**灯光参数：**
| 光源 | 颜色 | 能量 | 角度 | 阴影 |
|------|------|------|------|------|
| 主光 (日落暖色) | (1.0, 0.92, 0.85) | 0.9 | (-55, -35, 0) | 有 |
| 填充光 (冷蓝) | (0.6, 0.75, 1.0) | 0.35 | (-25, 120, 0) | 无 |
| 边缘光 (紫色底光) | (0.8, 0.6, 1.0) | 0.15 | (60, 0, 0) | 无 |

**环境设置：**
- 背景色: 近黑 (0.01, 0.01, 0.04)
- 环境光: 深空色 (0.2, 0.25, 0.35)，能量 0.4
- 雾: 密度 0.003，黑色
- Glow: 强度 0.6，bloom 0.15

---

### 5.2 车辆系统 (Car)

#### CarController (`src/car/car_controller.gd`)
继承 `CharacterBody3D`，核心物理循环。

**操控模型：** 绝对方向控制（WASD = 世界方向，非车头相对）

**物理循环 `_physics_process(delta)`：**
```
1. 读取输入 → 计算目标角度 (visual_angle)
2. 根据 grip 参数将 velocity 方向向 visual_angle 插值
   - grip_normal = 0.15 (正常抓地)
   - grip_drift = 0.02 (漂移时极低抓地 → 滑行感)
3. 漂移充能: angle_diff(速度方向, 车头方向) × 速度 → 充能值
4. 碰撞处理: move_and_slide()
```

**关键机制：**
| 机制 | 说明 |
|------|------|
| 漂移 | 按住漂移键降低 grip，车辆侧滑，充能条逐渐填满 |
| 氮气加速 | 松开漂移键时若充能≥50%，触发加速冲刺 |
| 受伤/击退 | `take_damage(amount, knockback, source_pos)` 施加反方向速度 |

#### DriftStateMachine (`src/car/drift_state_machine.gd`)
```
NONE → CHARGING_1 (0.5s) → CHARGING_2 (1.5s) → READY (2.5s)
```
每个阶段的氮气倍率: 0 / 1.0x / 1.5x / 2.5x

#### NitroSystem (`src/car/nitro_system.gd`)
- 漂移中积累氮气: `angle_diff × speed × stage_multiplier`
- 松漂移时激活: 持续消耗氮气，提供高速加速
- 信号: `nitro_changed`, `boost_started`, `boost_ended`

#### CarStats (`src/car/car_stats.gd`)
Resource 类，从 `cars.json` 加载。示例（Rookie Racer）：
```
max_hp: 100, regen: 1.0, armor: 0
max_speed: 28, boost_speed: 45, base_accel: 35
grip_normal: 0.15, grip_drift: 0.02
charge_rate: 50, max_charge: 100
nitro_max: 100, drain_rate: 25
weapon_slots: 4
```

---

### 5.3 武器系统 (Weapons)

#### WeaponBase (`src/weapons/weapon_base.gd`)
继承 Node3D，自动朝最近敌人射击。

**射击循环：**
```
_physics_process(delta):
  cooldown -= delta
  if cooldown <= 0:
    target = TargetingSystem.find_nearest_enemy(position, range, tree)
    if target:
      fire(direction_to_target)
      cooldown = 1.0 / fire_rate
```

**武器类型：**
| 武器 | 类型 | 特色 |
|------|------|------|
| Pistol | 远程 | 单发，平衡 |
| Shotgun | 远程 | 多弹丸，扇形扩散，击退 |
| SMG | 远程 | 极高射速，低伤害 |
| Sniper | 远程 | 慢速，高伤害，穿透 |
| Bumper | 近战 | 范围伤害，无弹道 |
| Laser | 远程 | 元素伤害 |

每种武器 **4 个等阶（Tier 1-4）**，属性逐阶提升。

#### 武器合并 (WeaponFactory)
```
条件: 同 ID + 同 Tier + Tier < 最大阶
合并: 移除两把旧武器 → 生成 Tier+1 新武器
```

#### WeaponMountManager (`src/car/weapon_mount_manager.gd`)
管理车身上最多 8 个武器槽位。`try_auto_merge()` 在商店关闭后自动合并同类武器。

#### TargetingSystem (`src/weapons/targeting_system.gd`)
静态工具类，通过 `"enemies"` 场景组查询最近/范围内敌人。

---

### 5.4 敌人系统 (Enemies)

#### EnemyBase (`src/enemies/enemy_base.gd`)
继承 `CharacterBody3D`。

**行为循环：**
```
_physics_process(delta):
  direction = (player.position - position).normalized()
  velocity = direction * speed
  move_and_slide()
  # 碰撞检测: 接触玩家 → 造成伤害
```

**敌人类别：**
| 类型 | 代表 | 特点 |
|------|------|------|
| regular | Crawler, Dasher, Spitter | 基础追击型 |
| elite | Brute | 血厚、带光环效果 |
| boss | Overlord | 高血量、大体型 |

#### 难度缩放 (EnemyData)
```gdscript
# 每波的属性 = 基础值 × 倍率^(波数-1)
scaled_hp = base_hp × hp_multiplier^(wave - 1)
scaled_speed = base_speed × speed_multiplier^(wave - 1)
scaled_damage = base_damage × damage_multiplier^(wave - 1)
```

#### EnemySpawner (`src/enemies/enemy_spawner.gd`)
- 在玩家周围 50 单位处随机角度生成
- 限定在竞技场 150×150 边界内
- 每波最大敌人数可配置

---

### 5.5 波次系统 (Waves)

#### WaveManager (`src/waves/wave_manager.gd`)

**每波数据（来自 waves.json）：**
```json
{
  "wave": 1,
  "duration_seconds": 20,
  "spawn_rate": 1.5,
  "max_enemies": 8,
  "elite_chance": 0.0,
  "has_boss": false,
  "enemy_types": ["enemy_basic"]
}
```

**运行流程：**
```
start_wave(n):
  time_remaining = duration
  is_active = true

_physics_process(delta):
  time_remaining -= delta
  spawn_timer -= delta
  if spawn_timer <= 0:
    pick random enemy_type (考虑 elite_chance)
    spawner.spawn_enemy(enemy_data)
    spawn_timer = 1.0 / spawn_rate
  if time_remaining <= 0:
    if has_boss: spawn boss
    emit wave_completed
```

**20 波流程：** 波 1-19 结束进商店 → 波 20 通关 → VICTORY

#### WaveDifficulty (`src/waves/wave_difficulty.gd`)
静态分析函数：
- `get_rarity_weights(wave)`: 返回商店稀有度概率（随波次提升）
- `get_wave_hp_pool(wave)`: 计算波次总血量（用于平衡）

---

### 5.6 掉落与经济 (Loot & Economy)

#### LootSpawner → LootDrop
```
敌人死亡 → enemy_killed 信号 → LootSpawner.spawn_drop()
  → 创建 LootDrop (Area3D, 发光水晶)
  → 随机散射 + 浮动旋转
  → 玩家接近 → 磁吸拉向玩家 → 收集 → 加材料 + 经验
```
活跃掉落上限 50，超出时合并到最近掉落。

#### EconomyManager
```gdscript
add_materials(amount)     # 收集材料
spend_materials(amount)   # 商店购买
can_afford(amount) → bool # 余额检查
```

#### ShopManager (波次间商店)
```
生成算法:
  1. WaveDifficulty.get_rarity_weights(wave) → 稀有度权重
  2. 抽取 4 个随机道具 (受 luck 修正)
  3. 定价: base_price × 1.08^(wave-1)
  4. 刷新费: base_cost + increment × reroll_count
```

---

### 5.7 属性系统 (Stats)

#### PlayerStats (`src/stats/player_stats.gd`)
```
final_stat = base_stat + Σ(FLAT modifiers) × Π(1 + PERCENT modifiers)
```

**数据流：**
```
CarStats (基础)     ┐
道具 stat_modifiers  ├→ PlayerStats.recalculate() → final_stats
升级 stat_modifiers  ┘
                          ↓
                    stat_changed 信号 → 同步到 CarController
```

#### StatModifier (`src/stats/stat_modifier.gd`)
```gdscript
{
  stat_name: "max_speed",
  mod_type: FLAT | PERCENT,
  value: 5.0,
  source: "item_speed_boost"
}
```

#### LevelUpManager (`src/stats/level_up_manager.gd`)
```
升级所需经验 = 10 × 1.15^level (指数增长)
升级时:
  1. 随机生成 3 个升级选项
  2. 玩家选择 1 个
  3. 应用 stat_modifiers 到 PlayerStats
  4. 额外 +1 max_hp (Brotato 风格)
```

---

## 6. 信号架构 (EventBus)

EventBus 是所有模块间通信的唯一通道。核心信号分类：

### 游戏流程
```
game_state_changed(old_state, new_state)
wave_started(wave_num)
wave_ended(wave_num)
wave_timer_tick(seconds_remaining)
```

### 战斗
```
car_damaged(amount, source)
car_died
enemy_spawned(enemy)
enemy_killed(enemy, position, value)
weapon_fired(weapon_id)
weapon_merged(weapon_id, new_tier)
weapon_equipped(slot, weapon_id)
```

### 经济/进度
```
material_collected(amount)
material_changed(total)
xp_gained(amount)
level_up(new_level)
upgrade_chosen(upgrade_id)
item_purchased(item_id)
shop_opened / shop_closed
stat_changed(name, old_value, new_value)
```

### 车辆状态
```
drift_stage_changed(stage: 0-3)
nitro_activated / nitro_depleted
nitro_gauge_changed(ratio: 0.0-1.0)
boost_started / boost_ended
```

**信号流示意：**
```
                    ┌──── AudioManager (播放音效)
enemy_killed ──────├──── LootSpawner (生成掉落)
                    ├──── WaveManager (更新敌人计数)
                    └──── HUD (击杀反馈)

                    ┌──── NitroSystem (充能)
drift_stage_changed├──── HUD (漂移阶段指示)
                    └──── AudioManager (漂移音效)
```

---

## 7. 数据驱动设计

所有游戏内容都在 `data/*.json` 中定义，代码中不硬编码数值：

```
DataLoader (启动时加载)
├── cars: Dictionary        ← cars.json
├── weapons: Dictionary     ← weapons.json
├── enemies: Dictionary     ← enemies.json
├── upgrades: Array         ← upgrades.json
├── items: Array            ← items.json
├── waves: Dictionary       ← waves.json
└── translations: CSV       ← translations.csv (由 Godot 自动加载)
```

**扩展新内容只需编辑 JSON，无需改代码：**
- 新车: 在 cars.json 添加条目
- 新武器: 在 weapons.json 添加条目 + 4 个 tier
- 新敌人: 在 enemies.json 添加条目 + 缩放参数
- 新升级: 在 upgrades.json 添加条目 + stat_modifiers

---

## 8. 物理层配置

| 层 | 名称 | 碰撞对象 |
|----|------|---------|
| 1 | car | 与 enemies(2), arena_boundary(5) 碰撞 |
| 2 | enemies | 与 car(1), projectiles(3), arena_boundary(5) 碰撞 |
| 3 | projectiles | 与 enemies(2) 碰撞 |
| 4 | loot | 与 car(1) 碰撞（拾取检测） |
| 5 | arena_boundary | 与 car(1), enemies(2) 碰撞 |
| 6 | hitbox | 伤害施加区域 |
| 7 | hurtbox | 伤害接收区域 |

---

## 9. 设计模式总结

| 模式 | 应用位置 | 说明 |
|------|---------|------|
| **信号总线** | EventBus | 模块间零耦合，通过信号通信 |
| **状态机** | GameManager, DriftStateMachine | 通用 StateMachine + State 基类 |
| **工厂模式** | WeaponFactory, EnemySpawner | 从数据创建实例 |
| **对象池** | ObjectPool | 复用高频实例（弹丸、敌人） |
| **组件组合** | CarController | 通过挂载子节点扩展功能 |
| **数据驱动** | DataLoader + JSON | 内容与逻辑分离 |
| **资源模式** | CarStats, WeaponData, EnemyData | 利用 Godot Resource 做类型化数据容器 |
| **修饰器聚合** | PlayerStats + StatModifier | FLAT/PERCENT 修饰器链式计算最终属性 |

---

## 10. 类层次结构

```
Autoload (全局单例)
├── EventBus
├── DataLoader
├── GameManager
├── AudioManager
├── SteamManager
├── SaveManager
├── InputSetup
└── LocaleManager

Node3D (3D 游戏对象)
├── GameArena                    # 场景协调器
├── CarController (CharacterBody3D)
│   ├── DriftStateMachine (Node)
│   ├── NitroSystem (Node)
│   └── WeaponMountManager (Node3D)
│       └── WeaponMount (Node3D)
│           └── WeaponBase (Node3D)
├── EnemyBase (CharacterBody3D)  # 敌人
├── LootDrop (Area3D)            # 掉落物
└── CameraController (Camera3D)  # 相机

Control (UI 节点)
├── MainMenuUI
├── CarSelectUI
├── WeaponSelectUI
├── ShopScreenUI
├── LevelUpUI
├── PauseMenuUI
├── GameOverUI
├── VictoryUI
├── SettingsUI
├── EpilepsyWarningUI
└── Item3DPreview (SubViewportContainer)

RefCounted (纯逻辑/工具类)
├── ShopManager
├── WeaponFactory
├── WeaponData
├── EnemyData
├── CarStats
├── StatModifier
├── StatCalculator
├── Inventory
├── ItemRarity
├── WaveDifficulty
├── TargetingSystem
└── ObjectPool

Node (通用基类)
├── StateMachine
├── State
├── WaveManager
├── EnemySpawner
├── LootSpawner
├── LevelUpManager
├── EconomyManager
└── PlayerStats
```

---

## 11. 架构评估与重构建议

### 当前架构优势
1. **解耦良好** — EventBus 信号驱动，模块间无直接引用
2. **数据驱动** — JSON 配置与代码逻辑分离，扩展内容无需改代码
3. **组件化** — 车辆系统拆分为独立组件，职责清晰
4. **可测试** — GUT 单元测试覆盖核心逻辑

### 潜在问题与重构方向

#### P1: GameArena 职责过重 (God Object 倾向)
**现状：** `game_arena.gd` 同时负责：
- 创建 3D 环境（灯光、地面、雾效）
- 实例化所有子系统
- 处理波次过渡
- 管理粒子特效
- 处理掉落物收集
- 连接数十个信号

**建议：**
```
GameArena (只做组装和信号连接)
├── EnvironmentBuilder      ← 提取: 灯光/地面/雾效创建
├── WaveTransitionHandler   ← 提取: 波次过渡逻辑
└── VFXManager              ← 提取: poof 特效等视觉反馈
```

#### P2: 属性来源追踪困难
**现状：** `PlayerStats` 的 modifiers 数组不断追加，升级/道具效果混在一起。如果需要"移除某道具的效果"，需要遍历查找 source 字段。

**建议：** 改为分组存储:
```gdscript
var modifier_groups: Dictionary = {
  "car_base": [...],
  "item_speed_boost": [...],
  "upgrade_armor_1": [...]
}
# 移除时直接 erase key
```

#### P3: 武器视觉 (Procedural) vs 场景 (Scene) 混合
**现状：** 武器模型在 `weapon_base.gd` 中用代码程序化生成（Box + Cylinder 拼装）。随着武器类型增多，代码会越来越难维护。

**建议：** 将武器外观迁移到 .tscn 场景文件或 Resource，代码只管逻辑:
```
weapons/
├── weapon_base.gd           # 射击逻辑
├── models/
│   ├── pistol_model.tscn    # 手枪外观
│   ├── shotgun_model.tscn   # 霰弹枪外观
│   └── ...
```

#### P4: 敌人行为单一
**现状：** 所有敌人共用 `EnemyBase`，行为仅是"朝玩家直线追击"。Spitter（远程型）虽在数据中定义，但代码中并无远程射击逻辑。

**建议：** 引入行为组件或状态机:
```
EnemyBase
├── ChaserBehavior           # 追击型 (Crawler, Dasher)
├── RangedBehavior           # 远程型 (Spitter) — 保持距离 + 射击
├── ChargerBehavior          # 冲刺型 — 蓄力后冲锋
└── SwarmBehavior            # 群体型 (Buzzer) — 环绕 + 包围
```

#### P5: 对象池未被充分使用
**现状：** `ObjectPool` 类已实现，但弹丸和敌人目前直接 `new()` + `queue_free()`，未使用池化。在高密度波次（30+ 敌人 + 多武器射击）时可能产生 GC 压力。

**建议：** 为弹丸和敌人启用对象池:
```gdscript
# EnemySpawner
var enemy_pool := ObjectPool.new()
enemy_pool.setup(enemy_scene, 20, 50)

# WeaponBase
var projectile_pool := ObjectPool.new()
projectile_pool.setup(projectile_scene, 10, 30)
```

#### P6: 缺少 VFX/反馈系统
**现状：** 粒子特效直接在 `game_arena.gd` 中内联创建。伤害数字、击杀反馈等视觉效果缺失。

**建议：** 创建独立的 `VFXManager`:
```
VFXManager (Node)
├── spawn_poof(position, color)
├── spawn_damage_number(position, amount)
├── spawn_hit_flash(target)
└── spawn_death_explosion(position, size)
```

#### P7: 没有难度曲线可视化
**现状：** `waves.json` 的 20 波数据手动编写，难以直观判断难度曲线是否合理。

**建议：** 编写离线脚本或编辑器插件，绘制难度曲线:
```
wave_balance_tool.gd:
  输出每波的: 总HP、DPS、敌人密度、精英概率
  生成 CSV → 用表格工具绘图
```

### 重构优先级

| 优先级 | 项目 | 收益 | 风险 |
|--------|------|------|------|
| **高** | P4 敌人行为组件化 | 游戏体验多样性，必须在加新敌人前完成 | 低 |
| **高** | P1 GameArena 拆分 | 代码可维护性，避免文件膨胀 | 低 |
| **中** | P3 武器视觉场景化 | 美术迭代效率 | 中（需迁移现有代码） |
| **中** | P5 启用对象池 | 性能（后期波次大量敌人时） | 低 |
| **低** | P2 属性分组 | 支持道具卸载功能时再做 | 低 |
| **低** | P6 VFX 系统 | 手感提升，可渐进式添加 | 低 |
| **低** | P7 平衡工具 | 调试便利性 | 低 |
