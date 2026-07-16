extends Node

var _run_count: int = 0
var _unlocked_item_ids: Array[String] = []
var _unlocked_part_ids: Array[String] = []
var _unlocked_mutation_ids: Array[String] = []
var _unlocked_set_ids: Array[String] = []
var _inherited_san_cap_loss: float = 0.0
var _inherited_madness_rate: float = 0.0
var _tindalos_marked: bool = false
var _unlocked_endings: Array[String] = []
var _bestiary: Array[String] = []  # 遇遇过的敌人/BOSS

func _ready() -> void:
    EventBus.boss_defeated.connect(_on_boss_defeated)
    EventBus.player_died.connect(_on_player_died)

func start_new_run() -> void:
    _run_count += 1
    _inherited_madness_rate = _run_count * 0.05
    SANManager.reset_for_new_run(_inherited_san_cap_loss)
    SANManager.inherited_madness_rate = _inherited_madness_rate
    if _tindalos_marked:
        SANManager.mark_tindalos()
    EventBus.roguelike_reset_started.emit()
    # 重置各系统
    InventoryManager.reset_for_new_run()
    BodyPartManager.reset_for_new_run()
    BuildManager.reset_for_new_run()
    LevelManager.reset_for_new_run()
    MutationManager.reset_for_new_run()
    MadnessManager.reset_for_new_run()
    EventBus.roguelike_reset_completed.emit()

func unlock_item(item_id: String) -> void:
    if item_id not in _unlocked_item_ids:
        _unlocked_item_ids.append(item_id)
        EventBus.meta_progress_updated.emit("item_unlocked", item_id)

func unlock_part(part_id: String) -> void:
    if part_id not in _unlocked_part_ids:
        _unlocked_part_ids.append(part_id)
        EventBus.meta_progress_updated.emit("part_unlocked", part_id)

func unlock_mutation(mutation_id: String) -> void:
    if mutation_id not in _unlocked_mutation_ids:
        _unlocked_mutation_ids.append(mutation_id)

func unlock_set(set_id: String) -> void:
    if set_id not in _unlocked_set_ids:
        _unlocked_set_ids.append(set_id)

func unlock_ending(ending_id: String) -> void:
    if ending_id not in _unlocked_endings:
        _unlocked_endings.append(ending_id)
        EventBus.meta_progress_updated.emit("ending_unlocked", ending_id)

func add_to_bestiary(enemy_id: String) -> void:
    if enemy_id not in _bestiary:
        _bestiary.append(enemy_id)

func get_run_count() -> int:
    return _run_count

func get_inherited_madness_rate() -> float:
    return _inherited_madness_rate

func is_item_unlocked(item_id: String) -> bool:
    return item_id in _unlocked_item_ids

func is_part_unlocked(part_id: String) -> bool:
    return part_id in _unlocked_part_ids

func _on_boss_defeated(boss_id: String) -> void:
    add_to_bestiary(boss_id)

func _on_player_died(cause: String) -> void:
    _inherited_san_cap_loss = SANManager.san_cap_loss
    EventBus.roguelike_reset_started.emit()
