extends Node2D
## C1-1 普罗维登斯码头 - 教学关卡
## 验证完整战斗循环: 移动/跳跃/冲刺/攻击/敌人/SAN/道具拾取

const EnemyScene = preload("res://src/entities/enemy/Enemy.tscn")
const SafeZoneScene = preload("res://src/entities/world/SafeZone.tscn")
const ItemPickupScene = preload("res://src/entities/items/ItemPickup.tscn")

@onready var _player: CharacterBody2D = $Player
@onready var _background: ColorRect = $Background
@onready var _background_layer: ColorRect = $BackgroundLayer


func _ready() -> void:
	# 氛围渐变: 从AtmosphereManager获取当前章节基调
	_background.color = AtmosphereManager.current_bg_color
	_background_layer.color = Color(
		GameConstants.THEME_ACCENT_PURPLE.r,
		GameConstants.THEME_ACCENT_PURPLE.g,
		GameConstants.THEME_ACCENT_PURPLE.b,
		AtmosphereManager.current_fog_density * 0.4  # 雾气浓度随氛围渐变
	)
	# 设置当前章节
	AtmosphereManager.set_chapter("C1")

	# 设置区域污染倍率
	SANManager.set_pollution_multiplier(1.0)
	SANManager.set_safe_zone(false)

	# 标记关卡已加载
	EventBus.show_notification.emit("C1-1 普罗维登斯码头", 0)

	# 生成敌人
	_spawn_enemies()

	# 放置安全区
	_spawn_safe_zone(Vector2(900, 620))

	# 放置拾取道具
	_spawn_item_pickup("elder_sign_small", Vector2(300, 580))
	_spawn_item_pickup("necronomicon_page", Vector2(700, 400))

	# 连接关卡完成信号
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _spawn_enemies() -> void:
	# 邪教徒 x2
	_spawn_enemy("cultist", Vector2(500, 620))
	_spawn_enemy("cultist", Vector2(800, 620))
	# 深潜者 x1 (在平台上)
	_spawn_enemy("deep_one", Vector2(640, 410))


func _spawn_enemy(enemy_id: String, pos: Vector2) -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	enemy.global_position = pos
	var data = LevelManager.get_enemy_data(enemy_id)
	if data:
		enemy.setup(data)
	else:
		# 如果数据未加载，用默认值
		print("警告: 敌人数据未找到: " + enemy_id)


func _spawn_safe_zone(pos: Vector2) -> void:
	var sz = SafeZoneScene.instantiate()
	add_child(sz)
	sz.global_position = pos


func _spawn_item_pickup(item_id: String, pos: Vector2) -> void:
	var pickup = ItemPickupScene.instantiate()
	add_child(pickup)
	pickup.global_position = pos
	pickup.setup(item_id)


func _on_enemy_killed(enemy_id: String) -> void:
	# 检查是否所有敌人都被消灭
	var enemies = get_tree().get_nodes_in_group(GameConstants.GROUP_ENEMIES)
	# 过滤掉已死亡的
	var alive = enemies.filter(func(e): return e.get("state") != 4)  # State.DEAD = 4
	if alive.is_empty():
		EventBus.show_notification.emit("区域清空! 探索继续...", 0)
		# 通关奖励道具
		_spawn_item_pickup("holy_water_small", Vector2(640, 400))
		LevelManager.complete_level("C1", "C1-1")
