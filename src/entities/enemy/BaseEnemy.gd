extends CharacterBody2D
## 基础敌人 - 巡逻/追击/攻击 三状态AI + 受击/死亡
## Q版ColorRect拼贴视觉，与Player风格统一

signal died(enemy: Node)

enum State { PATROL, CHASE, ATTACK, HURT, DEAD }

var _state: State = State.PATROL
var _facing: int = -1
var _hp: int = 50
var _max_hp: int = 50
var _damage: int = 10
var _speed: float = 100.0
var _enemy_id: String = ""
var _enemy_data: Resource = null

# 巡逻
var _patrol_origin: Vector2
var _patrol_range: float = 80.0

# 追击
var _player_ref: CharacterBody2D = null
var _attack_cooldown: float = 0.0
var _attack_windup: float = 0.0
var _attack_active: float = 0.0

# 受击
var _hurt_flash: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _death_timer: float = 0.0

# SAN目击
var _has_been_seen: bool = false

# 节点引用
@onready var _visual: Node2D = $VisualRoot
@onready var _body: ColorRect = $VisualRoot/Body
@onready var _eye_l: ColorRect = $VisualRoot/EyeL
@onready var _eye_r: ColorRect = $VisualRoot/EyeR
@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_shape: CollisionShape2D = $AttackArea/AttackShape
@onready var _detect_area: Area2D = $DetectArea
@onready var _hp_bar: ProgressBar = $VisualRoot/HPBar


func _ready() -> void:
	add_to_group(GameConstants.GROUP_ENEMIES)
	_patrol_origin = global_position
	_attack_shape.disabled = true
	_attack_area.body_entered.connect(_on_attack_body_entered)
	_detect_area.body_entered.connect(_on_detect_body_entered)
	_detect_area.body_exited.connect(_on_detect_body_exited)
	_update_hp_bar()


func setup(data: Resource) -> void:
	_enemy_data = data
	_enemy_id = data.id
	_max_hp = data.base_hp
	_hp = _max_hp
	_damage = data.base_damage
	_speed = data.base_speed
	# 根据分类设色
	match data.category:
		EnemyData.Category.SERVANT_RACE:
			_body.color = GameConstants.THEME_ENEMY_DEEPONE
		_:
			_body.color = GameConstants.THEME_ENEMY_CULTIST
	_update_hp_bar()


func _physics_process(delta: float) -> void:
	if GameManager.is_in_hit_stop():
		return

	if _state == State.DEAD:
		_death_timer -= delta
		var alpha = maxf(0.0, _death_timer / GameConstants.ENEMY_DEATH_FADE_DURATION)
		modulate.a = alpha
		if _death_timer <= 0.0:
			queue_free()
		return

	_update_timers(delta)
	_apply_gravity(delta)

	match _state:
		State.PATROL:
			_handle_patrol(delta)
		State.CHASE:
			_handle_chase(delta)
		State.ATTACK:
			_handle_attack_state(delta)
		State.HURT:
			_handle_hurt(delta)

	_apply_knockback(delta)
	move_and_slide()
	_update_facing()
	_update_flash(delta)
	_check_san_sight()


func _update_timers(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GameConstants.ENEMY_GRAVITY * delta, GameConstants.ENEMY_MAX_FALL_SPEED)


func _apply_knockback(delta: float) -> void:
	if _knockback_vel != Vector2.ZERO:
		velocity.x = _knockback_vel.x
		_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, GameConstants.ENEMY_KNOCKBACK_FRICTION * delta)


# ====================
# 巡逻状态
# ====================
func _handle_patrol(delta: float) -> void:
	var patrol_speed = _speed * GameConstants.ENEMY_PATROL_SPEED_MULT
	velocity.x = _facing * patrol_speed

	# 巡逻到边界转向
	var dist_from_origin = global_position.x - _patrol_origin.x
	if absf(dist_from_origin) > _patrol_range:
		_facing = -signf(dist_from_origin) as int

	# 碰墙转向
	if is_on_wall():
		_facing *= -1


# ====================
# 追击状态
# ====================
func _handle_chase(delta: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_state = State.PATROL
		return

	var to_player = _player_ref.global_position - global_position
	var dist = absf(to_player.x)

	# 超出追踪范围回到巡逻
	if dist > GameConstants.ENEMY_DETECT_RANGE * 1.5:
		_player_ref = null
		_state = State.PATROL
		_patrol_origin = global_position
		return

	# 进入攻击范围
	if dist <= GameConstants.ENEMY_ATTACK_RANGE and _attack_cooldown <= 0.0:
		_start_attack()
		return

	var chase_speed = _speed * GameConstants.ENEMY_CHASE_SPEED_MULT
	_facing = signf(to_player.x) as int if to_player.x != 0.0 else _facing
	velocity.x = _facing * chase_speed

	# 简单跳跃：玩家在上方且有墙
	if to_player.y < -30.0 and is_on_wall() and is_on_floor():
		velocity.y = GameConstants.PLAYER_JUMP_VELOCITY * 0.7


# ====================
# 攻击状态
# ====================
func _start_attack() -> void:
	_state = State.ATTACK
	_attack_windup = GameConstants.ENEMY_ATTACK_WINDUP
	_attack_active = 0.0
	velocity.x = 0.0


func _handle_attack_state(delta: float) -> void:
	if _attack_windup > 0.0:
		# 前摇 - 身体微缩
		_attack_windup -= delta
		_visual.scale = _visual.scale.lerp(Vector2(0.9, 1.1), delta * 10.0)
		if _attack_windup <= 0.0:
			# 攻击生效
			_attack_active = GameConstants.ENEMY_ATTACK_DURATION
			_attack_shape.disabled = false
			_attack_area.position.x = 24.0 * _facing
			_visual.scale = Vector2(1.15, 0.85)
	else:
		_attack_active -= delta
		if _attack_active <= 0.0:
			_attack_shape.disabled = true
			_attack_cooldown = GameConstants.ENEMY_ATTACK_COOLDOWN
			_visual.scale = Vector2.ONE
			_state = State.CHASE


# ====================
# 受击状态
# ====================
func _handle_hurt(delta: float) -> void:
	# 受击时被击退滑行，不主动移动
	# 击退结束后回到追击
	if _knockback_vel.length() < 20.0:
		_state = State.CHASE if _player_ref != null else State.PATROL


# ====================
# 外部接口 - 受击
# ====================
func take_damage(amount: int, from_direction: Vector2) -> void:
	if _state == State.DEAD:
		return

	_hp = max(0, _hp - amount)
	_hurt_flash = GameConstants.ENEMY_FLASH_DURATION
	_update_hp_bar()

	if _hp <= 0:
		_die()
	else:
		_state = State.HURT
		# 击退
		_knockback_vel = from_direction * 150.0
		velocity.y = -80.0  # 微上抛


func apply_knockback(direction: Vector2, force: float) -> void:
	## 玩家攻击调用的击退接口
	if _state == State.DEAD:
		return
	_knockback_vel = direction * force
	# 攻击命中时也造成伤害（由Player的_on_attack_body_entered处理伤害传递）
	# 这里只处理击退
	if _state != State.HURT:
		_state = State.HURT


func _die() -> void:
	_state = State.DEAD
	_death_timer = GameConstants.ENEMY_DEATH_FADE_DURATION
	_attack_shape.disabled = true
	# 停止移动
	velocity = Vector2.ZERO
	died.emit(self)
	# 掉落
	_spawn_drops()
	# 击杀通知
	EventBus.enemy_killed.emit(_enemy_id)


# ====================
# 掉落
# ====================
func _spawn_drops() -> void:
	if randf() > GameConstants.ENEMY_DROP_CHANCE:
		return
	# 掉落一个道具拾取物
	var ItemPickupScene = preload("res://src/entities/items/ItemPickup.tscn")
	var drop = ItemPickupScene.instantiate()
	get_parent().add_child(drop)
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * randf_range(10.0, GameConstants.ENEMY_DROP_PICKUP_RADIUS)
	drop.global_position = global_position + offset
	# 随机选一个绿阶道具ID（暂时用占位）
	var pool = ItemPoolManager.get_pool(0)  # 阿卡姆池
	if pool and not pool.item_weights.is_empty():
		drop.setup(ItemPoolManager.roll_item(0))
	else:
		drop.setup("material_eldritch_residue")  # 占位材料


# ====================
# 朝向与视觉
# ====================
func _update_facing() -> void:
	_visual.scale.x = absf(_visual.scale.x) * _facing


func _update_flash(delta: float) -> void:
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		_body.color = GameConstants.THEME_ENEMY_HURT
		_eye_l.color = GameConstants.THEME_ENEMY_HURT
		_eye_r.color = GameConstants.THEME_ENEMY_HURT
	else:
		# 恢复原色
		if _enemy_data:
			match _enemy_data.category:
				EnemyData.Category.SERVANT_RACE:
					_body.color = GameConstants.THEME_ENEMY_DEEPONE
				_:
					_body.color = GameConstants.THEME_ENEMY_CULTIST
		else:
			_body.color = GameConstants.THEME_ENEMY_CULTIST
		_eye_l.color = Color.WHITE
		_eye_r.color = Color.WHITE


func _update_hp_bar() -> void:
	if _hp_bar:
		_hp_bar.max_value = _max_hp
		_hp_bar.value = _hp
		_hp_bar.visible = _hp < _max_hp and _state != State.DEAD


# ====================
# SAN目击损失
# ====================
func _check_san_sight() -> void:
	if _has_been_seen or _state == State.DEAD:
		return
	if _enemy_data == null:
		return
	var player = _get_player()
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= GameConstants.ENEMY_SAN_DAMAGE_RANGE:
		# 首次目击造成SAN损失
		var san_loss = _enemy_data.san_loss_on_sight_first
		if san_loss != null and san_loss != "":
			var loss = Dice.roll(san_loss)
			if loss > 0:
				SANManager.apply_temporary_loss(float(loss), "enemy_sight:" + _enemy_id)
		_has_been_seen = true


# ====================
# 信号处理
# ====================
func _on_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_group"):
		_player_ref = body as CharacterBody2D
		if _state == State.PATROL:
			_state = State.CHASE


func _on_detect_body_exited(body: Node2D) -> void:
	if _player_ref == body:
		# 不立即丢失，让追击逻辑处理距离
		pass


func _on_attack_body_entered(body: Node2D) -> void:
	# 攻击到玩家
	if body.is_in_group("player_group"):
		if body.has_method("take_damage"):
			body.take_damage(_damage, Vector2(_facing, 0))


# ====================
# 工具
# ====================
func _get_player() -> CharacterBody2D:
	if _player_ref != null and is_instance_valid(_player_ref):
		return _player_ref
	# 尝试从场景树找玩家
	var players = get_tree().get_nodes_in_group("player_group")
	if players.size() > 0:
		return players[0] as CharacterBody2D
	return null

func get_enemy_id() -> String:
	return _enemy_id
