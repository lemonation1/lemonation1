class_name MadnessData
extends Resource

# 疯狂症状数据（克苏鲁神话中的精神状态）

@export var id: String
@export var display_name: String
@export var buff_description: String
@export var debuff_description: String
@export var trigger_condition: String
@export var trigger_threshold: int = 5  # SAN损失阈值
@export var related_deity: String
@export var duration: String = "until_cured"  # until_cured/per_run
