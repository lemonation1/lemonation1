class_name BodyPartData
extends Resource

# 身体部件槽位
enum SlotType { HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG, BACK, FLESH_GROWTH }
# 部件稀有度
enum Rarity { GREEN = 1, BLUE = 2, PURPLE = 3, ORANGE = 4, RED = 5 }
# 所属流派
enum Faction { BLOOD, KNOWLEDGE, HEART, DUAL, COLORLESS }

@export var id: String
@export var display_name: String
@export var deity_source: String  # 来源神祇
@export var slot: SlotType
@export var rarity: Rarity = Rarity.GREEN
@export var faction: Faction = Faction.COLORLESS
@export var description: String
@export var stat_bonuses: Dictionary  # {"attack": 10, "defense": 5, ...}
@export var san_pollution_per_min: float = 0.0  # 持续SAN污染/分钟
@export var unlock_ability: String  # 解锁能力（如"water_breathing"）
@export var unlock_terrain: String  # 开启地形
@export var visual_effect: String  # 视觉畸变特效
@export var upgrade_level: int = 0
@export var max_upgrade: int = 5
@export var set_id: String
