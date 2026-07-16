extends Control
## 变异选择界面 - 通关后弹出, 从主导流派中三选一
## 流派: 血脉(珊瑚) / 知识(青灰) / 守心(苔绿)

signal mutation_selected(mutation_id: String)

const CARD_COUNT: int = 3

# 流派颜色
const FACTION_COLORS: Dictionary = {
	0: Color(0.68, 0.38, 0.40),  # 血脉 - 暗珊瑚
	1: Color(0.30, 0.55, 0.62),  # 知识 - 青灰
	2: Color(0.32, 0.50, 0.38),  # 守心 - 暗苔绿
}

@onready var _overlay: ColorRect = $Overlay
@onready var _title: Label = $Center/VBox/Title
@onready var _hint: Label = $Center/VBox/Hint
@onready var _cards_container: HBoxContainer = $Center/VBox/CardsContainer
@onready var _skip_button: Button = $Center/VBox/SkipButton

var _faction: int = 0
var _choices: Array = []  # 当前展示的变异数据数组
var _selected: bool = false


func _ready() -> void:
	visible = false
	# 暂停时仍可处理输入和动画
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_overlay.color = Color(0.03, 0.03, 0.06, 0.78)
	UITheme.style_label(_title, GameConstants.THEME_ACCENT_GOLD, true)
	_title.add_theme_font_size_override("font_size", 28)
	UITheme.style_label(_hint, GameConstants.THEME_TEXT_DIM)
	_hint.add_theme_font_size_override("font_size", 14)
	UITheme.style_button(_skip_button)
	_skip_button.pressed.connect(func(): _select(""))


## 弹出变异选择 (根据主导流派)
func show_selection() -> void:
	_faction = BuildManager.get_dominant_faction()
	var faction_name = GameConstants.FACTION_NAMES[_faction]
	_title.text = "变异涌动 · " + faction_name + "之道"
	_title.add_theme_color_override("font_color", FACTION_COLORS[_faction])

	# 获取该流派可用变异, 随机选3个
	var available = MutationManager.get_available_mutations(_faction)
	available.shuffle()
	_choices = available.slice(0, min(CARD_COUNT, available.size()))

	_build_cards()
	_show_animate()


func _build_cards() -> void:
	# 清空旧卡片
	for child in _cards_container.get_children():
		child.queue_free()

	if _choices.is_empty():
		_hint.text = "此流派尚无可觉醒的变异"
		return

	_hint.text = "选择一种变异以觉醒 (或放弃)"

	for i in _choices.size():
		var data = MutationManager.get_mutation_data(_choices[i])
		if data == null:
			continue
		var card = _make_card(data, i)
		_cards_container.add_child(card)


## 构建单张变异卡片
func _make_card(data: Resource, index: int) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(220, 280)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# 按钮样式 - 流派色边框
	var faction_color = FACTION_COLORS.get(_faction, FACTION_COLORS[0])
	var normal := StyleBoxFlat.new()
	normal.bg_color = GameConstants.THEME_PANEL_BG
	normal.border_color = faction_color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	var hover := normal.duplicate()
	hover.bg_color = GameConstants.THEME_PANEL_HOVER
	hover.border_color = GameConstants.THEME_ACCENT_GOLD
	hover.set_border_width_all(3)
	var pressed := normal.duplicate()
	pressed.bg_color = GameConstants.THEME_BG_LIGHT
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", pressed)
	card.add_theme_color_override("font_color", Color.TRANSPARENT)  # 不显示按钮文字

	# 卡片内容容器
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# 流派标签
	var faction_label = Label.new()
	faction_label.text = GameConstants.FACTION_NAMES[_faction]
	faction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faction_label.add_theme_color_override("font_color", faction_color)
	faction_label.add_theme_font_size_override("font_size", 14)
	faction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(faction_label)

	# 分隔
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	# 变异名称
	var name_label = Label.new()
	name_label.text = data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	UITheme.style_label(name_label, GameConstants.THEME_TEXT_LIGHT, true)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# 间隔
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# 效果描述
	var effect_label = Label.new()
	effect_label.text = data.effect_description
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 14)
	UITheme.style_label(effect_label, GameConstants.THEME_TEXT_LIGHT)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(effect_label)

	# 间隔
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer2)

	# 持续时间
	var duration_label = Label.new()
	var dur_text = {"per_level": "本关有效", "per_run": "本次轮回", "permanent": "永久"}
	duration_label.text = dur_text.get(data.duration, data.duration)
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	duration_label.add_theme_font_size_override("font_size", 12)
	UITheme.style_label(duration_label, GameConstants.THEME_TEXT_DIM)
	duration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(duration_label)

	# 序号提示
	var key_label = Label.new()
	key_label.text = "[" + str(index + 1) + "]"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 12)
	key_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(key_label)

	card.pressed.connect(func(): _select(data.id))
	return card


## 选择某个变异 (传空字符串=放弃)
func _select(mutation_id: String) -> void:
	if _selected:
		return
	_selected = true
	if mutation_id != "":
		MutationManager.select_mutation(mutation_id)
	mutation_selected.emit(mutation_id)
	_close_animate()


func _show_animate() -> void:
	visible = true
	_cards_container.modulate.a = 0.0
	_cards_container.scale = Vector2(0.94, 0.94)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_overlay, "color:a", 0.78, 0.2)
	tween.tween_property(_cards_container, "modulate:a", 1.0, 0.3).set_delay(0.1)
	tween.tween_property(_cards_container, "scale", Vector2.ONE, 0.3).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _close_animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_overlay, "color:a", 0.0, 0.18)
	tween.tween_property(_cards_container, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(func():
		visible = false
		queue_free()
	)


func _input(event: InputEvent) -> void:
	if not visible or _selected:
		return
	# 数字键 1/2/3 快速选择
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		if key == KEY_1 and _choices.size() >= 1:
			_select(_choices[0])
			get_viewport().set_input_as_handled()
		elif key == KEY_2 and _choices.size() >= 2:
			_select(_choices[1])
			get_viewport().set_input_as_handled()
		elif key == KEY_3 and _choices.size() >= 3:
			_select(_choices[2])
			get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE:
			_select("")
			get_viewport().set_input_as_handled()
