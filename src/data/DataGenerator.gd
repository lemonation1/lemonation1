@tool
extends EditorScript
## 数据生成器 - 生成初始的关卡、敌人、道具池 .tres 数据文件
## 在 Godot 编辑器中运行: File > Run > 选择此脚本

const ItemData = preload("res://src/data/ItemData.gd")
const EnemyData = preload("res://src/data/EnemyData.gd")
const LevelData = preload("res://src/data/LevelData.gd")
const ItemPoolData = preload("res://src/data/ItemPoolData.gd")


func _run() -> void:
	_generate_items()
	_generate_enemies()
	_generate_levels()
	_generate_item_pools()
	print("=== 数据生成完成 ===")


# ====================
# 道具数据
# ====================
func _generate_items() -> void:
	var dir_path = "res://src/data/items/"

	# --- 绿阶道具 ---
	var items = [
		# 禁忌典籍
		_create_item("necronomicon_page", "死灵之书残页", "Necronomicon Page",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.FORBIDDEN_TOME,
			"+5神话伤害，叠10张解锁召唤", "上限-1", ItemData.SideEffectType.PERMANENT_CAP_LOSS, "1",
			ItemData.SourcePool.ALL_POOLS, "", "+5 神话伤害", "古老的残页，上面的文字让人头晕目眩..."),
		_create_item("yellow_king_page", "黄衣之王残页", "Yellow King Page",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.FORBIDDEN_TOME,
			"+10%精神抗性", "临时-2/关", ItemData.SideEffectType.CONTINUOUS_SAN_LOSS, "2",
			ItemData.SourcePool.DUNWICH, "", "+10% 精神抗性", "剧本的残页上写满了疯狂的对白..."),
		_create_item("ebon_page", "伊波恩之书残页", "Eibon Page",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.FORBIDDEN_TOME,
			"+5%暗抗", "上限-1", ItemData.SideEffectType.PERMANENT_CAP_LOSS, "1",
			ItemData.SourcePool.NKAI, "", "+5% 暗抗", "魔法师伊波恩留下的禁忌知识..."),
		# 神圣反制
		_create_item("elder_sign_small", "旧印石板小", "Lesser Elder Sign",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.DIVINE_COUNTER,
			"+5 SAN抗性", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.ARKHAM, "", "+5 SAN抗性", "古老的保护符号，散发着微弱的光芒..."),
		_create_item("elder_sign_amulet", "旧印护符", "Elder Sign Amulet",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.AMULET_JEWELRY,
			"+5%抗精神", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.ANGEL_ROOM, "", "+5% 抗精神", "刻有旧印的护身符..."),
		_create_item("cross", "十字架", "Cross",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.DIVINE_COUNTER,
			"+3 SAN抗性", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.ARKHAM, "", "+3 SAN抗性", "朴素的十字架，给人一丝安宁..."),
		_create_item("holy_water_small", "圣水小", "Lesser Holy Water",
			ItemData.Rarity.GREEN, ItemData.ItemType.ACTIVE, ItemData.ItemCategory.CONSUMABLE,
			"主动1d4 SAN恢复", "1次/关", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.ANGEL_ROOM, "", "恢复 1d4 SAN", "瓶中的水散发着微弱的圣光..."),
		# 深海祭品
		_create_item("deepone_scale", "深潜者鳞片", "Deepone Scale",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.SEA_OFFERING,
			"+5水下时长", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.INNSMOUTH, "", "+5 水下时长", "灰绿色的鳞片，触感冰凉..."),
		_create_item("dagon_scale_frag", "达贡之鳞碎片", "Dagon Scale Fragment",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.SEA_OFFERING,
			"+5%水系伤害", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.INNSMOUTH, "", "+5% 水系伤害", "达贡身上的鳞片碎片..."),
		_create_item("hydra_tear", "海德拉之泪", "Hydra's Tear",
			ItemData.Rarity.GREEN, ItemData.ItemType.ACTIVE, ItemData.ItemCategory.CONSUMABLE,
			"主动1d4回血", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.INNSMOUTH, "", "恢复 1d4 HP", "一颗晶莹的泪珠..."),
		# 外星科技
		_create_item("migo_chela_frag", "米·戈螯钳碎片", "Mi-Go Chela Fragment",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.ALIEN_TECH,
			"+3%物理伤害", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.MADNESS_MOUNTAINS, "", "+3% 物理伤害", "金属质感的甲壳碎片..."),
		_create_item("migo_gun_frag", "米·戈电枪残", "Mi-Go Gun Fragment",
			ItemData.Rarity.GREEN, ItemData.ItemType.ACTIVE, ItemData.ItemCategory.ALIEN_TECH,
			"主动5-10闪电伤害", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.MADNESS_MOUNTAINS, "", "5-10 闪电伤害", "破损的异族武器..."),
		# 邪教材料
		_create_item("yellow_mark_small", "黄色印记小", "Lesser Yellow Sign",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.CULT_MATERIAL,
			"+3%精神攻击", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.DUNWICH, "", "+3% 精神攻击", "诡异的黄色符号..."),
		_create_item("cultist_charm", "邪教徒符咒", "Cultist Charm",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.CULT_MATERIAL,
			"+3%法术伤害", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.DUNWICH, "", "+3% 法术伤害", "邪教徒身上的符咒..."),
		# 血肉变异
		_create_item("flesh_growth_tissue", "血肉增生组织", "Flesh Growth Tissue",
			ItemData.Rarity.GREEN, ItemData.ItemType.PASSIVE, ItemData.ItemCategory.FLESH_MUTATION,
			"+1血肉增生槽等级", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.ALL_POOLS, "", "+1 血肉增生槽", "蠕动的肉块，散发着不祥的气息..."),
		# 占位材料
		_create_item("material_eldritch_residue", "深渊残渣", "Eldritch Residue",
			ItemData.Rarity.GREEN, ItemData.ItemType.MATERIAL, ItemData.ItemCategory.CULT_MATERIAL,
			"合成材料", "无", ItemData.SideEffectType.NONE, "",
			ItemData.SourcePool.ALL_POOLS, "", "通用合成材料", "未知的粘稠物质..."),
	]

	for item in items:
		var path = dir_path + item.id + ".tres"
		ResourceSaver.save(item, path)
		print("保存道具: " + path)


func _create_item(id: String, name_cn: String, name_en: String,
		rarity: ItemData.Rarity, type: ItemData.ItemType, category: ItemData.ItemCategory,
		effect: String, side_effect: String, se_type: ItemData.SideEffectType, se_val: String,
		source: ItemData.SourcePool, set_id: String, effect_desc: String, lore: String) -> Resource:
	var data = ItemData.new()
	data.id = id
	data.display_name = name_cn
	data.display_name_en = name_en
	data.rarity = rarity
	data.item_type = type
	data.category = category
	data.description = effect
	data.effect_description = effect_desc
	data.side_effect_type = se_type
	data.side_effect_value = se_val
	data.source_pool = source
	data.is_special = false
	data.max_stack = 1
	data.set_id = set_id
	data.lore_text = lore
	return data


# ====================
# 敌人数据
# ====================
func _generate_enemies() -> void:
	var dir_path = "res://src/data/enemies/"

	var enemies = [
		_create_enemy("cultist", "邪教徒", EnemyData.Category.SERVANT_RACE, "克苏鲁",
			"克苏鲁崇拜的凡人信徒", "全区域", EnemyData.CombatRole.NORMAL,
			50, 10, 90.0, "1d3", "0/1", false, "", {}),
		_create_enemy("deep_one", "深潜者", EnemyData.Category.SERVANT_RACE, "达贡",
			"半人半鱼的深海种族", "印斯茅斯/拉莱耶", EnemyData.CombatRole.NORMAL,
			70, 12, 70.0, "1d4", "0/1", true, "", {}),
		_create_enemy("deep_one_warrior", "深潜者战士", EnemyData.Category.SERVANT_RACE, "达贡",
			"装备精良的深潜者", "印斯茅斯/拉莱耶", EnemyData.CombatRole.ELITE,
			120, 18, 85.0, "1d6", "1/1", true, "", {}),
		_create_enemy("cultist_priest", "邪教祭司", EnemyData.Category.SERVANT_RACE, "克苏鲁",
			"主持仪式的高阶信徒", "路易斯安那沼泽", EnemyData.CombatRole.MINI_BOSS,
			200, 15, 60.0, "1d6", "1d3", false, "",
			{"green": ["cultist_charm", "yellow_mark_small"], "blue": ["yellow_king_page"]}),
		_create_enemy("shogoth_spawn", "修格斯幼体", EnemyData.Category.CREATED_RACE, "莎布·尼古拉丝",
			"可变形的黑色原生质生物", "疯狂山脉", EnemyData.CombatRole.NORMAL,
			80, 14, 50.0, "1d6", "0/1", false, "fire",
			{"green": ["flesh_growth_tissue"], "blue": []}),
	]

	for enemy in enemies:
		var path = dir_path + enemy.id + ".tres"
		ResourceSaver.save(enemy, path)
		print("保存敌人: " + path)


func _create_enemy(id: String, name_cn: String, category: EnemyData.Category,
		deity: String, desc: String, habitat: String, role: EnemyData.CombatRole,
		hp: int, dmg: int, spd: float, san_first: String, san_repeat: String,
		is_servant: bool, weakness: String, drops: Dictionary) -> Resource:
	var data = EnemyData.new()
	data.id = id
	data.display_name = name_cn
	data.category = category
	data.serves_deity = deity
	data.description = desc
	data.habitat = habitat
	data.combat_role = role
	data.base_hp = hp
	data.base_damage = dmg
	data.base_speed = spd
	data.san_loss_on_sight_first = san_first
	data.san_loss_on_sight_repeat = san_repeat
	data.is_servant_race = is_servant
	data.weakness = weakness
	data.drop_table = drops
	return data


# ====================
# 关卡数据
# ====================
func _generate_levels() -> void:
	var dir_path = "res://src/data/levels/"

	# C1: 拉莱耶终章 (克苏鲁的呼唤)
	var c1 = LevelData.new()
	c1.chapter_id = "C1"
	c1.level_name = "拉莱耶终章"
	c1.story_source = "克苏鲁的呼唤 (1928)"
	c1.core_deities = ["克苏鲁", "达贡", "海德拉"]
	c1.area_boss = "cthulhu"
	c1.hidden_bosses = []
	c1.unlock_ability = ""
	c1.pollution_multiplier = 1.0
	c1.recommended_faction = LevelData.RecommendedFaction.ALL
	c1.sub_levels = [
		{"id": "C1-1", "scene": "res://src/levels/shared/TestLevel.tscn", "boss": "", "mechanic": "教学:移动/跳跃/攻击"},
		{"id": "C1-2", "scene": "", "boss": "", "mechanic": "回忆:威尔考克斯梦境"},
		{"id": "C1-3", "scene": "", "boss": "cultist_priest", "mechanic": "战斗+潜行:沼泽邪教"},
		{"id": "C1-4", "scene": "", "boss": "", "mechanic": "登岛:水位/潮汐"},
		{"id": "C1-5", "scene": "", "boss": "", "mechanic": "迷宫:非欧几何"},
		{"id": "C1-6", "scene": "", "boss": "", "mechanic": "解谜:开门"},
		{"id": "C1-7", "scene": "", "boss": "cthulhu", "mechanic": "逃亡:克苏鲁追击"},
	]
	c1.key_mechanics = ["三段嵌套叙事", "非欧几何迷宫", "潮汐机制", "克苏鲁追击战"]
	c1.green_drops = ["necronomicon_page", "elder_sign_small", "deepone_scale"]
	c1.blue_drops = ["dagon_scale_frag"]
	c1.purple_drops = []
	c1.orange_drops = []
	c1.red_drops = []
	c1.has_multiple_endings = false
	ResourceSaver.save(c1, dir_path + "C1.tres")
	print("保存关卡: " + dir_path + "C1.tres")


# ====================
# 道具池数据
# ====================
func _generate_item_pools() -> void:
	var dir_path = "res://src/data/item_pools/"

	# 阿卡姆池 (默认池)
	var arkham = ItemPoolData.new()
	arkham.pool_type = ItemPoolData.PoolType.ARKHAM
	arkham.display_name = "阿卡姆"
	arkham.area = "阿卡姆/普罗维登斯"
	arkham.item_weights = {
		"necronomicon_page": 1.0,
		"elder_sign_small": 0.8,
		"elder_sign_amulet": 0.6,
		"cross": 0.7,
		"yellow_mark_small": 0.5,
		"cultist_charm": 0.5,
		"flesh_growth_tissue": 0.3,
		"material_eldritch_residue": 0.9,
	}
	ResourceSaver.save(arkham, dir_path + "pool_arkham.tres")
	print("保存道具池: " + dir_path + "pool_arkham.tres")

	# 印斯茅斯池
	var innsmouth = ItemPoolData.new()
	innsmouth.pool_type = ItemPoolData.PoolType.INNSMOUTH
	innsmouth.display_name = "印斯茅斯"
	innsmouth.area = "印斯茅斯/魔鬼礁"
	innsmouth.item_weights = {
		"deepone_scale": 1.0,
		"dagon_scale_frag": 0.8,
		"hydra_tear": 0.7,
		"material_eldritch_residue": 0.9,
	}
	ResourceSaver.save(innsmouth, dir_path + "pool_innsmouth.tres")
	print("保存道具池: " + dir_path + "pool_innsmouth.tres")

	# 疯狂山脉池
	var mountains = ItemPoolData.new()
	mountains.pool_type = ItemPoolData.PoolType.MADNESS_MOUNTAINS
	mountains.display_name = "疯狂山脉"
	mountains.area = "南极/古老者遗迹"
	mountains.item_weights = {
		"migo_chela_frag": 1.0,
		"migo_gun_frag": 0.7,
		"ebon_page": 0.5,
		"material_eldritch_residue": 0.9,
	}
	ResourceSaver.save(mountains, dir_path + "pool_madness_mountains.tres")
	print("保存道具池: " + dir_path + "pool_madness_mountains.tres")
