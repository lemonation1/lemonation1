extends Area2D
## 道具拾取实体 - 地面上的可拾取道具
## 碰触自动拾取，带发光浮动动画

var _item_id: String = ""
var _item_data: Resource = null
var _bob_time: float = 0.0
var _spawn_anim: float = 0.0

@onready var _visual: ColorRect = $Visual
@onready var _glow: ColorRect = $Glow
@onready var _collision: CollisionShape2D = $CollisionShape2D

# 稀有度颜色
const RARITY_COLORS: Dictionary = {
	1: Color(0.45, 0.80, 0.58, 1.0),  # 绿
	2: Color(0.40, 0.60, 0.95, 1.0),  # 蓝
	3: Color(0.65, 0.40, 0.85, 1.0),  # 紫
	4: Color(0.95, 0.65, 0.30, 1.0),  # 橙
	5: Color(0.92, 0.35, 0.40, 1.0),  # 红
}


func _ready() -> void:
	add_to_group(GameConstants.GROUP_ITEMS)
	body_entered.connect(_on_body_entered)
	# 生成弹出动画
	_spawn_anim = 0.25
	_visual.scale = Vector2.ZERO


func setup(item_id: String) -> void:
	_item_id = item_id
	_item_data = InventoryManager.get_item_data(item_id)
	# 延迟到_ready后设置颜色
	call_deferred("_apply_visual")


func _apply_visual() -> void:
	if _item_data != null:
		var color = RARITY_COLORS.get(_item_data.rarity, RARITY_COLORS[1])
		_visual.color = color
		_glow.color = Color(color.r, color.g, color.b, 0.2)
	else:
		# 占位材料 - 紫灰色
		_visual.color = Color(0.55, 0.45, 0.70, 1.0)
		_glow.color = Color(0.55, 0.45, 0.70, 0.2)


func _process(delta: float) -> void:
	_bob_time += delta
	# 浮动动画
	_visual.position.y = sin(_bob_time * 3.0) * 3.0
	_glow.position.y = _visual.position.y

	# 生成弹出动画
	if _spawn_anim > 0.0:
		_spawn_anim -= delta
		var t = 1.0 - maxf(0.0, _spawn_anim / 0.25)
		_visual.scale = Vector2.ONE * t
		_glow.scale = Vector2.ONE * t
	# 发光脉动
	var pulse = 0.6 + sin(_bob_time * 4.0) * 0.15
	_glow.modulate.a = pulse


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_group"):
		_pickup()


func _pickup() -> void:
	if _item_id != "":
		InventoryManager.add_item(_item_id)
		var display_name = _item_data.display_name if _item_data != null else _item_id
		var lore = _item_data.lore_short if _item_data != null and _item_data.lore_short != "" else ""
		if lore != "":
			# 拾取时显示短评 (一句)
			EventBus.show_notification.emit("获得: " + display_name + "\n「" + lore + "」", 0)
		else:
			EventBus.show_notification.emit("获得: " + display_name, 0)
	# 拾取特效
	_spawn_pickup_effect()
	queue_free()


func _spawn_pickup_effect() -> void:
	var tween = create_tween()
	var ghost = _visual.duplicate() as ColorRect
	ghost.position = _visual.position
	get_parent().add_child(ghost)
	tween.tween_property(ghost, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)
