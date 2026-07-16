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
const PLAYER_FAST_FALL_SPEED: float = 760.0  # 长按下时加速下落
const PLAYER_FAST_FALL_THRESHOLD: float = 80.0  # 超过此下落速度进入快落

# 冲刺
const PLAYER_DASH_SPEED: float = 620.0
const PLAYER_DASH_DURATION: float = 0.16
const PLAYER_DASH_COOLDOWN: float = 0.45
const PLAYER_DASH_END_SPEED: float = 300.0
const PLAYER_DASH_END_LIFT: float = -60.0  # 冲刺结束给一点上抬，防止直接栽下去
const PLAYER_DASH_GHOST_INTERVAL: float = 0.02  # 残影生成间隔
const PLAYER_DASH_GHOST_LIFETIME: float = 0.35  # 残影存活时间

# 攻击
const PLAYER_ATTACK_DURATION: float = 0.18
const PLAYER_ATTACK_COMBO_WINDOW: float = 0.32
const PLAYER_ATTACK_MAX_COMBO: int = 3
const PLAYER_HIT_STOP_DURATION: float = 0.06
const PLAYER_ATTACK_KNOCKBACK: float = 200.0
const PLAYER_ATTACK_CANCEL_WINDOW: float = 0.08  # 攻击启动后可被冲刺取消的窗口（取消链）

# 输入缓冲（统一缓冲队列 - 跳跃/冲刺/攻击均可预输入）
const PLAYER_BUFFER_JUMP: float = 0.15
const PLAYER_BUFFER_DASH: float = 0.18
const PLAYER_BUFFER_ATTACK: float = 0.14

# 转身
const PLAYER_TURN_SPEED: float = 22.0  # 转身时的速度衰减插值

# Squash & Stretch
const PLAYER_SQUASH_LERP: float = 15.0
const PLAYER_SQUASH_JUMP: Vector2 = Vector2(0.82, 1.22)
const PLAYER_SQUASH_LAND: Vector2 = Vector2(1.22, 0.82)
const PLAYER_SQUASH_DASH: Vector2 = Vector2(1.3, 0.7)
const PLAYER_SQUASH_TURN: Vector2 = Vector2(1.15, 0.85)

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

# === 阴郁唯美色彩主题 (参考丝之歌: 暗沉但不刺眼, 压抑感内化) ===
# 背景 — 更深沉的去饱和暗色, 像被雾气笼罩的废墟
const THEME_BG_DEEP: Color = Color(0.06, 0.07, 0.11, 1.0)
const THEME_BG_MID: Color = Color(0.09, 0.10, 0.16, 1.0)
const THEME_BG_LIGHT: Color = Color(0.13, 0.15, 0.22, 1.0)

# 面板 — 低调暗色, 不抢画面注意力
const THEME_PANEL_BG: Color = Color(0.08, 0.09, 0.14, 0.94)
const THEME_PANEL_BORDER: Color = Color(0.24, 0.27, 0.38, 1.0)
const THEME_PANEL_HOVER: Color = Color(0.14, 0.16, 0.24, 0.96)

# 强调色 — 去饱和, 像褪色的旧物而非鲜艳的霓虹
const THEME_ACCENT_GOLD: Color = Color(0.72, 0.60, 0.32, 1.0)      # 暗金, 像旧烛光
const THEME_ACCENT_CYAN: Color = Color(0.30, 0.55, 0.62, 1.0)      # 青灰, 像深海冷光
const THEME_ACCENT_CORAL: Color = Color(0.68, 0.38, 0.40, 1.0)     # 暗珊瑚, 像干涸的血
const THEME_ACCENT_PURPLE: Color = Color(0.42, 0.34, 0.55, 1.0)    # 灰紫, 像暮色
const THEME_ACCENT_GREEN: Color = Color(0.32, 0.50, 0.38, 1.0)     # 暗苔绿, 像腐殖土上的苔藓

# 文字 — 柔和的灰白, 不刺眼
const THEME_TEXT_LIGHT: Color = Color(0.82, 0.82, 0.85, 1.0)
const THEME_TEXT_DIM: Color = Color(0.50, 0.52, 0.58, 1.0)
const THEME_TEXT_ACCENT: Color = Color(0.72, 0.60, 0.32, 1.0)

# SAN 状态色 — 去饱和渐变, 从冷绿到暗红, 不用鲜艳色
const THEME_SAN_HEALTHY: Color = Color(0.35, 0.55, 0.42, 1.0)      # 苔绿
const THEME_SAN_OKAY: Color = Color(0.62, 0.56, 0.34, 1.0)         # 暗黄
const THEME_SAN_WARN: Color = Color(0.65, 0.44, 0.30, 1.0)         # 锈橙
const THEME_SAN_DANGER: Color = Color(0.60, 0.30, 0.34, 1.0)       # 暗红
const THEME_SAN_CRITICAL: Color = Color(0.45, 0.20, 0.26, 1.0)     # 深暗红

# 玩家占位色 — 冷青灰, 像雾中的孤独旅人
const THEME_PLAYER_BODY: Color = Color(0.28, 0.45, 0.52, 1.0)
const THEME_PLAYER_OUTLINE: Color = Color(0.12, 0.22, 0.28, 1.0)

# === 氛围渐变系统 (渐进式疯狂) ===
# 章节基调: 随游戏进度永久渐暗, 每章比上章更压抑
# 背景色 / 雾气浓度 / 暗影强度 / 饱和度偏移
const ATMOSPHERE_CHAPTER_TINT: Array[Dictionary] = [
	# C1: 沉郁静谧 — 冷灰蓝, 轻雾
	{"bg": Color(0.06, 0.07,0.11), "fog": 0.15, "shadow": 0.3, "sat_shift": 0.0, "hue_shift": 0.0},
	# C2: 荒凉寂寒 — 更暗, 灰青
	{"bg": Color(0.05,0.06,0.09), "fog": 0.22, "shadow": 0.4, "sat_shift": -0.05, "hue_shift": -0.02},
	# C3: 腐败腥气 — 偏绿灰, 雾更浓
	{"bg": Color(0.05,0.07,0.07), "fog": 0.30, "shadow": 0.5, "sat_shift": -0.08, "hue_shift": 0.03},
	# C4: 不安扭曲 — 暗褐红, 开始有色差
	{"bg": Color(0.07,0.05,0.06), "fog": 0.38, "shadow": 0.6, "sat_shift": -0.10, "hue_shift": -0.03},
	# C5: 幻梦侵蚀 — 灰紫, 饱和度略回升(病态)
	{"bg": Color(0.06,0.05,0.08), "fog": 0.45, "shadow": 0.7, "sat_shift": 0.05, "hue_shift": 0.05},
	# C6: 现实崩裂 — 深暗紫, 病态饱和
	{"bg": Color(0.05,0.04,0.09), "fog": 0.55, "shadow": 0.8, "sat_shift": 0.12, "hue_shift": 0.08},
	# C7: 深渊低语 — 近黑, 强扭曲
	{"bg": Color(0.03,0.03,0.07), "fog": 0.65, "shadow": 0.9, "sat_shift": 0.18, "hue_shift": 0.10},
	# C8: 终焉疯狂 — 最暗, 最大扭曲
	{"bg": Color(0.02,0.02,0.05), "fog": 0.75, "shadow": 1.0, "sat_shift": 0.25, "hue_shift": 0.15},
]

# SAN阶段实时扭曲: 叠加在章节基调之上, SAN越低扭曲越强(可恢复)
# 暗角强度 / 色差偏移 / 呼吸晃动幅度 / 画面摇晃频率
const ATMOSPHERE_SAN_DISTORTION: Array[Dictionary] = [
	# SOBER (清醒): 几乎无扭曲
	{"vignette": 0.15, "chromatic": 0.0, "sway_amp": 0.0, "sway_freq": 0.0, "flicker": 0.0},
	# UNEASY (不安): 轻微暗角加深, 偶有微晃
	{"vignette": 0.25, "chromatic": 0.3, "sway_amp": 0.5, "sway_freq": 0.3, "flicker": 0.0},
	# MAD (疯狂): 明显色差, 呼吸式晃动, 偶有闪烁
	{"vignette": 0.40, "chromatic": 1.0, "sway_amp": 1.5, "sway_freq": 0.8, "flicker": 0.15},
	# COLLAPSE (崩溃): 强色差, 持续晃动, 频繁闪烁
	{"vignette": 0.55, "chromatic": 2.0, "sway_amp": 3.0, "sway_freq": 1.5, "flicker": 0.35},
	# ZERO (归零): 画面接近崩坏但仍可读
	{"vignette": 0.70, "chromatic": 3.5, "sway_amp": 5.0, "sway_freq": 2.5, "flicker": 0.50},
]

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

# === 敌人系统 ===
const ENEMY_GRAVITY: float = 980.0
const ENEMY_MAX_FALL_SPEED: float = 480.0
const ENEMY_FLASH_DURATION: float = 0.08  # 受击闪白时长
const ENEMY_DEATH_FADE_DURATION: float = 0.3  # 死亡淡出时长
const ENEMY_KNOCKBACK_FRICTION: float = 1200.0  # 击退减速
const ENEMY_DETECT_RANGE: float = 220.0  # 发现玩家距离
const ENEMY_ATTACK_RANGE: float = 36.0  # 攻击距离
const ENEMY_ATTACK_COOLDOWN: float = 0.8  # 攻击间隔
const ENEMY_ATTACK_WINDUP: float = 0.25  # 攻击前摇
const ENEMY_ATTACK_DURATION: float = 0.2  # 攻击持续
const ENEMY_PATROL_SPEED_MULT: float = 0.4  # 巡逻速度倍率
const ENEMY_CHASE_SPEED_MULT: float = 1.0  # 追击速度倍率
const ENEMY_SAN_DAMAGE_RANGE: float = 180.0  # 目击SAN损失生效距离
const ENEMY_DROP_PICKUP_RADIUS: float = 60.0  # 掉落物散布半径
const ENEMY_DROP_CHANCE: float = 0.35  # 基础掉落概率

# 敌人配色 (阴郁去饱和, 压抑感内化)
const THEME_ENEMY_CULTIST: Color = Color(0.40, 0.28, 0.32, 1.0)  # 邪教徒 - 暗红褐, 像干血
const THEME_ENEMY_DEEPONE: Color = Color(0.22, 0.32, 0.28, 1.0)  # 深潜者 - 灰绿, 像腐烂的海藻
const THEME_ENEMY_OUTLINE: Color = Color(0.08, 0.08, 0.12, 1.0)  # 敌人描边 - 近黑
const THEME_ENEMY_HURT: Color = Color(0.85, 0.80, 0.75, 1.0)    # 受击闪白 - 低调灰白

# === 玩家生命系统 ===
const PLAYER_MAX_HP: int = 5
const PLAYER_HURT_INVINCIBLE_TIME: float = 0.8  # 受伤无敌时间
const PLAYER_HURT_KNOCKBACK: float = 180.0

# 组名
const GROUP_ENEMIES: String = "enemies"
const GROUP_ITEMS: String = "items"
const GROUP_INTERACTABLE: String = "interactable"
const GROUP_SAFE_ZONE: String = "safe_zone"
const GROUP_BOSS: String = "boss"
