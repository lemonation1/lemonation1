class_name ItemData
extends Resource

# 道具稀有度：绿=1, 蓝=2, 紫=3, 橙=4, 红=5
enum Rarity { GREEN = 1, BLUE = 2, PURPLE = 3, ORANGE = 4, RED = 5 }
# 道具类型：被动/主动/消耗品/材料/钥匙
enum ItemType { PASSIVE, ACTIVE, CONSUMABLE, MATERIAL, KEY }
# 道具分类（克苏鲁主题）
enum ItemCategory { FORBIDDEN_TOME, DIVINE_COUNTER, SEA_OFFERING, ALIEN_TECH, CULT_MATERIAL, FLESH_MUTATION, ANCIENT_RELIC, DREAM_ARTIFACT, CONSUMABLE, WEAPON_TOOL, AMULET_JEWELRY, SUMMON_IDOL, CARTER_SERIES, TRAPEZOHEDRON, ELDER_SIGN_STONE, SPECIAL_KEY }
# 副作用类型
enum SideEffectType { NONE, CONTINUOUS_SAN_LOSS, PERMANENT_CAP_LOSS, HALLUCINATION, LOSS_OF_CONTROL, SPATIAL_DISLOCATION, AREA_REVERSAL }
# 来源池
enum SourcePool { ARKHAM, INNSMOUTH, DUNWICH, NKAI, MADNESS_MOUNTAINS, DREAMLANDS, RLYEH, DEVIL_ROOM, ANGEL_ROOM, CURSED_ROOM, HIDDEN_ROOM, ALL_POOLS }

@export var id: String
@export var display_name: String
@export var display_name_en: String
@export var rarity: Rarity = Rarity.GREEN
@export var item_type: ItemType = ItemType.PASSIVE
@export var category: ItemCategory = ItemCategory.FORBIDDEN_TOME
@export var description: String
@export var effect_description: String
@export var side_effect_type: SideEffectType = SideEffectType.NONE
@export var side_effect_value: String
@export var source_pool: SourcePool = SourcePool.ALL_POOLS
@export var is_special: bool = false
@export var max_stack: int = 1
@export var stack_unlock_condition: String
@export var charges: int = -1  # -1=无限, >0=次数
@export var charge_type: String  # "per_level", "per_run", "recharge"
@export var set_id: String  # 套装ID
@export var faction_tags: Array[String]  # ["blood", "knowledge", "heart"]
@export var lore_text: String  # 详细介绍 (点击查看)
@export var lore_short: String  # 短评 (拾取/悬停显示, 一句话)
@export var san_cost_on_use: int = 0  # 主动使用消耗SAN
@export var permanent_san_cap_cost: int = 0  # 永久上限代价
@export var grid_size: Vector2i = Vector2i.ZERO  # 背包网格尺寸 (0,0=自动按类型/稀有度推算)
@export var needs_decoding: bool = false  # 禁忌典籍需解读后才显示真实效果 (克苏鲁主题)
@export var san_pollution_per_min: float = 0.0  # 持有SAN污染/分钟 (禁书类)


## 获取网格尺寸 (优先用显式设置, 否则按类型+稀有度推算)
func get_grid_size() -> Vector2i:
	if grid_size != Vector2i.ZERO:
		return grid_size
	# 默认推算规则: 材料/消耗品/钥匙 1x1, 被动 1x1~2x2, 主动 1x2, 禁书 2x2~2x3
	match item_type:
		ItemType.MATERIAL, ItemType.KEY:
			return Vector2i(1, 1)
		ItemType.CONSUMABLE:
			return Vector2i(1, 1)
		ItemType.ACTIVE:
			return Vector2i(1, 2)
		ItemType.PASSIVE:
			# 禁书类按稀有度变大
			if category == ItemCategory.FORBIDDEN_TOME:
				match rarity:
					Rarity.GREEN, Rarity.BLUE: return Vector2i(2, 2)
					Rarity.PURPLE: return Vector2i(2, 2)
					Rarity.ORANGE: return Vector2i(2, 3)
					Rarity.RED: return Vector2i(3, 2)
			# 武器工具类
			if category == ItemCategory.WEAPON_TOOL:
				return Vector2i(2, 2)
			# 护身符/旧印类
			if category in [ItemCategory.AMULET_JEWELRY, ItemCategory.ELDER_SIGN_STONE, ItemCategory.DIVINE_COUNTER]:
				return Vector2i(1, 1)
			# 其他被动
			return Vector2i(1, 2)
	return Vector2i(1, 1)
