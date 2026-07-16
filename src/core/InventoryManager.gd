extends Node

const MAX_ACTIVE_SLOTS: int = 6
const INITIAL_ACTIVE_SLOTS: int = 3
const GRID_WIDTH: int = 8   # 背包网格宽度
const GRID_HEIGHT: int = 6  # 背包网格高度

var _passive_items: Dictionary = {}  # {item_id: count}
var _active_items: Array[String] = []  # 快捷栏道具ID
var _active_slots: int = INITIAL_ACTIVE_SLOTS
var _consumables: Dictionary = {}  # {item_id: count}
var _materials: Dictionary = {}  # {item_id: count}
var _key_items: Array[String] = []
var _item_database: Dictionary = {}  # {item_id: ItemData}
var _active_set_bonuses: Dictionary = {}  # {set_id: bool}

# 背包网格系统 (RE4式拼图)
# _grid_occupancy: {Vector2i(网格坐标): item_id}  占用记录
# _item_positions: {item_id: {"pos": Vector2i, "rotated": bool}}  每个道具的位置和旋转
# _item_instances: {item_id: Array[单个实例UID]}  因为可能有多个同类道具
var _grid_occupancy: Dictionary = {}
var _item_positions: Dictionary = {}
var _decoded_items: Dictionary = {}  # {item_id: bool} 是否已解读 (禁忌典籍)

func _ready() -> void:
    EventBus.item_picked_up.connect(_on_item_picked_up)
    EventBus.item_removed.connect(_on_item_removed)

func register_item_data(item_data: Resource) -> void:
    _item_database[item_data.id] = item_data

func get_item_data(item_id: String) -> Resource:
    return _item_database.get(item_id)

func add_item(item_id: String, count: int = 1) -> void:
    var data = get_item_data(item_id)
    if data == null:
        return
    match data.item_type:
        0:  # PASSIVE
            _passive_items[item_id] = _passive_items.get(item_id, 0) + count
            # 自动放置到背包网格 (RE4式)
            if not _item_positions.has(item_id):
                auto_place_item(item_id)
            _check_set_bonus(item_id)
        1:  # ACTIVE
            if item_id not in _active_items and _active_items.size() < _active_slots:
                _active_items.append(item_id)
                # 主动道具也占网格
                if not _item_positions.has(item_id):
                    auto_place_item(item_id)
        2:  # CONSUMABLE
            _consumables[item_id] = _consumables.get(item_id, 0) + count
        3:  # MATERIAL
            _materials[item_id] = _materials.get(item_id, 0) + count
        4:  # KEY
            if item_id not in _key_items:
                _key_items.append(item_id)
    EventBus.item_picked_up.emit(item_id, count)

func remove_item(item_id: String, count: int = 1) -> void:
    for storage in [_passive_items, _consumables, _materials]:
        if storage.has(item_id):
            storage[item_id] -= count
            if storage[item_id] <= 0:
                storage.erase(item_id)
            EventBus.item_removed.emit(item_id, count)
            return
    EventBus.item_removed.emit(item_id, count)

func use_active_item(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= _active_items.size():
        return
    var item_id = _active_items[slot_index]
    var data = get_item_data(item_id)
    if data == null:
        return
    if data.san_cost_on_use > 0:
        SANManager.apply_temporary_loss(float(data.san_cost_on_use), "active_item:" + item_id)
    EventBus.active_item_used.emit(slot_index)
    EventBus.item_used.emit(item_id)

func use_consumable(item_id: String) -> void:
    if not _consumables.has(item_id) or _consumables[item_id] <= 0:
        return
    _consumables[item_id] -= 1
    if _consumables[item_id] <= 0:
        _consumables.erase(item_id)
    EventBus.item_used.emit(item_id)

func has_item(item_id: String) -> bool:
    return _passive_items.has(item_id) or _consumables.has(item_id) or _materials.has(item_id) or _key_items.has(item_id)

func get_item_count(item_id: String) -> int:
    var total = 0
    for storage in [_passive_items, _consumables, _materials]:
        total += storage.get(item_id, 0)
    return total

func get_all_passive_items() -> Dictionary:
    return _passive_items

func get_active_items() -> Array[String]:
    return _active_items

func upgrade_active_slots() -> void:
    _active_slots = min(MAX_ACTIVE_SLOTS, _active_slots + 1)

func _on_item_picked_up(item_id: String, count: int) -> void:
    pass

func _on_item_removed(item_id: String, count: int) -> void:
    _check_set_bonus(item_id)

func _check_set_bonus(item_id: String) -> void:
    # 检查套装联动
    pass  # 由 SetBonus 系统处理

func reset_for_new_run() -> void:
    _passive_items.clear()
    _active_items.clear()
    _active_slots = INITIAL_ACTIVE_SLOTS
    _consumables.clear()
    _materials.clear()
    _key_items.clear()
    _active_set_bonuses.clear()
    _grid_occupancy.clear()
    _item_positions.clear()
    _decoded_items.clear()


# === 背包网格系统 (RE4式拼图) ===

## 获取道具占用的网格尺寸 (考虑旋转)
func get_item_grid_size(item_id: String) -> Vector2i:
    var data = get_item_data(item_id)
    if data == null:
        return Vector2i(1, 1)
    var size = data.get_grid_size()
    if is_item_rotated(item_id):
        return Vector2i(size.y, size.x)
    return size


## 道具是否已旋转
func is_item_rotated(item_id: String) -> bool:
    if _item_positions.has(item_id):
        return _item_positions[item_id].get("rotated", false)
    return false


## 道具在网格中的位置 (左上角坐标)
func get_item_position(item_id: String) -> Vector2i:
    if _item_positions.has(item_id):
        return _item_positions[item_id].get("pos", Vector2i(-1, -1))
    return Vector2i(-1, -1)


## 获取所有已放置的道具ID (有网格位置的)
func get_placed_items() -> Array[String]:
    var result: Array[String] = []
    for item_id in _item_positions:
        result.append(item_id)
    return result


## 检查道具能否放在指定位置 (左上角坐标, 是否旋转)
func can_place_item(item_id: String, pos: Vector2i, rotated: bool) -> bool:
    if pos.x < 0 or pos.y < 0:
        return false
    var data = get_item_data(item_id)
    if data == null:
        return false
    var base_size = data.get_grid_size()
    var size = Vector2i(base_size.y, base_size.x) if rotated else base_size
    if pos.x + size.x > GRID_WIDTH or pos.y + size.y > GRID_HEIGHT:
        return false
    # 检查每个格子是否被其他道具占用
    for x in range(pos.x, pos.x + size.x):
        for y in range(pos.y, pos.y + size.y):
            var cell = Vector2i(x, y)
            if _grid_occupancy.has(cell):
                var occupier = _grid_occupancy[cell]
                if occupier != item_id:
                    return false
    return true


## 放置道具 (先清除旧占用, 再设置新占用)
func place_item(item_id: String, pos: Vector2i, rotated: bool) -> bool:
    if not can_place_item(item_id, pos, rotated):
        return false
    # 清除旧占用
    _remove_item_from_grid(item_id)
    # 设置新占用
    var data = get_item_data(item_id)
    var base_size = data.get_grid_size()
    var size = Vector2i(base_size.y, base_size.x) if rotated else base_size
    for x in range(pos.x, pos.x + size.x):
        for y in range(pos.y, pos.y + size.y):
            _grid_occupancy[Vector2i(x, y)] = item_id
    _item_positions[item_id] = {"pos": pos, "rotated": rotated}
    return true


## 自动放置道具 (找第一个能放下的位置)
func auto_place_item(item_id: String) -> bool:
    var data = get_item_data(item_id)
    if data == null:
        return false
    # 先尝试不旋转
    for y in range(GRID_HEIGHT):
        for x in range(GRID_WIDTH):
            if can_place_item(item_id, Vector2i(x, y), false):
                return place_item(item_id, Vector2i(x, y), false)
    # 再尝试旋转
    for y in range(GRID_HEIGHT):
        for x in range(GRID_WIDTH):
            if can_place_item(item_id, Vector2i(x, y), true):
                return place_item(item_id, Vector2i(x, y), true)
    return false


## 从网格移除道具
func _remove_item_from_grid(item_id: String) -> void:
    var keys_to_remove = []
    for cell in _grid_occupancy:
        if _grid_occupancy[cell] == item_id:
            keys_to_remove.append(cell)
    for key in keys_to_remove:
        _grid_occupancy.erase(key)
    _item_positions.erase(item_id)


## 从背包丢弃道具 (永久移除)
func discard_item(item_id: String) -> void:
    _remove_item_from_grid(item_id)
    _passive_items.erase(item_id)
    _consumables.erase(item_id)
    _materials.erase(item_id)
    _decoded_items.erase(item_id)
    _active_items.erase(item_id)
    EventBus.item_removed.emit(item_id, 1)


## 获取背包网格占用图 (用于UI渲染)
func get_grid_occupancy() -> Dictionary:
    return _grid_occupancy.duplicate()


## 获取网格已用格子数 / 总格子数
func get_grid_usage() -> Vector2i:
    return Vector2i(_grid_occupancy.size(), GRID_WIDTH * GRID_HEIGHT)


# === 禁忌典籍解读系统 (Tunic式) ===

## 道具是否需要解读
func item_needs_decoding(item_id: String) -> bool:
    var data = get_item_data(item_id)
    if data == null:
        return false
    return data.needs_decoding and not is_item_decoded(item_id)


## 道具是否已解读
func is_item_decoded(item_id: String) -> bool:
    return _decoded_items.get(item_id, false)


## 解读道具 (消耗SAN, 揭示真实效果)
func decode_item(item_id: String) -> bool:
    if not item_needs_decoding(item_id):
        return false
    var data = get_item_data(item_id)
    if data == null:
        return false
    # 解读消耗SAN (按稀有度递增)
    var san_cost = float(data.rarity) * 10.0
    SANManager.apply_temporary_loss(san_cost, "decode:" + item_id)
    _decoded_items[item_id] = true
    EventBus.show_notification.emit("解读完成: " + data.display_name + "\n真实效果已显现", 0)
    return true


# === SAN污染计算 ===

## 获取当前背包中所有道具的SAN污染/分钟总量
func get_total_san_pollution_per_min() -> float:
    var total = 0.0
    for item_id in _passive_items:
        var data = get_item_data(item_id)
        if data != null:
            total += data.san_pollution_per_min
    # 部件的SAN污染
    total += BodyPartManager.get_total_san_pollution_per_min()
    return total
