# 内容创作指南 — 如何新增车辆、武器、道具、升级

## 核心机制

所有内容通过 .tscn 场景文件定义，放在 `scenes/content/` 对应子目录即可。
DataLoader 启动时自动扫描目录，**零代码、零配置**。

```
scenes/content/
├── cars/          → 车辆（自动出现在选车界面）
├── weapons/       → 武器（自动出现在选武器界面 / 商店）
├── items/         → 道具（自动出现在商店）
└── upgrades/      → 升级（自动出现在升级选择）
```

---

## 方式一：在 Godot 编辑器中创建（推荐）

### 新增车辆

1. 复制一个现有车辆场景（如 `car_starter.tscn`），重命名为 `car_xxx.tscn`
2. 在编辑器中打开，根节点脚本已经是 `CarScene`
3. 在 Inspector 中修改 @export 属性：

| 属性组 | 字段 | 说明 |
|--------|------|------|
| 基本 | `id` | 唯一 ID（如 `car_xxx`），必须唯一 |
| 基本 | `car_name` | 显示名称 |
| 基本 | `unlock_condition` | 解锁条件（`none` = 默认解锁） |
| Health | `max_hp`, `hp_regen`, `armor` | 生命值、回血、护甲 |
| Movement | `max_speed`, `boost_speed`, `base_accel` | 速度、加速冲刺速度、加速度 |
| Movement | `friction`, `normal_grip`, `drift_grip` | 摩擦、正常抓地、漂移抓地 |
| Movement | `turn_speed_normal`, `turn_speed_drift` | 转向速度 |
| Drift Charge | `charge_rate`, `max_charge`, `boost_duration` | 充能速率、最大充能、加速持续 |
| Nitro | `nitro_max`, `nitro_accumulation_rate` | 氮气容量、积累速率 |
| Nitro | `nitro_drain_rate`, `nitro_damage` | 消耗速率、氮气伤害 |
| Equipment | `weapon_slots` | 武器槽位数 |

4. 在场景树中修改 3D 模型子节点（车身、车舱、车灯等）的 Mesh 和 Material
5. 保存 → 运行游戏即可在车辆选择界面看到

**车辆场景节点结构要求：**
```
CarScene (根, car_scene.gd)
├── BodyWrap (Node3D)          ← 必须叫 BodyWrap，武器挂载点在这里
│   ├── Chassis (MeshInstance3D)
│   ├── Cabin (MeshInstance3D)
│   ├── HeadlightL/R (MeshInstance3D)
│   ├── TaillightL/R (MeshInstance3D)
│   └── （可自由添加其他装饰节点）
├── WheelFL/FR/RL/RR (MeshInstance3D)  ← 必须有 WheelRL 和 WheelRR（胎印系统用）
├── BoostExhaustL/R (GPUParticles3D)   ← 必须叫这个名字（氮气喷射特效）
└── DriftSparksL/R (GPUParticles3D)    ← 必须叫这个名字（漂移火花特效）
```

### 新增武器

1. 复制现有武器场景（如 `weapon_pistol.tscn`），重命名为 `weapon_xxx.tscn`
2. 在 Inspector 中修改属性：

| 字段 | 说明 |
|------|------|
| `id` | 唯一 ID（如 `weapon_xxx`） |
| `weapon_name` | 显示名称 |
| `type` | `ranged`（远程）或 `melee`（近战） |
| `damage_type` | `ranged` / `melee` / `elemental` |
| `can_be_starting_weapon` | 是否可作为初始武器选择 |
| `tiers` | 4 阶数据数组（点击展开编辑每阶） |

3. `tiers` 数组中每个 WeaponTierData 的字段：

| 字段 | 说明 |
|------|------|
| `tier` | 阶级 (1-4) |
| `damage` | 伤害 |
| `fire_rate` | 射击间隔（秒，越小越快） |
| `weapon_range` | 射程 |
| `projectile_speed` | 弹速（近战填 0） |
| `projectile_count` | 弹丸数量 |
| `spread_angle` | 扩散角度（度） |
| `piercing` | 穿透数 |
| `knockback` | 击退力度 |

4. 修改 Model 子节点的 3D 外观
5. 保存即可

**武器场景节点结构要求：**
```
WeaponScene (根, weapon_scene.gd)
└── Model (Node3D)             ← 必须叫 Model（代码从这里提取视觉模型）
    ├── Barrel (MeshInstance3D)
    ├── Body (MeshInstance3D)
    └── （可自由添加其他节点）
```

### 新增道具

1. 复制现有道具（如 `item_armor_plate.tscn`），重命名为 `item_xxx.tscn`
2. 修改属性：

| 字段 | 说明 |
|------|------|
| `id` | 唯一 ID |
| `item_name` | 显示名称 |
| `description` | 描述文字 |
| `rarity` | `common` / `uncommon` / `rare` / `legendary` |
| `base_price` | 基础价格 |
| `max_stack` | 最大叠加数 |
| `category` | `defense` / `offense` / `speed` / `utility` / `special` |
| `stat_modifiers` | 属性修饰器数组 |

3. `stat_modifiers` 数组中每个 StatModifierData：

| 字段 | 说明 |
|------|------|
| `stat` | 属性名（见下方属性名列表） |
| `type` | `flat`（固定值加成）或 `percent`（百分比加成） |
| `value` | 数值 |

4. 修改 Model 子节点外观
5. 保存即可

### 新增升级

1. 复制现有升级（如 `upgrade_hp.tscn`），重命名为 `upgrade_xxx.tscn`
2. 修改属性：

| 字段 | 说明 |
|------|------|
| `id` | 唯一 ID |
| `upgrade_name` | 显示名称 |
| `description` | 描述文字 |
| `rarity` | `common` / `uncommon` / `rare` / `legendary` |
| `weight` | 出现权重（越高越常见） |
| `stat_modifiers` | 属性修饰器数组（同道具） |

---

## 方式二：用脚本批量生成

适合一次性创建大量内容。参考 `tools/generate_content_scenes.gd`。

基本流程：
```gdscript
var root := CarScene.new()   # 或 WeaponScene / ItemScene / UpgradeScene
root.id = "car_xxx"
root.car_name = "My Car"
# ... 设置所有 @export 属性 ...

# 添加 3D 模型子节点
var model := MeshInstance3D.new()
# ... 设置 mesh 和 material ...
root.add_child(model)

# 关键：保存前必须递归设置 owner
_set_owner_recursive(root, root)

# 保存
var scene := PackedScene.new()
scene.pack(root)
ResourceSaver.save(scene, "res://scenes/content/cars/car_xxx.tscn")
root.free()

func _set_owner_recursive(node: Node, owner_node: Node) -> void:
    for child in node.get_children():
        child.owner = owner_node
        _set_owner_recursive(child, owner_node)
```

⚠️ **必须调用 `_set_owner_recursive`**，否则子节点不会被保存到 .tscn 文件中。

---

## 可用的 stat 属性名

用于道具和升级的 `stat_modifiers`：

| 属性名 | 说明 |
|--------|------|
| `max_hp` | 最大生命值 |
| `hp_regen` | 每秒回血量 |
| `armor` | 护甲（减少受伤） |
| `max_speed` | 最大速度 |
| `boost_speed` | 加速冲刺速度 |
| `base_accel` | 加速度 |
| `nitro_max` | 氮气容量 |
| `nitro_accumulation_rate` | 氮气积累速率 |
| `nitro_drain_rate` | 氮气消耗速率 |
| `nitro_damage` | 氮气冲刺伤害 |
| `weapon_slots` | 武器槽位数 |
| `ranged_damage_mult` | 远程伤害加成 |
| `melee_damage_mult` | 近战伤害加成 |
| `all_damage_mult` | 全伤害加成 |
| `attack_speed_mult` | 攻击速度加成 |
| `life_steal` | 生命偷取比例 |
| `crit_chance` | 暴击概率 |
| `crit_damage` | 暴击伤害倍率 |
| `dodge` | 闪避概率 |
| `luck` | 幸运值（影响商店稀有度） |
| `pickup_range` | 拾取范围 |
| `shop_price_mult` | 商店价格倍率（负值=折扣） |
