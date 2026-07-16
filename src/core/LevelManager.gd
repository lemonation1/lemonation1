extends Node

var _current_chapter: String = ""
var _current_sub_level: String = ""
var _completed_levels: Array[String] = []
var _level_database: Dictionary = {}  # {level_id: LevelData}
var _boss_database: Dictionary = {}  # {boss_id: BossData}
var _enemy_database: Dictionary = {}  # {enemy_id: EnemyData}

func register_level_data(level_data: Resource) -> void:
    _level_database[level_data.chapter_id] = level_data

func register_boss_data(boss_data: Resource) -> void:
    _boss_database[boss_data.id] = boss_data

func register_enemy_data(enemy_data: Resource) -> void:
    _enemy_database[enemy_data.id] = enemy_data

func get_level_data(chapter_id: String) -> Resource:
    return _level_database.get(chapter_id)

func get_boss_data(boss_id: String) -> Resource:
    return _boss_database.get(boss_id)

func get_enemy_data(enemy_id: String) -> Resource:
    return _enemy_database.get(enemy_id)

func load_level(chapter_id: String, sub_level_id: String) -> void:
    _current_chapter = chapter_id
    _current_sub_level = sub_level_id
    var data = get_level_data(chapter_id)
    if data:
        SANManager.set_pollution_multiplier(data.pollution_multiplier)
    EventBus.level_loaded.emit(chapter_id, sub_level_id)

func complete_level(chapter_id: String, sub_level_id: String) -> void:
    var key = chapter_id + "-" + sub_level_id
    if key not in _completed_levels:
        _completed_levels.append(key)
    EventBus.level_completed.emit(chapter_id, sub_level_id)

func is_level_completed(chapter_id: String, sub_level_id: String) -> bool:
    var key = chapter_id + "-" + sub_level_id
    return key in _completed_levels

func get_current_chapter() -> String:
    return _current_chapter

func get_current_sub_level() -> String:
    return _current_sub_level

func get_recommended_faction(chapter_id: String) -> int:
    var data = get_level_data(chapter_id)
    if data:
        return data.recommended_faction
    return 3  # ALL

func reset_for_new_run() -> void:
    _current_chapter = ""
    _current_sub_level = ""
    _completed_levels.clear()
