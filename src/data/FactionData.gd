class_name FactionData
extends Resource

# 流派类型：鲜血/知识/心脏
enum FactionType { BLOOD, KNOWLEDGE, HEART }

@export var faction_type: FactionType
@export var display_name: String
@export var display_name_en: String
@export var core_description: String
@export var san_relationship: String
@export var typical_build: String
@export var risk: String
@export var min_formed_san: int
@export var max_formed_san: int
@export var mutation_ids: Array[String]  # 专属变异
@export var recommended_sets: Array[String]  # 推荐套装
