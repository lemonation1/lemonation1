class_name GameConstants
extends RefCounted
## 游戏全局常量

# === 手感调优 ===
# 移动
const PLAYER_GRAVITY: float = 980.0
const PLAYER_MOVE_SPEED: float = 230.0
const PLAYER_JUMP_VELOCITY: float = -420.0
const PLAYER_ACCELERATION: float = 1800.0
const PLAYER_FRICTION: float = 2200.0
const PLAYER_AIR_ACCELERATION: float = 1400.0
const PLAYER_AIR_FRICTION: float = 800.0
const PLAYER_COYOTE_TIME: float = 0.12
const PLAYER_JUMP_BUFFER: float = 0.15
const PLAYER_JUMP_CUT_MULTIPLIER: float = 0.5
const PLAYER_DOUBLE_JUMP_MULT: float = 0.88
const PLAYER_MAX_FALL_SPEED: float = 520.0

# 冲刺
const PLAYER_DASH_SPEED: float = 620.0
const PLAYER_DASH_DURATION: float = 0.16
const PLAYER_DASH_COOLDOWN: float = 0.45
const PLAYER_DASH_END_SPEED: float = 300.0

# 攻击
const PLAYER_ATTACK_DURATION: float = 0.18
const PLAYER_ATTACK_COMBO_WINDOW: float = 0.32
const PLAYER_ATTACK_MAX_COMBO: int = 3
const PLAYER_HIT_STOP_DURATION: float = 0.06
const PLAYER_ATTACK_KNOCKBACK: float = 200.0

# Squash & Stretch
const PLAYER_SQUASH_LERP: float = 15.0
const PLAYER_SQUASH_JUMP: Vector2 = Vector2(0.82, 1.22)
const PLAYER_SQUASH_LAND: Vector2 = Vector2(1.22, 0.82)
const PLAYER_SQUASH_DASH: Vector2 = Vector2(1.3, 0.7)

# 相机
const CAMERA_SMOOTH_SPEED: float = 8.0
const CAMERA_LOOKAHEAD_MAG: float = 80.0
const CAMERA_LOOKAHEAD_LERP: float = 6.0
const CAMERA_SHAKE_MAX_OFFSET: float = 14.0
const CAMERA_SHAKE_DECAY: float = 1.5

# 屏幕震动量级
const SHAKE_LAND_LIGHT: float = 0.12
const SHAKE_LAND_HEAVY: float = 0.3
const SHAKE_ATTACK_HIT: float = 0.22
const SHAKE_DASH: float = 0.18
const SHAKE_HURT: float = 0.45

# === Q版柔和色彩主题 ===
# 背景
const THEME_BG_DEEP: Color = Color(0.10, 0.11, 0.20, 1.0)
const THEME_BG_MID: Color = Color(0.14, 0.16, 0.28, 1.0)
const THEME_BG_LIGHT: Color = Color(0.19, 0.22, 0.36, 1.0)

# 面板
const THEME_PANEL_BG: Color = Color(0.15, 0.17, 0.28, 0.92)
const THEME_PANEL_BORDER: Color = Color(0.36, 0.42, 0.62, 1.0)
const THEME_PANEL_HOVER: Color = Color(0.22, 0.26, 0.42, 0.95)

# 强调色
const THEME_ACCENT_GOLD: Color = Color(0.95, 0.78, 0.36, 1.0)
const THEME_ACCENT_CYAN: Color = Color(0.40, 0.80, 0.88, 1.0)
const THEME_ACCENT_CORAL: Color = Color(0.92, 0.50, 0.55, 1.0)
const THEME_ACCENT_PURPLE: Color = Color(0.58, 0.48, 0.82, 1.0)
const THEME_ACCENT_GREEN: Color = Color(0.45, 0.80, 0.58, 1.0)

# 文字
const THEME_TEXT_LIGHT: Color = Color(0.93, 0.93, 0.96, 1.0)
const THEME_TEXT_DIM: Color = Color(0.62, 0.65, 0.76, 1.0)
const THEME_TEXT_ACCENT: Color = Color(0.95, 0.78, 0.36, 1.0)

# SAN 状态色（柔和版）
const THEME_SAN_HEALTHY: Color = Color(0.50, 0.82, 0.62, 1.0)
const THEME_SAN_OKAY: Color = Color(0.88, 0.82, 0.42, 1.0)
const THEME_SAN_WARN: Color = Color(0.90, 0.62, 0.38, 1.0)
const THEME_SAN_DANGER: Color = Color(0.88, 0.42, 0.46, 1.0)
const THEME_SAN_CRITICAL: Color = Color(0.78, 0.32, 0.38, 1.0)

# 玩家占位色
const THEME_PLAYER_BODY: Color = Color(0.40, 0.75, 0.85, 1.0)
const THEME_PLAYER_OUTLINE: Color = Color(0.20, 0.40, 0.55, 1.0)

# === SAN 系统 ===
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

# === 部件系统 ===
const BODY_PART_MAX_SLOTS: int = 11
const BODY_PART_OVERLOAD_SAN_MULTIPLIER: float = 2.0

# === 道具系统 ===
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
