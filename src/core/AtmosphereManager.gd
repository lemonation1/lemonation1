extends Node
## 氛围渐变管理器 — 双层驱动: 章节基调(永久渐暗) + SAN阶段(实时扭曲)
## 让游戏从开篇的沉郁静谧, 随进度和理智下降逐渐走向疯狂
## 核心原则: 扭曲始终可读, 不用jump scare, 玩家在不知不觉中感到"不对劲"

signal atmosphere_changed(intensity: float)  # 0.0=正常 1.0=最疯狂

# 当前章节基调索引 (0=C1 ~ 7=C8)
var _chapter_index: int = 0
# 当前SAN阶段 (0=SOBER ~ 4=ZERO)
var _san_stage: int = 0
# 综合氛围强度 0.0~1.0
var _intensity: float = 0.0
# 是否在幻梦境 (额外加成扭曲)
var _in_dream: bool = false

# === 实时输出值 (供关卡/相机/UI读取) ===
var current_bg_color: Color = Color(0.06, 0.07, 0.11)
var current_fog_density: float = 0.15
var current_shadow_intensity: float = 0.3
var current_saturation_shift: float = 0.0
var current_hue_shift: float = 0.0
var current_vignette: float = 0.15
var current_chromatic_aberration: float = 0.0
var current_sway_amplitude: float = 0.0
var current_sway_frequency: float = 0.0
var current_flicker: float = 0.0

# 过渡用
var _transition_time: float = 0.0
var _transition_duration: float = 2.0
var _from_values: Dictionary = {}
var _target_values: Dictionary = {}
var _is_transitioning: bool = false

# 呼吸晃动计时
var _sway_time: float = 0.0
# 闪烁计时
var _flicker_time: float = 0.0
var _flicker_active: bool = false


func _ready() -> void:
	EventBus.san_stage_changed.connect(_on_san_stage_changed)
	EventBus.world_switched.connect(_on_world_switched)
	EventBus.level_loaded.connect(_on_level_loaded)
	_recalculate()


func _process(delta: float) -> void:
	if _is_transitioning:
		_update_transition(delta)
	_update_sway(delta)
	_update_flicker(delta)


# ====================
# 章节基调
# ====================
func set_chapter(chapter_id: String) -> void:
	var idx = _chapter_id_to_index(chapter_id)
	if idx == _chapter_index:
		return
	_chapter_index = idx
	_recalculate()


func _chapter_id_to_index(chapter_id: String) -> int:
	var idx = chapter_id.to_int()
	return clampi(idx - 1, 0, 7)


# ====================
# SAN阶段
# ====================
func _on_san_stage_changed(new_stage: int) -> void:
	_san_stage = new_stage
	_recalculate()


# ====================
# 双层世界
# ====================
func _on_world_switched(in_dream: bool) -> void:
	_in_dream = in_dream
	_recalculate()


# ====================
# 关卡加载 — 平滑过渡到新章节基调
# ====================
func _on_level_loaded(chapter_id: String, _sub_level_id: String) -> void:
	var idx = _chapter_id_to_index(chapter_id)
	if idx != _chapter_index:
		_start_transition(idx)


# ====================
# 核心计算 — 叠加章节基调 + SAN扭曲 + 幻梦加成
# ====================
func _recalculate() -> void:
	var chapter_data = GameConstants.ATMOSPHERE_CHAPTER_TINT[_chapter_index]
	var san_data = GameConstants.ATMOSPHERE_SAN_DISTORTION[_san_stage]

	# 章节基调 (永久性)
	var bg = chapter_data.bg
	var fog = chapter_data.fog
	var shadow = chapter_data.shadow
	var sat_shift = chapter_data.sat_shift
	var hue_shift = chapter_data.hue_shift

	# SAN扭曲 (可恢复) — 叠加在基调之上
	var vignette = san_data.vignette
	var chromatic = san_data.chromatic
	var sway_amp = san_data.sway_amp
	var sway_freq = san_data.sway_freq
	var flicker = san_data.flicker

	# 幻梦境: 色调更饱和扭曲, 但不是"恶心", 而是"超现实"
	if _in_dream:
		sat_shift += 0.15
		hue_shift += 0.08
		chromatic += 0.5
		vignette += 0.05

	# 综合强度: 章节占40%, SAN阶段占50%, 幻梦占10%
	var chapter_weight = float(_chapter_index) / 7.0 * 0.4
	var san_weight = float(_san_stage) / 4.0 * 0.5
	var dream_weight = (0.1 if _in_dream else 0.0)
	_intensity = clampf(chapter_weight + san_weight + dream_weight, 0.0, 1.0)

	current_bg_color = bg
	current_fog_density = fog
	current_shadow_intensity = shadow
	current_saturation_shift = sat_shift
	current_hue_shift = hue_shift
	current_vignette = vignette
	current_chromatic_aberration = chromatic
	current_sway_amplitude = sway_amp
	current_sway_frequency = sway_freq
	current_flicker = flicker

	atmosphere_changed.emit(_intensity)


# ====================
# 平滑过渡 (章节切换时)
# ====================
func _start_transition(new_chapter_idx: int) -> void:
	_from_values = {
		"bg": current_bg_color,
		"fog": current_fog_density,
		"shadow": current_shadow_intensity,
		"sat": current_saturation_shift,
		"hue": current_hue_shift,
	}
	_chapter_index = new_chapter_idx
	_recalculate()
	_target_values = {
		"bg": current_bg_color,
		"fog": current_fog_density,
		"shadow": current_shadow_intensity,
		"sat": current_saturation_shift,
		"hue": current_hue_shift,
	}
	# 恢复from值, 然后过渡到target
	current_bg_color = _from_values.bg
	current_fog_density = _from_values.fog
	current_shadow_intensity = _from_values.shadow
	current_saturation_shift = _from_values.sat
	current_hue_shift = _from_values.hue
	_is_transitioning = true
	_transition_time = 0.0


func _update_transition(delta: float) -> void:
	_transition_time += delta
	var t = clampf(_transition_time / _transition_duration, 0.0, 1.0)
	# 平滑插值 (ease-in-out)
	t = t * t * (3.0 - 2.0 * t)

	current_bg_color = _from_values.bg.lerp(_target_values.bg, t)
	current_fog_density = lerpf(_from_values.fog, _target_values.fog, t)
	current_shadow_intensity = lerpf(_from_values.shadow, _target_values.shadow, t)
	current_saturation_shift = lerpf(_from_values.sat, _target_values.sat, t)
	current_hue_shift = lerpf(_from_values.hue, _target_values.hue, t)

	if t >= 1.0:
		_is_transitioning = false


# ====================
# 呼吸式晃动 (相机/画面微移)
# ====================
func _update_sway(delta: float) -> void:
	_sway_time += delta


func get_sway_offset() -> Vector2:
	## 供相机调用, 返回当前应偏移的像素量
	if current_sway_amplitude <= 0.0:
		return Vector2.ZERO
	var x = sin(_sway_time * current_sway_frequency) * current_sway_amplitude
	var y = cos(_sway_time * current_sway_frequency * 0.7) * current_sway_amplitude * 0.5
	return Vector2(x, y)


# ====================
# 画面闪烁 (SAN低时偶发暗化)
# ====================
func _update_flicker(delta: float) -> void:
	if current_flicker <= 0.0:
		_flicker_active = false
		return
	_flicker_time -= delta
	if _flicker_time <= 0.0:
		# 随机触发一次闪烁
		if randf() < current_flicker * delta * 2.0:
			_flicker_active = true
			_flicker_time = 0.06 + randf() * 0.1  # 闪烁持续60-160ms
		else:
			_flicker_active = false
			_flicker_time = 0.5 + randf() * 2.0  # 下次闪烁间隔
	else:
		_flicker_active = true


func is_flickering() -> bool:
	return _flicker_active


# ====================
# 查询接口
# ====================
func get_intensity() -> float:
	return _intensity


func get_intensity_label() -> String:
	## 返回当前氛围的文字描述 (供调试/UI)
	if _intensity < 0.15:
		return "沉郁静谧"
	elif _intensity < 0.35:
		return "不安渐生"
	elif _intensity < 0.55:
		return "理智动摇"
	elif _intensity < 0.75:
		return "疯狂侵蚀"
	elif _intensity < 0.90:
		return "现实崩裂"
	else:
		return "深渊低语"
