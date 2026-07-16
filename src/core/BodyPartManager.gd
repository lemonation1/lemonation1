extends Node

const MAX_SLOTS: int = 11
const SLOTS_PER_RARITY: Dictionary = {1: 0, 2: 0, 3: 1, 4: 2, 5: 3}  # 每部件占槽数

var _equipped_parts: Dictionary = {}  # {slot: BodyPartData}
var _flesh_growth_slots: int = 0  # 血肉增生额外槽
var _is_overloaded: bool = false
var _unlocked_abilities: Array[String] = []
var _part_database: Dictionary = {}  # {part_id: BodyPartData}

func _ready() -> void:
    EventBus.body_part_equipped.connect(_on_part_equipped)

func register_part_data(part_data: Resource) -> void:
    _part_database[part_data.id] = part_data

func get_part_data(part_id: String) -> Resource:
    return _part_database.get(part_id)

func equip_part(part_id: String, slot: int) -> bool:
    var data = get_part_data(part_id)
    if data == null:
        return false
    if slot < 0 or slot >= MAX_SLOTS + _flesh_growth_slots:
        return false
    if _equipped_parts.has(slot):
        unequip_part(slot)
    _equipped_parts[slot] = data
    _check_overload()
    if data.unlock_ability != "" and data.unlock_ability not in _unlocked_abilities:
        _unlocked_abilities.append(data.unlock_ability)
        EventBus.ability_unlocked.emit(data.unlock_ability)
    EventBus.body_part_equipped.emit(part_id, slot)
    return true

func unequip_part(slot: int) -> void:
    if not _equipped_parts.has(slot):
        return
    var data = _equipped_parts[slot]
    _equipped_parts.erase(slot)
    _check_overload()
    EventBus.body_part_unequipped.emit(slot)

func get_equipped_part(slot: int) -> Resource:
    return _equipped_parts.get(slot)

func get_all_equipped() -> Dictionary:
    return _equipped_parts

func get_used_slots() -> int:
    return _equipped_parts.size()

func get_max_slots() -> int:
    return MAX_SLOTS + _flesh_growth_slots

func is_overloaded() -> bool:
    return _is_overloaded

func has_ability(ability: String) -> bool:
    return ability in _unlocked_abilities

func get_all_abilities() -> Array[String]:
    return _unlocked_abilities.duplicate()

func add_flesh_growth_slots(count: int) -> void:
    _flesh_growth_slots += count

func get_stat_bonuses() -> Dictionary:
    var total = {}
    for slot in _equipped_parts:
        var data = _equipped_parts[slot]
        for stat in data.stat_bonuses:
            total[stat] = total.get(stat, 0) + data.stat_bonuses[stat]
    return total

func get_total_san_pollution_per_min() -> float:
    var total = 0.0
    for slot in _equipped_parts:
        total += _equipped_parts[slot].san_pollution_per_min
    if _is_overloaded:
        total *= 2.0
    return total

func _check_overload() -> void:
    var was_overloaded = _is_overloaded
    _is_overloaded = get_used_slots() > get_max_slots()
    if _is_overloaded != was_overloaded:
        EventBus.body_part_overloaded.emit(_is_overloaded)

func _on_part_equipped(part_id: String, slot: int) -> void:
    pass

func reset_for_new_run() -> void:
    _equipped_parts.clear()
    _flesh_growth_slots = 0
    _is_overloaded = false
    _unlocked_abilities.clear()
