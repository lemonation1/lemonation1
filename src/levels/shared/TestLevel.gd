extends Node2D
## 测试关卡 - 用于验证玩家手感（移动/跳跃/冲刺/攻击）

@onready var _player: CharacterBody2D = $Player
@onready var _background: ColorRect = $Background
@onready var _background_layer: ColorRect = $BackgroundLayer

func _ready() -> void:
	# Q版柔和背景：深蓝调 + 紫色雾感
	_background.color = GameConstants.THEME_BG_DEEP
	_background_layer.color = Color(
		GameConstants.THEME_ACCENT_PURPLE.r,
		GameConstants.THEME_ACCENT_PURPLE.g,
		GameConstants.THEME_ACCENT_PURPLE.b,
		0.06
	)

	# 设置区域污染倍率
	SANManager.set_pollution_multiplier(1.0)
	SANManager.set_safe_zone(false)

	# 标记关卡已加载
	EventBus.show_notification.emit("C1-1 普罗维登斯码头", 0)

	# 连接玩家攻击信号
	_player.get_node("AttackArea").body_entered.connect(_on_attack_hit)

func _on_attack_hit(body: Node) -> void:
	if body.is_in_group("enemies"):
		# TODO: 敌人受伤逻辑
		body.queue_free()
