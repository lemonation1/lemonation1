extends Node

var _active_madness: Array[String] = []
var _madness_database: Dictionary = {}  # {madness_id: MadnessData}

func register_madness_data(data: Resource) -> void:
    _madness_database[data.id] = data

func get_madness_data(madness_id: String) -> Resource:
    return _madness_database.get(madness_id)

func trigger_random_madness(loss_amount: float, source: String) -> void:
    var candidates: Array[String] = []
    for id in _madness_database:
        var data = _madness_database[id]
        if loss_amount >= data.trigger_threshold:
            candidates.append(id)
    if candidates.is_empty():
        return
    var chosen = candidates.pick_random()
    trigger_madness(chosen)

func trigger_madness(madness_id: String) -> void:
    if madness_id not in _active_madness:
        _active_madness.append(madness_id)
        EventBus.madness_triggered.emit(madness_id)

func cure_madness(madness_id: String) -> void:
    _active_madness.erase(madness_id)

func cure_all_madness() -> void:
    _active_madness.clear()

func get_active_madness() -> Array[String]:
    return _active_madness

func has_madness(madness_id: String) -> bool:
    return madness_id in _active_madness

func reset_for_new_run() -> void:
    _active_madness.clear()
