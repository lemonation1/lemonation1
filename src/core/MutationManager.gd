extends Node

var _current_mutations: Array[String] = []  # 当前关卡的变异
var _mutation_database: Dictionary = {}  # {mutation_id: MutationData}

func register_mutation_data(data: Resource) -> void:
    _mutation_database[data.id] = data

func get_mutation_data(mutation_id: String) -> Resource:
    return _mutation_database.get(mutation_id)

func select_mutation(mutation_id: String) -> void:
    if _current_mutations.size() >= 1:
        _current_mutations.clear()
    _current_mutations.append(mutation_id)
    EventBus.mutation_selected.emit(mutation_id)

func get_current_mutations() -> Array[String]:
    return _current_mutations

func get_available_mutations(faction: int) -> Array[String]:
    var result: Array[String] = []
    for id in _mutation_database:
        var data = _mutation_database[id]
        if data.faction == faction:
            result.append(id)
    return result

func clear_mutations() -> void:
    _current_mutations.clear()

func reset_for_new_run() -> void:
    _current_mutations.clear()
