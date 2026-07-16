class_name GameConstants
extends RefCounted
## 游戏全局常量

# SAN 系统
const SAN_BASE_MAX: float = 100.0
const SAN_MIN_MAX: float = 30.0
const SAN_REGEN_BASE: float = 1.0
const SAN_REGEN_SAFE_ZONE: float = 5.0
const SAN_LOW_THRESHOLD: float = 30.0
const SAN_LOW_DRAIN: float = 0.5
const SAN_INHERIT_RATIO: float = 0.5

# SAN 阶段阈值
const SAN_STAGE_SOBER: float = 70.0
const SAN_STAGE_UNEASY: float = 40.0
const SAN_STAGE_MAD: float = 15.0
const SAN_STAGE_COLLAPSE: float = 1.0

# 部件系统
const BODY_PART_MAX_SLOTS: int = 11
const BODY_PART_OVERLOAD_SAN_MULTIPLIER: float = 2.0

# 道具系统
const INVENTORY_INITIAL_ACTIVE_SLOTS: int = 3
const INVENTORY_MAX_ACTIVE_SLOTS: int = 6

# 稀有度权重
const RARITY_WEIGHTS: Dictionary = {
	1: 0.9,  # GREEN
	2: 0.6,  # BLUE
	3: 0.3,  # PURPLE
	4: 0.15, # ORANGE
	5: 0.07  # RED
}

# 区域污染倍率
const POLLUTION_MULTIPLIERS: Dictionary = {
	"C1": 1.0,
	"C2": 2.3,
	"C3": 1.5,
	"C4": 1.8,
	"C5": 2.0,
	"C6": 2.5,
	"C7": 2.7,
	"C8": 3.0,
	"HIDDEN": 5.0
}

# 流派名称
const FACTION_NAMES: Array[String] = ["血脉", "知识", "守心"]

# 疯狂继承
const MADNESS_INHERIT_PER_RUN: float = 0.05

# 碰撞层
const COLLISION_LAYER_PLAYER: int = 1
const COLLISION_LAYER_ENEMY: int = 2
const COLLISION_LAYER_PLAYER_ATTACK: int = 4
const COLLISION_LAYER_TERRAIN: int = 8
const COLLISION_LAYER_INTERACTABLE: int = 16
const COLLISION_LAYER_ITEM: int = 32

# 组名
const GROUP_ENEMIES: String = "enemies"
const GROUP_ITEMS: String = "items"
const GROUP_INTERACTABLE: String = "interactable"
const GROUP_SAFE_ZONE: String = "safe_zone"
const GROUP_BOSS: String = "boss"
