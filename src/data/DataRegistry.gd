extends Node
## 数据注册器 - 启动时加载所有数据资源到管理器

func _ready() -> void:
	_register_items()
	_register_body_parts()
	_register_enemies()
	_register_bosses()
	_register_levels()
	_register_mutations()
	_register_madness()
	_register_sets()
	_register_pools()

func _register_items() -> void:
	var dir = DirAccess.open("res://src/data/items/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): InventoryManager.register_item_data(res))

func _register_body_parts() -> void:
	var dir = DirAccess.open("res://src/data/body_parts/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): BodyPartManager.register_part_data(res))

func _register_enemies() -> void:
	var dir = DirAccess.open("res://src/data/enemies/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): LevelManager.register_enemy_data(res))

func _register_bosses() -> void:
	var dir = DirAccess.open("res://src/data/bosses/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): LevelManager.register_boss_data(res))

func _register_levels() -> void:
	var dir = DirAccess.open("res://src/data/levels/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): LevelManager.register_level_data(res))

func _register_mutations() -> void:
	var dir = DirAccess.open("res://src/data/mutations/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): MutationManager.register_mutation_data(res))

func _register_madness() -> void:
	var dir = DirAccess.open("res://src/data/madness/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): MadnessManager.register_madness_data(res))

func _register_sets() -> void:
	# 套装数据暂不注册到管理器，由 InventoryManager 内部处理
	pass

func _register_pools() -> void:
	var dir = DirAccess.open("res://src/data/item_pools/")
	if dir == null:
		return
	_load_resources_from_dir(dir, func(res): ItemPoolManager.register_pool(res))

func _load_resources_from_dir(dir: DirAccess, callback: Callable) -> void:
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var path = dir.get_current_dir() + "/" + file_name
			var res = load(path)
			if res:
				callback.call(res)
		file_name = dir.get_next()
	dir.list_dir_end()
