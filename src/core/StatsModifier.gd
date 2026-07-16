extends Node
## 属性修正管理器 - 集中计算变异/部件对玩家属性的影响
## 监听 mutation_selected / body_part 装备信号, 重算修正
## Player/SANManager 通过 get_*() 方法查询最终修正值

# === 修正字段 (来自变异) ===
var _mutations: Array[String] = []  # 当前生效的变异ID

# === 派生修正值 (rebuild时重算) ===
# 移动/冲刺
var move_speed_mult: float = 1.0
var dash_cd_mult: float = 1.0
# 战斗
var attack_damage_mult: float = 1.0       # 基础攻击伤害乘数
var low_hp_damage_mult: float = 1.0       # 低血量额外伤害 (狂化, 动态判定时由Player查阈值)
var low_hp_threshold_ratio: float = 0.0   # 触发低血量加成的HP比例阈值 (0=无)
var lifesteal_ratio: float = 0.0          # 攻击吸血比例
var on_kill_heal: int = 0                 # 击杀回血
var damage_reduction_mult: float = 1.0    # 受伤减免 (越小越减)
var spell_damage_mult: float = 1.0        # 法术伤害乘数
var damage_mult_vs_god: float = 1.0       # 对神祇系敌人伤害乘数
# SAN
var san_resistance_bonus: float = 0.0     # SAN抗性 (整数减伤)
var san_regen_mult: float = 1.0           # SAN恢复乘数
var san_regen_idle_mult: float = 1.0      # 静止时额外SAN恢复乘数 (冥想)
var san_insight_enabled: bool = false     # 疯狂洞察: SAN越低法术伤害越高
# 道具
var item_effect_mult: float = 1.0         # 道具效果乘数
var item_charge_bonus: int = 0            # 主动道具充能加成
var item_cd_mult: float = 1.0             # 道具CD乘数
# 双层世界
var dream_realm_cd_mult: float = 1.0      # 幻梦境切换CD乘数
# 生存
var death_save_available: bool = false    # 免死一次标记


func _ready() -> void:
	EventBus.mutation_selected.connect(_on_mutation_selected)
	EventBus.mutation_select_finished.connect(_on_mutation_finished)
	EventBus.roguelike_reset_started.connect(_on_reset)


## 变异选择完成时记录 (放弃=空串, 不变)
func _on_mutation_finished(mutation_id: String) -> void:
	if mutation_id != "" and not _mutations.has(mutation_id):
		_mutations.append(mutation_id)
		rebuild()


func _on_mutation_selected(_mutation_id: String) -> void:
	# mutation_select_finished 也会触发, 这里不重复处理
	pass


func _on_reset() -> void:
	reset()


## 重算所有修正 (变异 + 部件)
func rebuild() -> void:
	# 先重置为默认
	move_speed_mult = 1.0
	dash_cd_mult = 1.0
	attack_damage_mult = 1.0
	low_hp_damage_mult = 1.0
	low_hp_threshold_ratio = 0.0
	lifesteal_ratio = 0.0
	on_kill_heal = 0
	damage_reduction_mult = 1.0
	spell_damage_mult = 1.0
	damage_mult_vs_god = 1.0
	san_resistance_bonus = 0.0
	san_regen_mult = 1.0
	san_regen_idle_mult = 1.0
	san_insight_enabled = false
	item_effect_mult = 1.0
	item_charge_bonus = 0
	item_cd_mult = 1.0
	dream_realm_cd_mult = 1.0
	death_save_available = false

	# 应用变异修正
	for mut_id in _mutations:
		_apply_mutation(mut_id)

	# 应用部件属性加成 (来自BodyPartManager)
	var part_bonuses = BodyPartManager.get_stat_bonuses()
	if part_bonuses.has("attack"):
		attack_damage_mult += float(part_bonuses["attack"]) / 100.0
	if part_bonuses.has("defense"):
		damage_reduction_mult *= maxf(0.1, 1.0 - float(part_bonuses["defense"]) / 100.0)
	if part_bonuses.has("move_speed"):
		move_speed_mult += float(part_bonuses["move_speed"]) / 100.0
	if part_bonuses.has("spell_damage"):
		spell_damage_mult += float(part_bonuses["spell_damage"]) / 100.0


## 单个变异修正映射
func _apply_mutation(mut_id: String) -> void:
	match mut_id:
		# 血脉
		"blood_thirst":
			on_kill_heal += 2
		"iron_flesh":
			damage_reduction_mult *= 0.85  # 减伤15%
		"berserk":
			low_hp_damage_mult *= 1.5
			low_hp_threshold_ratio = 0.3
		"lifesteal_aura":
			lifesteal_ratio += 0.05
		"adrenaline":
			move_speed_mult *= 1.15
			dash_cd_mult *= 0.8
		# 知识
		"arcane_mind":
			spell_damage_mult *= 1.2
		"san_insight":
			san_insight_enabled = true
		"forbidden_knowledge":
			item_effect_mult *= 1.25
		"mana_surge":
			item_charge_bonus += 1
			item_cd_mult *= 0.8
		"dreamwalker":
			dream_realm_cd_mult *= 0.5
		# 守心
		"iron_will":
			san_resistance_bonus += 15.0
		"calm_mind":
			san_regen_mult *= 1.5
		"meditation":
			san_regen_idle_mult *= 3.0
		"holy_ward":
			death_save_available = true
		"banish_evil":
			damage_mult_vs_god *= 1.3


## 消耗免死标记 (Player致命伤害时调用)
func consume_death_save() -> bool:
	if death_save_available:
		death_save_available = false
		return true
	return false


## 获取疯狂洞察的动态法术伤害加成 (SAN越低越高)
func get_san_insight_spell_bonus(current_san: float, san_max: float) -> float:
	if not san_insight_enabled:
		return 1.0
	var san_lost = maxf(0.0, san_max - current_san)
	# 每损失10SAN +5%
	return 1.0 + (san_lost / 10.0) * 0.05


func reset() -> void:
	_mutations.clear()
	rebuild()
