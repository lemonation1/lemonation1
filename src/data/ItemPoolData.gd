class_name ItemPoolData
extends Resource

# 道具池类型（按原著故事区域划分）
enum PoolType { ARKHAM, INNSMOUTH, DUNWICH, NKAI, MADNESS_MOUNTAINS, DREAMLANDS, RLYEH, DEVIL_ROOM, ANGEL_ROOM, CURSED_ROOM, HIDDEN_ROOM }

@export var pool_type: PoolType
@export var display_name: String
@export var area: String
@export var item_weights: Dictionary  # {"item_id": weight}
@export var depleted: bool = false
@export var special_items: Array[String]
@export var special_count_modifier: float = 1.0  # Special道具出现率修正
