extends Control
## 道具详情弹窗 - 点击道具时弹出, 展示短评和详细介绍
## 短评(lore_short)在拾取时显示, 详细介绍(lore_text)在此弹窗中展示

signal closed

var _item_data: Resource = null

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: Panel = $Center/Panel
@onready var _name_label: Label = $Center/Panel/VBox/Header/NameLabel
@onready var _rarity_label: Label = $Center/Panel/VBox/Header/RarityLabel
@onready var _type_label: Label = $Center/Panel/VBox/Header/TypeLabel
@onready var _effect_label: Label = $Center/Panel/VBox/Body/EffectLabel
@onready var _side_effect_label: Label = $Center/Panel/VBox/Body/SideEffectLabel
@onready var _lore_short_label: Label = $Center/Panel/VBox/Body/LoreShortLabel
@onready var _lore_text_label: Label = $Center/Panel/VBox/Body/LoreScroll/LoreText
@onready var _close_button: Button = $Center/Panel/VBox/Footer/CloseButton

# 稀有度名称
const RARITY_NAMES: Dictionary = {
	1: "绿", 2: "蓝", 3: "紫", 4: "橙", 5: "红"
}
# 稀有度颜色
const RARITY_COLORS: Dictionary = {
	1: Color(0.32, 0.50, 0.38), 2: Color(0.30, 0.55, 0.62),
	3: Color(0.42, 0.34, 0.55), 4: Color(0.72, 0.60, 0.32), 5: Color(0.68, 0.38, 0.40)
}
# 类型名称
const TYPE_NAMES: Dictionary = {
	0: "被动", 1: "主动", 2: "消耗品", 3: "材料", 4: "钥匙"
}


func _ready() -> void:
	visible = false
	_overlay.color = Color(0.02, 0.02, 0.04, 0.7)
	_close_button.pressed.connect(close)
	UITheme.style_panel(_panel, 6)
	UITheme.style_button(_close_button)
	UITheme.style_label(_name_label, GameConstants.THEME_TEXT_LIGHT, true)
	UITheme.style_label(_effect_label, GameConstants.THEME_ACCENT_CYAN)
	UITheme.style_label(_side_effect_label, GameConstants.THEME_ACCENT_CORAL)
	UITheme.style_label(_lore_short_label, GameConstants.THEME_TEXT_DIM)
	UITheme.style_label(_lore_text_label, GameConstants.THEME_TEXT_DIM)
	# 竖排自动换行
	_lore_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## 显示道具详情
func show_item(item_data: Resource) -> void:
	_item_data = item_data
	if item_data == null:
		return

	# 名称
	_name_label.text = item_data.display_name
	var rarity_color = RARITY_COLORS.get(item_data.rarity, RARITY_COLORS[1])
	_name_label.add_theme_color_override("font_color", rarity_color)

	# 稀有度 + 类型
	_rarity_label.text = RARITY_NAMES.get(item_data.rarity, "?") + "阶"
	_rarity_label.add_theme_color_override("font_color", rarity_color)
	_type_label.text = TYPE_NAMES.get(item_data.item_type, "未知")

	# 效果
	_effect_label.text = "效果: " + item_data.effect_description

	# 副作用
	if item_data.side_effect_type != 0:  # SideEffectType.NONE = 0
		var se_names = {1: "持续SAN损失", 2: "永久上限损失", 3: "幻觉", 4: "失控", 5: "空间错位", 6: "区域反转"}
		var se_name = se_names.get(item_data.side_effect_type, "未知")
		var se_val = item_data.side_effect_value if item_data.side_effect_value != "" else ""
		_side_effect_label.text = "代价: " + se_name + (" (" + se_val + ")" if se_val != "" else "")
		_side_effect_label.visible = true
	else:
		_side_effect_label.visible = false

	# 短评
	_lore_short_label.text = "「" + item_data.lore_short + "」" if item_data.lore_short != "" else ""

	# 详细介绍
	_lore_text_label.text = item_data.lore_text if item_data.lore_text != "" else "这段历史已失落于时光之中。"

	# 弹出动画
	visible = true
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.15)


func close() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "scale", Vector2(0.85, 0.85), 0.12)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(func():
		visible = false
		closed.emit()
	)


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
			close()
			get_viewport().set_input_as_handled()
	elif visible and event is InputEventMouseButton:
		# 点击遮罩关闭
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var panel_rect = _panel.get_global_rect()
			if not panel_rect.has_point(event.position):
				close()
				get_viewport().set_input_as_handled()
