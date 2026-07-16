extends CharacterBody2D
## 玩家控制器 - 丝之歌级手感优化
## 统一输入缓冲队列 · 土狼时间 · 可变跳跃高度 · 快落
## 冲刺取消链 · 命中停顿 · Squash&Stretch · 残影 · 落地反馈

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
var _can_double_jump: bool = false
var _has_double_jumped: bool = false
var _was_in_air: bool = false
var _prev_velocity_y: float = 0.0
var _is_fast_falling: bool = false

# === 冲刺 ===
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _ghost_timer: float = 0.0

# === 攻击 ===
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _attack_elapsed: float = 0.0
var _combo_count: int = 0
var _combo_window: float = 0.0
var _hit_targets: Array[Node2D] = []

# === 输入缓冲队列 ===
var _buffer_jump: float = 0.0
var _buffer_dash: float = 0.0
var _buffer_attack: float = 0.0

# === Squash & Stretch ===
var _squash_target: Vector2 = Vector2.ONE
var _squash_reset_timer: float = 0.0

# === 无敌 ===
var _is_invincible: bool = false
var _hurt_invincible_timer: float = 0.0

# === 生命值 ===
var _hp: int = GameConstants.PLAYER_MAX_HP
var _max_hp: int = GameConstants.PLAYER_MAX_HP
signal hp_changed(current: int, max_hp: int)


func _ready() -> void:
	add_to_group("player_group")
	_attack_shape.disabled = true
	_attack_area.body_entered.connect(_on_attack_body_entered)
	if BodyPartManager.has_ability("double_jump"):
		_can_double_jump = true
	hp_changed.emit(_hp, _max_hp)


func _physics_process(delta: float) -> void:
	# 全局命中停顿 - 冻结所有物理实体
	if GameManager.is_in_hit_stop():
		return

	_update_buffers(delta)
	_update_timers(delta)

	if _is_dashing:
		_handle_dash(delta)
	else:
		_apply_gravity(delta)
		_handle_movement(delta)
		_handle_jump()
		_handle_dash_input()
		_handle_attack()

	_handle_items()
	_handle_attack_cancel_into_dash()

	move_and_slide()

	_check_landing()
	_update_facing()
	_update_camera_lookahead()
	_prev_velocity_y = velocity.y


func _process(delta: float) -> void:
	_update_squash(delta)
	_update_modulate(delta)


# ====================
# 输入缓冲系统 - 三个动作均可预输入
# ====================
func _update_buffers(delta: float) -> void:
	if _buffer_jump > 0.0:
		_buffer_jump -= delta
	if _buffer_dash > 0.0:
		_buffer_dash -= delta
	if _buffer_attack > 0.0:
		_buffer_attack -= delta


func _update_timers(delta: float) -> void:
	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
	if _combo_window > 0.0:
		_combo_window -= delta
		if _combo_window <= 0.0:
			_combo_count = 0
	if _is_attacking:
		_attack_elapsed += delta
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()
	if _hurt_invincible_timer > 0.0:
		_hurt_invincible_timer -= delta
		if _hurt_invincible_timer <= 0.0:
			_is_invincible = false


# ====================
# 重力 + 快落
# ====================
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = GameConstants.PLAYER_COYOTE_TIME
		_has_double_jumped = false
		_is_fast_falling = false
		return

	# 快落判定：长按下键且正在下落
	var input_y := Input.get_axis("move_up", "move_down")
	if input_y > 0.3 and velocity.y > GameConstants.PLAYER_FAST_FALL_THRESHOLD:
		_is_fast_falling = true

	var max_fall := GameConstants.PLAYER_FAST_FALL_SPEED if _is_fast_falling else GameConstants.PLAYER_MAX_FALL_SPEED
	velocity.y = minf(velocity.y + GameConstants.PLAYER_GRAVITY * delta, max_fall)
	_coyote_timer -= delta


# ====================
# 移动 - 含转身平滑过渡
# ====================
func _handle_movement(delta: float) -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()
	var accel := GameConstants.PLAYER_ACCELERATION if on_floor else GameConstants.PLAYER_AIR_ACCELERATION
	var friction := GameConstants.PLAYER_FRICTION if on_floor else GameConstants.PLAYER_AIR_FRICTION

	if input_x != 0.0:
		# 转身检测：方向反转时给一个快速减速→加速过渡，避免瞬间反向的生硬感
		if signf(input_x) != signf(velocity.x) and absf(velocity.x) > 30.0:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 1.5)
			if absf(velocity.x) < 20.0:
				_squash(GameConstants.PLAYER_SQUASH_TURN, 0.06)
		else:
			velocity.x = move_toward(velocity.x, input_x * GameConstants.PLAYER_MOVE_SPEED, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


# ====================
# 跳跃（含土狼时间 / 二段跳 / 可变高度 / 输入缓冲）
# ====================
func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_buffer_jump = GameConstants.PLAYER_BUFFER_JUMP

	# 可变跳跃高度 - 松开跳跃键时截断上升
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= GameConstants.PLAYER_JUMP_CUT_MULTIPLIER

	if _buffer_jump <= 0.0:
		return

	# 普通跳跃（含土狼时间）
	if _coyote_timer > 0.0:
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY
		_coyote_timer = 0.0
		_buffer_jump = 0.0
		_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.1)
		_dash_dust.direction = Vector2(0, -1)
		_dash_dust.emitting = true
		return

	# 二段跳
	if _can_double_jump and not _has_double_jumped:
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY * GameConstants.PLAYER_DOUBLE_JUMP_MULT
		_has_double_jumped = true
		_buffer_jump = 0.0
		_squash(GameConstants.PLAYER_SQUASH_JUMP, 0.08)
		_dash_dust.direction = Vector2(0, 1)
		_dash_dust.emitting = true


# ====================
# 冲刺（含残影 + 结束微上抬）
# ====================
func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash"):
		_buffer_dash = GameConstants.PLAYER_BUFFER_DASH

	if _buffer_dash <= 0.0:
		return
	if _dash_cooldown > 0.0 or _is_dashing:
		return

	# 冲刺取消攻击
	if _is_attacking:
		_end_attack()

	_start_dash()
	_buffer_dash = 0.0


func _start_dash() -> void:
	_is_dashing = true
	_is_invincible = true
	_dash_timer = GameConstants.PLAYER_DASH_DURATION
	_dash_cooldown = GameConstants.PLAYER_DASH_COOLDOWN
	_ghost_timer = 0.0

	# 方向：优先输入方向，否则朝 facing
	var input_x := Input.get_axis("move_left", "move_right")
	var input_y := Input.get_axis("move_up", "move_down")
	if input_x != 0.0 or input_y != 0.0:
		_dash_direction = Vector2(input_x, input_y).normalized()
		if input_x != 0.0:
			_facing = int(signf(input_x))
	else:
		_dash_direction = Vector2(_facing, 0.0)

	velocity = _dash_direction * GameConstants.PLAYER_DASH_SPEED
	_squash(GameConstants.PLAYER_SQUASH_DASH, 0.1)
	_camera.add_trauma(GameConstants.SHAKE_DASH)
	_dash_dust.direction = -_dash_direction
	_dash_dust.emitting = true


func _handle_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * GameConstants.PLAYER_DASH_SPEED

	# 残影生成
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_spawn_ghost()
		_ghost_timer = GameConstants.PLAYER_DASH_GHOST_INTERVAL

	if _dash_timer <= 0.0:
		_end_dash()


func _end_dash() -> void:
	_is_dashing = false
	_is_invincible = false
	# 保留部分冲刺惯性 + 微上抬，防止冲刺结束直接栽下去
	velocity = _dash_direction * GameConstants.PLAYER_DASH_END_SPEED
	if not is_on_floor() and velocity.y > 0.0:
		velocity.y += GameConstants.PLAYER_DASH_END_LIFT
	_squash(Vector2(0.85, 1.15), 0.08)


# ====================
# 冲刺残影
# ====================
func _spawn_ghost() -> void:
	var ghost := ColorRect.new()
	ghost.color = Color(0.4, 0.75, 0.85, 0.45)
	ghost.size = Vector2(22, 34)
	ghost.position = _visual.global_position - Vector2(11, 17)
	ghost.scale = _visual.scale
	add_child(ghost)

	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, GameConstants.PLAYER_DASH_GHOST_LIFETIME)
	tween.tween_callback(ghost.queue_free)


# ====================
# 攻击连击（含输入缓冲）
# ====================
func _handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		_buffer_attack = GameConstants.PLAYER_BUFFER_ATTACK

	if _buffer_attack <= 0.0:
		return
	if _is_attacking and _combo_window <= 0.0:
		return

	_start_attack()
	_buffer_attack = 0.0


func _start_attack() -> void:
	if _combo_window <= 0.0:
		_combo_count = 0
	else:
		_combo_count = (_combo_count + 1) % GameConstants.PLAYER_ATTACK_MAX_COMBO

	_is_attacking = true
	_attack_elapsed = 0.0
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


# 攻击启动后短窗口内可用冲刺取消（取消链）
func _handle_attack_cancel_into_dash() -> void:
	if _is_attacking and _buffer_dash > 0.0 and _attack_elapsed <= GameConstants.PLAYER_ATTACK_CANCEL_WINDOW:
		if _dash_cooldown <= 0.0:
			_end_attack()
			# _buffer_dash 仍 > 0，下一帧的 _handle_dash_input 会消费它


func _on_attack_body_entered(body: Node2D) -> void:
	if body in _hit_targets or not body.is_in_group(GameConstants.GROUP_ENEMIES):
		return
	_hit_targets.append(body)
	# 命中停顿 + 屏幕震动
	GameManager.trigger_hit_stop(GameConstants.PLAYER_HIT_STOP_DURATION)
	_camera.add_trauma(GameConstants.SHAKE_ATTACK_HIT)
	# 对敌人造成伤害 + 击退
	var hit_dir = Vector2(_facing, -0.3).normalized()
	if body.has_method("take_damage"):
		# 连击段越高伤害越高
		var dmg = 10 + _combo_count * 5
		body.take_damage(dmg, hit_dir)
	elif body.has_method("apply_knockback"):
		body.apply_knockback(hit_dir, GameConstants.PLAYER_ATTACK_KNOCKBACK)
	# 命中减速 - 增强打击感
	velocity.x *= 0.3


# ====================
# 道具快捷栏
# ====================
func _handle_items() -> void:
	if Input.is_action_just_pressed("use_active_1"):
		InventoryManager.use_active_item(0)
	elif Input.is_action_just_pressed("use_active_2"):
		InventoryManager.use_active_item(1)
	elif Input.is_action_just_pressed("use_active_3"):
		InventoryManager.use_active_item(2)


# ====================
# 落地检测
# ====================
func _check_landing() -> void:
	var in_air := not is_on_floor()
	if _was_in_air and not in_air:
		var fall_speed := absf(_prev_velocity_y)
		var intensity := clampf(fall_speed / 400.0, 0.0, 1.0)
		_squash(GameConstants.PLAYER_SQUASH_LAND, 0.08)
		if fall_speed > 150.0:
			_land_dust.emitting = true
			_camera.add_trauma(lerpf(GameConstants.SHAKE_LAND_LIGHT, GameConstants.SHAKE_LAND_HEAVY, intensity))
		_is_fast_falling = false
	_was_in_air = in_air


# ====================
# 朝向
# ====================
func _update_facing() -> void:
	var input_x := Input.get_axis("move_left", "move_right")
	if input_x > 0.1:
		_facing = 1
	elif input_x < -0.1:
		_facing = -1


# ====================
# 相机前瞻
# ====================
func _update_camera_lookahead() -> void:
	var dir := Vector2.ZERO
	if absf(velocity.x) > 20.0:
		dir.x = signf(velocity.x)
	if _is_dashing and _dash_direction.y < -0.3:
		dir.y = -1.0
	elif _is_dashing and _dash_direction.y > 0.3:
		dir.y = 1.0
	_camera.set_lookahead(dir)


# ====================
# Squash & Stretch
# ====================
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


# ====================
# 透明度/闪烁
# ====================
func _update_modulate(delta: float) -> void:
	if _is_dashing:
		_visual.modulate.a = lerpf(_visual.modulate.a, 0.65, delta * 10.0)
	elif _is_invincible:
		_visual.modulate.a = 0.35 if fmod(Time.get_ticks_msec(), 120.0) < 60.0 else 1.0
	else:
		_visual.modulate.a = lerpf(_visual.modulate.a, 1.0, delta * 10.0)


# ====================
# 外部接口
# ====================
func apply_knockback(direction: Vector2, force: float) -> void:
	if _is_invincible:
		return
	velocity = direction * force
	_is_invincible = true
	_hurt_invincible_timer = 0.6
	_camera.add_trauma(GameConstants.SHAKE_HURT)


## 外部调用 - 敌人攻击命中玩家时调用
func take_damage(amount: int, from_direction: Vector2) -> void:
	if _is_invincible or _is_dashing:
		return
	_hp = max(0, _hp - amount)
	hp_changed.emit(_hp, _max_hp)
	# 受击击退
	velocity = from_direction * GameConstants.PLAYER_HURT_KNOCKBACK
	velocity.y = -120.0
	_is_invincible = true
	_hurt_invincible_timer = GameConstants.PLAYER_HURT_INVINCIBLE_TIME
	_camera.add_trauma(GameConstants.SHAKE_HURT)
	_squash(Vector2(1.3, 0.7), 0.1)
	if _hp <= 0:
		EventBus.player_died.emit("hp_zero")


func get_facing() -> int:
	return _facing


func get_hp() -> int:
	return _hp


func get_max_hp() -> int:
	return _max_hp


func heal(amount: int) -> void:
	_hp = min(_max_hp, _hp + amount)
	hp_changed.emit(_hp, _max_hp)
