extends Camera2D
## 平滑跟随相机 - 支持前瞻偏移与创伤式屏幕震动

var _trauma: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _lookahead: Vector2 = Vector2.ZERO
var _target_lookahead: Vector2 = Vector2.ZERO
var _base_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = GameConstants.CAMERA_SMOOTH_SPEED
	process_callback = Camera2D.CAMERA_PROCESS_PHYSICS
	_base_offset = offset

func _physics_process(delta: float) -> void:
	_update_shake(delta)
	_update_lookahead(delta)
	offset = _base_offset + _lookahead + _shake_offset

## 添加屏幕震动（0~1，二次方衰减）
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

## 设置前瞻方向与强度
func set_lookahead(direction: Vector2) -> void:
	_target_lookahead = direction * GameConstants.CAMERA_LOOKAHEAD_MAG

func _update_shake(delta: float) -> void:
	if _trauma > 0.0:
		var shake_amount = _trauma * _trauma
		var max_off = GameConstants.CAMERA_SHAKE_MAX_OFFSET
		_shake_offset = Vector2(
			randf_range(-1.0, 1.0) * shake_amount * max_off,
			randf_range(-1.0, 1.0) * shake_amount * max_off
		)
		_trauma = maxf(0.0, _trauma - delta * GameConstants.CAMERA_SHAKE_DECAY)
	else:
		_shake_offset = _shake_offset.lerp(Vector2.ZERO, delta * 10.0)

func _update_lookahead(delta: float) -> void:
	_lookahead = _lookahead.lerp(_target_lookahead, delta * GameConstants.CAMERA_LOOKAHEAD_LERP)
