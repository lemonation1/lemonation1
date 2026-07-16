extends Node

const DEFAULT_WEIGHTS: Dictionary = {
    1: 0.9,  # GREEN
    2: 0.6,  # BLUE
    3: 0.3,  # PURPLE
    4: 0.15, # ORANGE
    5: 0.07  # RED
}

var _pools: Dictionary = {}  # {PoolType: ItemPoolData}
var _special_count: int = 0  # 已拥有的Special道具数

func register_pool(pool_data: Resource) -> void:
    _pools[pool_data.pool_type] = pool_data

func get_pool(pool_type: int) -> Resource:
    return _pools.get(pool_type)

func roll_item(pool_type: int) -> String:
    var pool = get_pool(pool_type)
    if pool == null or pool.item_weights.is_empty():
        return ""
    if pool.depleted:
        return _roll_from_default_pool()
    var total_weight = 0.0
    var available_items: Array[Dictionary] = []
    for item_id in pool.item_weights:
        var weight = pool.item_weights[item_id]
        var item_data = InventoryManager.get_item_data(item_id)
        if item_data and not _is_special_blocked(item_data):
            available_items.append({"id": item_id, "weight": weight})
            total_weight += weight
    if available_items.is_empty() or total_weight <= 0:
        return _roll_from_default_pool()
    var roll = randf() * total_weight
    for item in available_items:
        roll -= item["weight"]
        if roll <= 0:
            if InventoryManager.get_item_data(item["id"]).is_special:
                _special_count += 1
            return item["id"]
    return available_items[0]["id"]

func _is_special_blocked(item_data: Resource) -> bool:
    if not item_data.is_special:
        return false
    # 已有越多Special，新Special出现率越低
    var block_chance = _special_count * 0.15
    return randf() < block_chance

func _roll_from_default_pool() -> String:
    # 池子枯竭时返回低阶道具
    var pool = get_pool(0)  # 默认阿卡姆池
    if pool and not pool.item_weights.is_empty():
        var keys = pool.item_weights.keys()
        return keys.pick_random()
    return ""

func remove_item_from_pool(pool_type: int, item_id: String) -> void:
    var pool = get_pool(pool_type)
    if pool:
        pool.item_weights.erase(item_id)
        if pool.item_weights.is_empty():
            pool.depleted = true

func reset_pools() -> void:
    for pool_type in _pools:
        _pools[pool_type].depleted = false
    _special_count = 0

func reset_for_new_run() -> void:
    reset_pools()
