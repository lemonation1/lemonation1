class_name EnemyData
extends Resource

# 敌人分类：眷族/独立种族/造物种族/其他
enum Category { SERVANT_RACE, INDEPENDENT_RACE, CREATED_RACE, OTHER }
# 战斗定位：普通/精英/小BOSS/BOSS
enum CombatRole { NORMAL, ELITE, MINI_BOSS, BOSS }

@export var id: String
@export var display_name: String
@export var category: Category
@export var serves_deity: String  # 侍奉神祇
@export var description: String
@export var habitat: String
@export var combat_role: CombatRole = CombatRole.NORMAL
@export var base_hp: int = 50
@export var base_damage: int = 10
@export var base_speed: float = 100.0
@export var abilities: Array[String]
@export var special_mechanics: Array[String]
@export var san_loss_on_sight_first: String  # "1d6"
@export var san_loss_on_sight_repeat: String  # "0/1"
@export var is_servant_race: bool = false  # 是否眷族（受旧印影响）
@export var weakness: String  # 弱点（如"electric"）
@export var drop_table: Dictionary  # {"green": [...], "blue": [...]}
