class_name MutationData
extends Resource

# 变异所属流派
enum Faction { BLOOD, KNOWLEDGE, HEART }

@export var id: String
@export var display_name: String
@export var faction: Faction
@export var effect_description: String
@export var duration: String = "per_level"  # per_level/per_run/permanent
