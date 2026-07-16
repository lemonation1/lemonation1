class_name LevelData
extends Resource

# 推荐流派
enum RecommendedFaction { BLOOD, KNOWLEDGE, HEART, ALL }

@export var chapter_id: String  # "C1" ~ "C8"
@export var level_name: String
@export var story_source: String  # 原著篇目
@export var core_deities: Array[String]
@export var area_boss: String
@export var hidden_bosses: Array[String]
@export var unlock_ability: String
@export var pollution_multiplier: float = 1.0
@export var recommended_faction: RecommendedFaction = RecommendedFaction.ALL
@export var sub_levels: Array[Dictionary]  # [{"id":"C1-1","scene":"","boss":"","mechanic":""}]
@export var key_mechanics: Array[String]
@export var green_drops: Array[String]
@export var blue_drops: Array[String]
@export var purple_drops: Array[String]
@export var orange_drops: Array[String]
@export var red_drops: Array[String]
@export var has_multiple_endings: bool = false
@export var endings: Array[String]
