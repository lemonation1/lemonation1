class_name BossData
extends Resource

# 神祇位阶：外神/旧日支配者/古神/眷族首领/化身
enum GodTier { OUTER_GOD, GREAT_OLD_ONE, ELDER_GOD, SERVANT_BOSS, AVATAR }
# 元素属性：水/风/火/地/无
enum Element { WATER, WIND, FIRE, EARTH, NONE }

@export var id: String
@export var display_name: String
@export var god_tier: GodTier
@export var element: Element = Element.NONE
@export var title: String
@export var description: String
@export var habitat: String
@export var abilities: Array[String]
@export var avatars: Array[String]  # 化身列表
@export var family: Dictionary  # 家族关系
@export var worshippers: Array[String]
@export var nemesis: String  # 宿敌
@export var level_id: String  # 所属关卡
@export var drop_parts: Array[String]  # 掉落部件ID
@export var is_scripted_death: bool = false  # 是否剧情杀
@export var combat_phases: Array[Dictionary]  # 多阶段战斗
@export var san_loss_on_encounter: String  # "1d10"
@export var permanent_san_loss: String  # "1d4"
@export var recommended_faction: String  # 推荐流派
