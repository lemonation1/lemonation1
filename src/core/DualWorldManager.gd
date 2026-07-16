extends Node

enum WorldLayer { REALITY, DREAMLANDS }

var _current_layer: WorldLayer = WorldLayer.REALITY
var _dream_death_occurred: bool = false
var _can_enter_dream: bool = true

func switch_to_layer(layer: WorldLayer) -> bool:
    if layer == WorldLayer.DREAMLANDS and not _can_enter_dream:
        return false
    _current_layer = layer
    EventBus.world_switched.emit(layer)
    return true

func get_current_layer() -> WorldLayer:
    return _current_layer

func is_in_dreamlands() -> bool:
    return _current_layer == WorldLayer.DREAMLANDS

func trigger_dream_death() -> void:
    _dream_death_occurred = true
    _can_enter_dream = false
    EventBus.dream_death_occurred.emit()

func can_enter_dream() -> bool:
    return _can_enter_dream

func reset_for_new_run() -> void:
    _current_layer = WorldLayer.REALITY
    _dream_death_occurred = false
    _can_enter_dream = true
