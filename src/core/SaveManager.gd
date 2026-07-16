extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_EXTENSION: String = ".save"

func _ready() -> void:
    _ensure_save_dir()

func _ensure_save_dir() -> void:
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int = 0) -> bool:
    var path = SAVE_DIR + str(slot) + SAVE_EXTENSION
    var data = _collect_save_data()
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    return true

func load_game(slot: int = 0) -> bool:
    var path = SAVE_DIR + str(slot) + SAVE_EXTENSION
    if not FileAccess.file_exists(path):
        return false
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return false
    var text = file.get_as_text()
    file.close()
    var data = JSON.parse_string(text)
    if data == null:
        return false
    _apply_save_data(data)
    return true

func has_save(slot: int = 0) -> bool:
    return FileAccess.file_exists(SAVE_DIR + str(slot) + SAVE_EXTENSION)

func delete_save(slot: int = 0) -> void:
    var path = SAVE_DIR + str(slot) + SAVE_EXTENSION
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)

func _collect_save_data() -> Dictionary:
    return {
        "version": 1,
        "timestamp": Time.get_unix_time_from_system(),
        "meta": {
            "run_count": MetaProgressManager.get_run_count(),
            "inherited_san_cap_loss": MetaProgressManager._inherited_san_cap_loss,
            "inherited_madness_rate": MetaProgressManager._inherited_madness_rate,
            "tindalos_marked": MetaProgressManager._tindalos_marked,
            "unlocked_items": MetaProgressManager._unlocked_item_ids,
            "unlocked_parts": MetaProgressManager._unlocked_part_ids,
            "unlocked_mutations": MetaProgressManager._unlocked_mutation_ids,
            "unlocked_sets": MetaProgressManager._unlocked_set_ids,
            "unlocked_endings": MetaProgressManager._unlocked_endings,
            "bestiary": MetaProgressManager._bestiary
        },
        "san": {
            "current": SANManager.current_san,
            "max": SANManager.san_max,
            "cap_loss": SANManager.san_cap_loss
        }
    }

func _apply_save_data(data: Dictionary) -> void:
    if data.has("meta"):
        var meta = data["meta"]
        MetaProgressManager._run_count = meta.get("run_count", 0)
        MetaProgressManager._inherited_san_cap_loss = meta.get("inherited_san_cap_loss", 0.0)
        MetaProgressManager._inherited_madness_rate = meta.get("inherited_madness_rate", 0.0)
        MetaProgressManager._tindalos_marked = meta.get("tindalos_marked", false)
        MetaProgressManager._unlocked_item_ids = meta.get("unlocked_items", [])
        MetaProgressManager._unlocked_part_ids = meta.get("unlocked_parts", [])
        MetaProgressManager._unlocked_mutation_ids = meta.get("unlocked_mutations", [])
        MetaProgressManager._unlocked_set_ids = meta.get("unlocked_sets", [])
        MetaProgressManager._unlocked_endings = meta.get("unlocked_endings", [])
        MetaProgressManager._bestiary = meta.get("bestiary", [])
    if data.has("san"):
        var san = data["san"]
        SANManager.current_san = san.get("current", 100.0)
        SANManager.san_max = san.get("max", 100.0)
        SANManager.san_cap_loss = san.get("cap_loss", 0.0)
