extends CharacterBody2D
## 玩家控制器 - 手感优化核心
## 地面/空中加速度分离 · 土狼时间 · 跳跃缓冲 · 可变跳跃高度
## 冲刺(无敌帧) · 攻击连击 · 命中停顿 · Squash&Stretch · 落地反馈

# === 节点引用 ===
@onready var _visual: Node2D = $VisualRoot
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_shape: CollisionShape2D = $AttackArea/AttackShape
@onready var _camera: Camera2D = $Camera2D
@onready var _land_dust: CPUParticles2D = $LandDust
@onready var _dash_dust: CPUParticles2D = $DashDust

# === 移动状态 ===
var _facing: int = 1
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _can_double_jump: bool = false
var _has_double_jumped: bool = false
var _was_in_air: bool = false
var _prev_velocity_y: float = 0.0

# === 冲刺 ===
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

# === 攻击 ===
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _combo_count: int = 0
var _combo_window: float = 0.0
var _hit_targets: Array[Node2D] = []

# === Squash & Stretch ===
var _squash_target: Vector2 = Vector2.ONE
var _squash_reset_timer: float = 0.0

# === 无敌 ===
var _is_invincible: bool = false
var _hurt_invincible_timer: float = 0.0


func _ready() -> void:
	_attack_shape.disabled = true
	_attack_area.body_entered.connect(_on_attack_body_entered)
	if BodyPartManager.has_ability("double_jump"):
		_can_double_jump = true


func _physics_process(delta: float) -> void:
	# 全局命中停顿 - 冻结所有物理实体
	if GameManager.is_in_hit_stop():
		return

	_update_timers(delta)

	if _is_dashing:
		_handle_dash(delta)
	else:
		_apply_gravity(delta)
		_handle_movement(delta)
		_handle_jump(delta)

	_handle_dash_input()
	_handle_attack()
	_handle_items()

	move_and_slide()

	_check_landing()
	_update_facing()
	_update_camera_lookahead()

	_prev_velocity_y = velocity.y


func _process(delta: float) -> void:
	_update_squash(delta)
	_update_modulate(delta)


# === 计时器 ===
func _update_timers(delta: float) -> void:
	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
	if _combo_window > 0.0:
		_combo_window -= delta
		if _combo_window <= 0.0:
			_combo_count = 0
	if _is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()
	if _hurt_invincible_timer > 0.0:
		_hurt_invincible_timer -= delta
		if _hurt_invincible_timer <= 0.0:
			_is_invincible = false


# === 重力 ===
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GameConstants.PLAYER_GRAVITY * delta, GameConstants.PLAYER_MAX_FALL_SPEED)
		_coyote_timer -= delta
	else:
		_coyote_timer = GameConstants.PLAYER_COYOTE_TIME
		_has_double_jumped = false


# === 移动 ===
func _handle_movement(delta: float) -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()
	var accel := GameConstants.PLAYER_ACCELERATION if on_floor else GameConstants.PLAYER_AIR_ACCELERATION
	var friction := GameConstants.PLAYER_FRICTION if on_floor else GameConstants.PLAYER_AIR_FRICTION

	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * GameConstants.PLAYER_MOVE_SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


# === 跳跃 ===
func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = GameConstants.PLAYER_JUMP_BUFFER
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta

	# 普通跳跃（含土狼时间）
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.1)
	# 二段跳
	elif _jump_buffer_timer > 0.0 and _can_double_jump and not _has_double_jumped and not is_on_floor():
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY * GameConstants.PLAYER_DOUBLE_JUMP_MULT
		_has_double_jumped = true
		_jump_buffer_timer = 0.0
		_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.08)

	# 可变跳跃高度 - 松开跳跃键时截断上升
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= GameConstants.PLAYER_JUMP_CUT_MULTIPLIER


# === 冲刺 ===
func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and not _is_dashing:
		if _is_attacking:
			_end_attack()  # 冲刺取消攻击
		_start_dash()


func _start_dash() -> void:
	_is_dashing = true
	_is_invincible = true
	_dash_timer = GameConstants.PLAYER_DASH_DURATION
	_dash_cooldown = GameConstants.PLAYER_DASH_COOLDOWN
	_dash_direction = Vector2(_facing, 0.0)
	# 支持斜向冲刺
	var input_y := Input.get_axis("move_up", "move_down")
	if input_y != 0.0:
		_dash_direction = Vector2(_facing, input_y).normalized()
	velocity = _dash_direction * GameConstants.PLAYER_DASH_SPEED
	_squash(GameConstants.PLAYER_SQUASH_DASH, 0.1)
	_camera.add_trauma(GameConstants.SHAKE_DASH)
	_dash_dust.direction = -_dash_direction
	_dash_dust.emitting = true


func _handle_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * GameConstants.PLAYER_DASH_SPEED
	if _dash_timer <= 0.0:
		_end_dash()


func _end_dash() -> void:
	_is_dashing = false
	_is_invincible = false
	# 保留部分冲刺惯性
	velocity = _dash_direction * GameConstants.PLAYER_DASH_END_SPEED
	_squash(Vector2(0.85, 1.15), 0.08)


# === 攻击连击 ===
func _handle_attack() -> void:
	if _is_dashing:
		return
	if Input.is_action_just_pressed("attack") and (not _is_attacking or _combo_window > 0.0):
		_start_attack()


func _start_attack() -> void:
	if _combo_window <= 0.0:
		_combo_count = 0
	else:
		_combo_count = (_combo_count + 1) % GameConstants.PLAYER_ATTACK_MAX_COMBO

	_is_attacking = true
	_attack_timer = GameConstants.PLAYER_ATTACK_DURATION
	_combo_window = 0.0
	_hit_targets.clear()

	_attack_area.position.x = 24.0 * _facing
	_attack_shape.disabled = false

	# 不同连击段对应不同攻击范围
	var shape := _attack_shape.shape as RectangleShape2D
	match _combo_count:
		0: shape.size = Vector2(36, 28)
		1: shape.size = Vector2(42, 32)
		2: shape.size = Vector2(50, 36)

	# 攻击微前冲
	velocity.x += _facing * 60.0


func _end_attack() -> void:
	_is_attacking = false
	_attack_shape.disabled = true
	_combo_window = GameConstants.PLAYER_ATTACK_COMBO_WINDOW


func _on_attack_body_entered(body: Node2D) -> void:
	if body in _hit_targets or not body.is_in_group(GameConstants.GROUP_ENEMIES):
		return
	_hit_targets.append(body)
	# 命中停顿 + 屏幕震动
	GameManager.trigger_hit_stop(GameConstants.PLAYER_HIT_STOP_DURATION)
	_camera.add_trauma(GameConstants.SHAKE_ATTACK_HIT)
	# 击退敌人
	if body.has_method("apply_knockback"):
		body.apply_knockback(Vector2(_facing, -0.3).normalized(), GameConstants.PLAYER_ATTACK_KNOCKBACK)
	# 命中减速 - 增强打击感
	velocity.x *= 0.3


# === 道具快捷栏 ===
func _handle_items() -> void:
	if Input.is_action_just_pressed("use_active_1"):
		InventoryManager.use_active_item(0)
	elif Input.is_action_just_pressed("use_active_2"):
		InventoryManager.use_active_item(1)
	elif Input.is_action_just_pressed("use_active_3"):
		InventoryManager.use_active_item(2)


# === 落地检测 ===
func _check_landing() -> void:
	var in_air := not is_on_floor()
	if _was_in_air and not in_air:
		var fall_speed := absf(_prev_velocity_y)
		var intensity := clampf(fall_speed / 400.0, 0.0, 1.0)
		_squash(GameConstants.PLAYER_SQUASH_LAND, 0.08)
		if fall_speed > 150.0:
			_land_dust.emitting = true
			_camera.add_trauma(lerpf(GameConstants.SHAKE_LAND_LIGHT, GameConstants.SHAKE_LAND_HEAVY, intensity))
	_was_in_air = in_air


# === 朝向 ===
func _update_facing() -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x > 0.1:
		_facing = 1
	elif input_x < -0.1:
		_facing = -1


# === 相机前瞻 ===
func _update_camera_lookahead() -> void:
	var dir := Vector2.ZERO
	if absf(velocity.x) > 20.0:
		dir.x = signf(velocity.x)
	_camera.set_lookahead(dir)


# === Squash & Stretch ===
func _squash(target: Vector2, reset_delay: float) -> void:
	_squash_target = target
	_squash_reset_timer = reset_delay


func _update_squash(delta: float) -> void:
	if _squash_reset_timer > 0.0:
		_squash_reset_timer -= delta
		if _squash_reset_timer <= 0.0:
			_squash_target = Vector2.ONE
	# 朝向通过 scale.x 正负控制，squash 取绝对值 lerp
	var abs_x := absf(_visual.scale.x)
	abs_x = lerpf(abs_x, _squash_target.x, delta * GameConstants.PLAYER_SQUASH_LERP)
	var sy := lerpf(_visual.scale.y, _squash_target.y, delta * GameConstants.PLAYER_SQUASH_LERP)
	_visual.scale = Vector2(abs_x * _facing, sy)


# === 透明度/闪烁 ===
func _update_modulate(delta: float) -> void:
	if _is_dashing:
		_visual.modulate.a = lerpf(_visual.modulate.a, 0.65, delta * 10.0)
	elif _is_invincible:
		_visual.modulate.a = 0.35 if fmod(Time.get_ticks_msec(), 120.0) < 60.0 else 1.0
	else:
		_visual.modulate.a = lerpf(_visual.modulate.a, 1.0, delta * 10.0)


# === 外部接口 ===
func apply_knockback(direction: Vector2, force: float) -> void:
	if _is_invincible:
		return
	velocity = direction * force
	_is_invincible = true
	_hurt_invincible_timer = 0.6
	_camera.add_trauma(GameConstants.SHAKE_HURT)


func get_facing() -> int:
	return _facing
