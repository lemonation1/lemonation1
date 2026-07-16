extends Node

enum Faction { BLOOD, KNOWLEDGE, HEART }

var _faction_levels: Dictionary = {Faction.BLOOD: 0, Faction.KNOWLEDGE: 0, Faction.HEART: 0}
var _dominant_faction: Faction = Faction.BLOOD

func add_faction_exp(faction: Faction, amount: int) -> void:
    _faction_levels[faction] = _faction_levels.get(faction, 0) + amount
    _update_dominant()
    EventBus.faction_level_changed.emit(faction, _faction_levels[faction])

func get_faction_level(faction: Faction) -> int:
    return _faction_levels.get(faction, 0)

func get_dominant_faction() -> Faction:
    return _dominant_faction

func get_faction_multiplier(faction: Faction) -> float:
    # 每级+10%加成
    return 1.0 + get_faction_level(faction) * 0.1

func _update_dominant() -> void:
    var max_level = -1
    for f in [Faction.BLOOD, Faction.KNOWLEDGE, Faction.HEART]:
        if _faction_levels[f] > max_level:
            max_level = _faction_levels[f]
            _dominant_faction = f

func reset_for_new_run() -> void:
    _faction_levels = {Faction.BLOOD: 0, Faction.KNOWLEDGE: 0, Faction.HEART: 0}
    _dominant_faction = Faction.BLOOD
