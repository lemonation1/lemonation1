extends Area2D
## 安全区 - 玩家进入时加速SAN恢复，退出时恢复

@onready var _glow: ColorRect = $Glow

var _pulse_time: float = 0.0


func _ready() -> void:
	add_to_group(GameConstants.GROUP_SAFE_ZONE)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# 柔和光晕
	_glow.color = Color(
		GameConstants.THEME_ACCENT_GOLD.r,
		GameConstants.THEME_ACCENT_GOLD.g,
		GameConstants.THEME_ACCENT_GOLD.b,
		0.08
	)


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse = 0.06 + sin(_pulse_time * 2.0) * 0.03
	_glow.color.a = pulse


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_group"):
		SANManager.set_safe_zone(true)
		EventBus.show_notification.emit("安全区 - 理智恢复中", 0)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_group"):
		SANManager.set_safe_zone(false)
