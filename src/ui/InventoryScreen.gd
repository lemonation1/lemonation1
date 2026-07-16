extends Control
## 背包界面 - 禁忌行囊
## 参考Resident Evil 4公文包网格拼图 + Tunic禁忌手册解读机制
## 网格8x6, 道具按尺寸占用, 可拖拽/旋转(R键/右键), 禁忌典籍需解读才显示真实效果

signal closed

const CELL_SIZE: int = 60  # 每格像素大小
const GRID_W: int = 8
const GRID_H: int = 6

const RARITY_NAMES: Dictionary = {1: "绿阶", 2: "蓝阶", 3: "紫阶", 4: "橙阶", 5: "红阶"}
const RARITY_COLORS: Dictionary = {
	1: Color(0.32, 0.50, 0.38),
	2: Color(0.30, 0.55, 0.62),
	3: Color(0.42, 0.34, 0.55),
	4: Color(0.72, 0.60, 0.32),
	5: Color(0.60, 0.30, 0.34),
}
const TYPE_NAMES: Dictionary = {0: "被动", 1: "主动", 2: "消耗品", 3: "材料", 4: "钥匙"}

@onready var _overlay: ColorRect = $Overlay
@onready var _close_button: Button = $Margin/VBox/Header/CloseButton
@onready var _title: Label = $Margin/VBox/Header/Title
@onready var _hint: Label = $Margin/VBox/Hint
@onready var _grid_container: Control = $Margin/VBox/Body/LeftPanel/Margin2/VBox/GridContainer
@onready var _grid_bg: ColorRect = $Margin/VBox/Body/LeftPanel/Margin2/VBox/GridContainer/GridBg
@onready var _grid_lines: Control = $Margin/VBox/Body/LeftPanel/Margin2/VBox/GridContainer/GridLines
@onready var _item_layer: Control = $Margin/VBox/Body/LeftPanel/Margin2/VBox/GridContainer/ItemLayer
@onready var _grid_usage_label: Label = $Margin/VBox/Body/LeftPanel/Margin2/VBox/StatusBox/GridUsageLabel
@onready var _san_pollution_label: Label = $Margin/VBox/Body/LeftPanel/Margin2/VBox/StatusBox/SanPollutionLabel

# 详情面板
@onready var _name_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/NameLabel
@onready var _rarity_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/RarityLabel
@onready var _type_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/TypeLabel
@onready var _effect_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/EffectLabel
@onready var _san_cost_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/SanCostLabel
@onready var _lore_short_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/LoreShortLabel
@onready var _lore_text_label: Label = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/LoreTextLabel
@onready var _decode_button: Button = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/DecodeButton
@onready var _discard_button: Button = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/DiscardButton

var _item_blocks: Dictionary = {}  # {item_id: ColorRect} 道具方块
var _selected_item_id: String = ""
var _dragging_item_id: String = ""
var _drag_offset: Vector2 = Vector2.ZERO
var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_overlay.color = Color(0.03, 0.03, 0.06, 0.85)
	UITheme.style_label(_title, GameConstants.THEME_ACCENT_GOLD, true)
	_title.add_theme_font_size_override("font_size", 26)
	UITheme.style_label(_hint, GameConstants.THEME_TEXT_DIM)
	_hint.add_theme_font_size_override("font_size", 13)
	# 面板标题
	var panel_title = $Margin/VBox/Body/LeftPanel/Margin2/VBox/PanelTitle
	var detail_title = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/DetailTitle
	for lbl in [panel_title, detail_title]:
		UITheme.style_label(lbl, GameConstants.THEME_TEXT_LIGHT, true)
		lbl.add_theme_font_size_override("font_size", 18)
	# 状态标签
	for lbl in [_grid_usage_label, _san_pollution_label]:
		UITheme.style_label(lbl, GameConstants.THEME_TEXT_DIM)
		lbl.add_theme_font_size_override("font_size", 13)
	# 详情标签
	for lbl in [_name_label, _rarity_label, _type_label, _effect_label, _san_cost_label,
				_lore_short_label, _lore_text_label]:
		UITheme.style_label(lbl, GameConstants.THEME_TEXT_LIGHT)
		lbl.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_font_size_override("font_size", 20)
	# 短评/详细介绍标题
	var lore_title = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/LoreTitle
	var lore_text_title = $Margin/VBox/Body/RightPanel/Margin2/ScrollBox/DetailVBox/LoreTextTitle
	for lbl in [lore_title, lore_text_title]:
		UITheme.style_label(lbl, GameConstants.THEME_ACCENT_GOLD)
		lbl.add_theme_font_size_override("font_size", 13)
	# 按钮
	UITheme.style_button(_close_button)
	UITheme.style_button(_decode_button)
	UITheme.style_button(_discard_button)
	# 设置网格背景尺寸
	_grid_bg.size = Vector2(GRID_W * CELL_SIZE, GRID_H * CELL_SIZE)
	_grid_lines.size = Vector2(GRID_W * CELL_SIZE, GRID_H * CELL_SIZE)
	_item_layer.size = Vector2(GRID_W * CELL_SIZE, GRID_H * CELL_SIZE)
	_draw_grid_lines()
	_close_button.pressed.connect(close)
	_decode_button.pressed.connect(_on_decode_pressed)
	_discard_button.pressed.connect(_on_discard_pressed)


## 绘制网格线
func _draw_grid_lines() -> void:
	# 用Line2D画网格线 (或者用多个ColorRect)
	for x in range(GRID_W + 1):
		var line = ColorRect.new()
		line.position = Vector2(x * CELL_SIZE - 1, 0)
		line.size = Vector2(2, GRID_H * CELL_SIZE)
		line.color = Color(0.15, 0.17, 0.24, 0.6)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid_lines.add_child(line)
	for y in range(GRID_H + 1):
		var line = ColorRect.new()
		line.position = Vector2(0, y * CELL_SIZE - 1)
		line.size = Vector2(GRID_W * CELL_SIZE, 2)
		line.color = Color(0.15, 0.17, 0.24, 0.6)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid_lines.add_child(line)


## 打开界面
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_selected_item_id = ""
	_refresh_all()
	_show_animate()


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_close_animate()


func _show_animate() -> void:
	modulate.a = 0.0
	scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _close_animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.18)
	tween.chain().tween_callback(func():
		visible = false
		closed.emit()
		queue_free()
	)


## 刷新全部
func _refresh_all() -> void:
	_refresh_grid()
	_refresh_detail()
	_refresh_status()


## 刷新网格 - 渲染所有道具方块
func _refresh_grid() -> void:
	# 清除旧方块
	for child in _item_layer.get_children():
		child.queue_free()
	_item_blocks.clear()
	# 为每个已放置道具创建方块
	for item_id in InventoryManager.get_placed_items():
		_create_item_block(item_id)


## 创建单个道具方块
func _create_item_block(item_id: String) -> void:
	var data = InventoryManager.get_item_data(item_id)
	if data == null:
		return
	var pos = InventoryManager.get_item_position(item_id)
	var rotated = InventoryManager.is_item_rotated(item_id)
	var base_size = data.get_grid_size()
	var size = Vector2i(base_size.y, base_size.x) if rotated else base_size
	# 方块容器
	var block = ColorRect.new()
	block.position = Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
	block.size = Vector2(size.x * CELL_SIZE, size.y * CELL_SIZE)
	var rarity_color = RARITY_COLORS.get(data.rarity, Color.WHITE)
	# 未解读的禁忌典籍显示为暗色神秘符号
	if InventoryManager.item_needs_decoding(item_id):
		block.color = Color(0.12, 0.10, 0.18, 0.95)
		block.border_color = Color(0.35, 0.30, 0.45, 1.0)
	else:
		block.color = Color(rarity_color.r * 0.3, rarity_color.g * 0.3, rarity_color.b * 0.3, 0.92)
		block.border_color = rarity_color
	# 用StyleBoxFlat做边框
	var sb = StyleBoxFlat.new()
	if InventoryManager.item_needs_decoding(item_id):
		sb.bg_color = Color(0.12, 0.10, 0.18, 0.95)
		sb.border_color = Color(0.35, 0.30, 0.45, 1.0)
	else:
		sb.bg_color = Color(rarity_color.r * 0.25, rarity_color.g * 0.25, rarity_color.b * 0.25, 0.92)
		sb.border_color = rarity_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 2
	sb.content_margin_top = 2
	sb.content_margin_right = 2
	sb.content_margin_bottom = 2
	block.add_theme_stylebox_override("panel", sb)
	# 道具名称标签
	var name_label = Label.new()
	if InventoryManager.item_needs_decoding(item_id):
		name_label.text = "???"
	else:
		name_label.text = data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.WHITE if not InventoryManager.item_needs_decoding(item_id) else Color(0.5, 0.45, 0.6))
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.anchors_preset = Control.PRESET_FULL_RECT
	name_label.offset_left = 4
	name_label.offset_top = 4
	name_label.offset_right = -4
	name_label.offset_bottom = -4
	block.add_child(name_label)
	# 选中高亮
	if item_id == _selected_item_id:
		sb.border_color = GameConstants.THEME_ACCENT_GOLD
		sb.set_border_width_all(3)
	# 连接鼠标事件 (用Control接收)
	block.mouse_filter = Control.MOUSE_FILTER_STOP
	block.gui_input.connect(_on_block_gui_input.bind(item_id))
	_item_layer.add_child(block)
	_item_blocks[item_id] = block


## 道具方块鼠标事件
func _on_block_gui_input(event: InputEvent, item_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖拽
				_selected_item_id = item_id
				_dragging_item_id = item_id
				var block = _item_blocks[item_id]
				_drag_offset = event.position
				_refresh_grid()
				_refresh_detail()
			else:
				# 结束拖拽 - 尝试放置到新位置
				if _dragging_item_id == item_id:
					_try_drop_at_mouse()
					_dragging_item_id = ""
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# 右键旋转
			_rotate_item(item_id)
	elif event is InputEventMouseMotion and _dragging_item_id == item_id:
		# 拖拽中方块跟随鼠标
		var block = _item_blocks[item_id]
		if block != null:
			block.position = _grid_container.get_local_mouse_position() - _drag_offset


## 尝试在鼠标位置放置道具
func _try_drop_at_mouse() -> void:
	if _dragging_item_id == "":
		return
	var local_pos = _grid_container.get_local_mouse_position() - _drag_offset
	var grid_x = int(local_pos.x / CELL_SIZE)
	var grid_y = int(local_pos.y / CELL_SIZE)
	var rotated = InventoryManager.is_item_rotated(_dragging_item_id)
	# 尝试放置, 失败则回到原位
	if InventoryManager.place_item(_dragging_item_id, Vector2i(grid_x, grid_y), rotated):
		_refresh_grid()
	else:
		_refresh_grid()  # 回原位


## 旋转道具
func _rotate_item(item_id: String) -> void:
	var pos = InventoryManager.get_item_position(item_id)
	var rotated = InventoryManager.is_item_rotated(item_id)
	# 尝试旋转后放置
	if InventoryManager.place_item(item_id, pos, not rotated):
		_refresh_grid()


## 刷新详情面板
func _refresh_detail() -> void:
	if _selected_item_id == "":
		_name_label.text = "—"
		_name_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
		_rarity_label.text = ""
		_type_label.text = ""
		_effect_label.text = "选择背包中的道具查看详情"
		_effect_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
		_san_cost_label.text = ""
		_lore_short_label.text = ""
		_lore_text_label.text = ""
		_decode_button.visible = false
		_discard_button.visible = false
		return
	var data = InventoryManager.get_item_data(_selected_item_id)
	if data == null:
		return
	var needs_decode = InventoryManager.item_needs_decoding(_selected_item_id)
	# 名称
	if needs_decode:
		_name_label.text = "??? (未解读)"
		_name_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
	else:
		_name_label.text = data.display_name
		_name_label.add_theme_color_override("font_color", RARITY_COLORS.get(data.rarity, GameConstants.THEME_TEXT_LIGHT))
	# 稀有度/类型
	_rarity_label.text = "稀有度: " + RARITY_NAMES.get(data.rarity, "")
	_rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(data.rarity, Color.WHITE))
	_type_label.text = "类型: " + TYPE_NAMES.get(data.item_type, "")
	# 效果
	if needs_decode:
		_effect_label.text = "效果: ??? (需要解读)"
		_effect_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
	else:
		_effect_label.text = "效果: " + data.effect_description
		_effect_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_LIGHT)
	# SAN代价
	var san_parts: Array[String] = []
	if data.san_cost_on_use > 0:
		san_parts.append("使用: -" + str(data.san_cost_on_use) + " SAN")
	if data.permanent_san_cap_cost > 0:
		san_parts.append("永久上限: -" + str(data.permanent_san_cap_cost))
	if data.san_pollution_per_min > 0:
		san_parts.append("持有污染: " + str(data.san_pollution_per_min) + "/分钟")
	if san_parts.is_empty():
		_san_cost_label.text = "代价: 无"
		_san_cost_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_HEALTHY)
	else:
		_san_cost_label.text = "代价: " + ", ".join(san_parts)
		_san_cost_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_WARN)
	# 短评/详细介绍
	if needs_decode:
		_lore_short_label.text = "「文字在蠕动，无法辨识...」"
		_lore_short_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
		_lore_text_label.text = "羊皮纸上的字符似乎在逃避你的目光。需要消耗SAN来解读这本禁忌之书。"
		_lore_text_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.6))
	else:
		_lore_short_label.text = "「" + data.lore_short + "」"
		_lore_short_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_ACCENT)
		_lore_text_label.text = data.lore_text
		_lore_text_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_LIGHT)
	# 按钮
	_decode_button.visible = needs_decode
	_discard_button.visible = true


## 刷新底部状态
func _refresh_status() -> void:
	var usage = InventoryManager.get_grid_usage()
	_grid_usage_label.text = "网格: " + str(usage.x) + " / " + str(usage.y)
	var san_pollution = InventoryManager.get_total_san_pollution_per_min()
	if san_pollution > 0:
		_san_pollution_label.text = "SAN污染: " + str(san_pollution) + " / 分钟"
		if san_pollution > 1.0:
			_san_pollution_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_DANGER)
		else:
			_san_pollution_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_WARN)
	else:
		_san_pollution_label.text = "SAN污染: 无"
		_san_pollution_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_HEALTHY)


## 解读按钮
func _on_decode_pressed() -> void:
	if _selected_item_id == "":
		return
	if InventoryManager.decode_item(_selected_item_id):
		_refresh_all()


## 丢弃按钮
func _on_discard_pressed() -> void:
	if _selected_item_id == "":
		return
	InventoryManager.discard_item(_selected_item_id)
	_selected_item_id = ""
	_refresh_all()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
			close()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and _selected_item_id != "":
			_rotate_item(_selected_item_id)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DELETE and _selected_item_id != "":
			_on_discard_pressed()
			get_viewport().set_input_as_handled()
