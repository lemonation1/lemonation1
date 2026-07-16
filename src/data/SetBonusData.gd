class_name SetBonusData
extends Resource

# 套装奖励数据（集齐部件/道具触发）

@export var id: String
@export var display_name: String
@export var required_parts: Array[String]  # 所需部件/道具ID
@export var bonus_effect: String
@export var bonus_description: String
@export var applicable_factions: Array[String]
