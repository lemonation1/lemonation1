extends Node

const MAX_ACTIVE_SLOTS: int = 6
const INITIAL_ACTIVE_SLOTS: int = 3

var _passive_items: Dictionary = {}  # {item_id: count}
var _active_items: Array[String] = []  # 快捷栏道具ID
var _active_slots: int = INITIAL_ACTIVE_SLOTS
var _consumables: Dictionary = {}  # {item_id: count}
var _materials: Dictionary = {}  # {item_id: count}
var _key_items: Array[String] = []
var _item_database: Dictionary = {}  # {item_id: ItemData}
var _active_set_bonuses: Dictionary = {}  # {set_id: bool}

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
            _check_set_bonus(item_id)
        1:  # ACTIVE
            if item_id not in _active_items and _active_items.size() < _active_slots:
                _active_items.append(item_id)
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
