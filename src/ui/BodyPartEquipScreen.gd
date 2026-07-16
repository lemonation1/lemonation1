extends Control
## 部件装备界面 - 血肉熔铸
## 参考Hollow Knight Silksong Crest系统: 人体轮廓槽位 + 部件库存 + 详情面板
## 流派色编码: 血脉(珊瑚红) / 知识(青灰) / 守心(苔绿) / 双修(暗金) / 无色(灰)
## 代价机制: 每个部件有SAN污染/分钟, 超载时翻倍

signal closed

# 槽位名称 (对应BodyPartData.SlotType枚举)
const SLOT_NAMES: Array = ["头部", "躯干", "左臂", "右臂", "左腿", "右腿", "背部", "血肉增生"]
const SLOT_KEYS: Array = ["HEAD", "TORSO", "LEFT_ARM", "RIGHT_ARM", "LEFT_LEG", "RIGHT_LEG", "BACK", "FLESH_GROWTH"]

# 稀有度
const RARITY_NAMES: Dictionary = {1: "绿阶", 2: "蓝阶", 3: "紫阶", 4: "橙阶", 5: "红阶"}
const RARITY_COLORS: Dictionary = {
	1: Color(0.32, 0.50, 0.38),
	2: Color(0.30, 0.55, 0.62),
	3: Color(0.42, 0.34, 0.55),
	4: Color(0.72, 0.60, 0.32),
	5: Color(0.60, 0.30, 0.34),
}

# 流派色
const FACTION_COLORS: Dictionary = {
	0: Color(0.68, 0.38, 0.40),   # 血脉 - 珊瑚
	1: Color(0.30, 0.55, 0.62),   # 知识 - 青灰
	2: Color(0.32, 0.50, 0.38),   # 守心 - 苔绿
	3: Color(0.72, 0.60, 0.32),   # 双修 - 暗金
	4: Color(0.50, 0.52, 0.58),   # 无色 - 灰
}
const FACTION_NAMES: Dictionary = {0: "血脉", 1: "知识", 2: "守心", 3: "双修", 4: "无色"}

# 属性名映射
const STAT_NAMES: Dictionary = {
	"attack": "攻击力",
	"defense": "防御",
	"move_speed": "移动速度",
	"spell_damage": "法术伤害",
	"attack_range": "攻击范围",
	"san_damage": "SAN伤害(对敌)",
	"water_duration": "水下时间",
	"max_hp": "最大生命",
	"max_san": "最大SAN",
}

@onready var _overlay: ColorRect = $Overlay
@onready var _close_button: Button = $Margin/VBox/Header/CloseButton
@onready var _title: Label = $Margin/VBox/Header/Title
@onready var _hint: Label = $Margin/VBox/Hint

# 左侧人体槽位
@onready var _body_container: Control = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer
@onready var _slot_buttons: Dictionary = {}  # {slot_index: Button}
@onready var _slot_used_label: Label = $Margin/VBox/Body/LeftPanel/Margin/VBox/StatusBox/SlotUsedLabel
@onready var _overload_label: Label = $Margin/VBox/Body/LeftPanel/Margin/VBox/StatusBox/OverloadLabel
@onready var _san_pollution_label: Label = $Margin/VBox/Body/LeftPanel/Margin/VBox/StatusBox/SanPollutionLabel

# 中间部件库
@onready var _filter_label: Label = $Margin/VBox/Body/MiddlePanel/Margin/VBox/FilterLabel
@onready var _item_list: ItemList = $Margin/VBox/Body/MiddlePanel/Margin/VBox/ItemList

# 右侧详情
@onready var _name_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/NameLabel
@onready var _source_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/SourceLabel
@onready var _rarity_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/RarityLabel
@onready var _faction_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/FactionLabel
@onready var _desc_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/DescLabel
@onready var _stats_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/StatsLabel
@onready var _san_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/SanLabel
@onready var _ability_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/AbilityLabel
@onready var _visual_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/VisualLabel
@onready var _set_label: Label = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/SetLabel
@onready var _equip_button: Button = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/EquipButton
@onready var _unequip_button: Button = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/UnequipButton

var _selected_slot: int = -1  # 当前选中槽位 (-1=全部)
var _selected_part_id: String = ""  # 当前选中部件
var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_overlay.color = Color(0.03, 0.03, 0.06, 0.85)
	# 标题
	UITheme.style_label(_title, GameConstants.THEME_ACCENT_GOLD, true)
	_title.add_theme_font_size_override("font_size", 26)
	UITheme.style_label(_hint, GameConstants.THEME_TEXT_DIM)
	_hint.add_theme_font_size_override("font_size", 13)
	# 三个面板标题
	var left_title = $Margin/VBox/Body/LeftPanel/Margin/VBox/PanelTitle
	var mid_title = $Margin/VBox/Body/MiddlePanel/Margin/VBox/PanelTitle
	var right_title = $Margin/VBox/Body/RightPanel/Margin/ScrollBox/DetailVBox/DetailTitle
	for lbl in [left_title, mid_title, right_title]:
		UITheme.style_label(lbl, GameConstants.THEME_TEXT_LIGHT, true)
		lbl.add_theme_font_size_override("font_size", 18)
	# 状态标签
	for lbl in [_slot_used_label, _overload_label, _san_pollution_label, _filter_label]:
		UITheme.style_label(lbl, GameConstants.THEME_TEXT_DIM)
		lbl.add_theme_font_size_override("font_size", 13)
	# 详情标签
	for lbl in [_name_label, _source_label, _rarity_label, _faction_label, _desc_label,
				_stats_label, _san_label, _ability_label, _visual_label, _set_label]:
		UITheme.style_label(lbl, GameConstants.THEME_TEXT_LIGHT)
		lbl.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_font_size_override("font_size", 20)
	# 按钮
	UITheme.style_button(_close_button)
	UITheme.style_button(_equip_button)
	UITheme.style_button(_unequip_button)
	# 注册槽位按钮
	_slot_buttons[0] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/HeadSlot
	_slot_buttons[1] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/TorsoSlot
	_slot_buttons[2] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/LeftArmSlot
	_slot_buttons[3] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/RightArmSlot
	_slot_buttons[4] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/LeftLegSlot
	_slot_buttons[5] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/RightLegSlot
	_slot_buttons[6] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/BackSlot
	_slot_buttons[7] = $Margin/VBox/Body/LeftPanel/Margin/VBox/BodyContainer/FleshGrowthSlot
	# 应用阴郁主题到所有槽位按钮和面板
	for slot_idx in _slot_buttons:
		var btn = _slot_buttons[slot_idx]
		_style_slot_button(btn)
		btn.pressed.connect(_on_slot_pressed.bind(slot_idx))
	_btn_setup_item_list()
	_close_button.pressed.connect(close)
	_equip_button.pressed.connect(_on_equip_pressed)
	_unequip_button.pressed.connect(_on_unequip_pressed)


func _btn_setup_item_list() -> void:
	_item_list.item_selected.connect(_on_item_selected)
	_item_list.item_activated.connect(_on_item_activated)


## 打开界面
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_selected_slot = -1
	_selected_part_id = ""
	_refresh_all()
	_show_animate()


## 关闭界面
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


## 槽位按钮样式
func _style_slot_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.12, 0.18, 0.85)
	normal.border_color = Color(0.28, 0.30, 0.40, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.16, 0.18, 0.26, 0.9)
	hover.border_color = GameConstants.THEME_ACCENT_GOLD
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
	btn.add_theme_color_override("font_hover_color", GameConstants.THEME_TEXT_LIGHT)
	btn.add_theme_font_size_override("font_size", 13)


## 刷新全部
func _refresh_all() -> void:
	_refresh_slots()
	_refresh_item_list()
	_refresh_detail()
	_refresh_status()


## 刷新槽位按钮显示 (展示已装备部件)
func _refresh_slots() -> void:
	for slot_idx in _slot_buttons:
		var btn = _slot_buttons[slot_idx]
		var equipped = BodyPartManager.get_equipped_part(slot_idx)
		var faction_color = GameConstants.THEME_TEXT_DIM
		var text = SLOT_NAMES[slot_idx]
		if equipped != null:
			text = equipped.display_name
			faction_color = FACTION_COLORS.get(equipped.faction, GameConstants.THEME_TEXT_LIGHT)
			# 边框按稀有度着色
			var rarity_color = RARITY_COLORS.get(equipped.rarity, Color.WHITE)
			var sb = btn.get_theme_stylebox("normal").duplicate()
			sb.border_color = rarity_color
			btn.add_theme_stylebox_override("normal", sb)
			var sb_h = btn.get_theme_stylebox("hover").duplicate()
			sb_h.border_color = rarity_color
			btn.add_theme_stylebox_override("hover", sb_h)
		else:
			# 重置边框
			var sb = btn.get_theme_stylebox("normal").duplicate()
			sb.border_color = Color(0.28, 0.30, 0.40, 1.0)
			btn.add_theme_stylebox_override("normal", sb)
			var sb_h = btn.get_theme_stylebox("hover").duplicate()
			sb_h.border_color = GameConstants.THEME_ACCENT_GOLD
			btn.add_theme_stylebox_override("hover", sb_h)
		btn.text = text
		btn.add_theme_color_override("font_color", faction_color)
		# 选中高亮
		if slot_idx == _selected_slot:
			var sb = btn.get_theme_stylebox("normal").duplicate()
			sb.bg_color = Color(0.20, 0.18, 0.10, 0.95)
			btn.add_theme_stylebox_override("normal", sb)


## 刷新部件列表
func _refresh_item_list() -> void:
	_item_list.clear()
	var parts: Array[String]
	if _selected_slot >= 0:
		# 显示该槽位的部件
		parts = BodyPartManager.get_owned_parts_for_slot(_selected_slot)
		_filter_label.text = "筛选: " + SLOT_NAMES[_selected_slot] + " (共" + str(parts.size()) + "件)"
	else:
		# 显示全部
		parts = BodyPartManager.get_owned_parts()
		_filter_label.text = "全部部件 (共" + str(parts.size()) + "件, 点击左侧槽位筛选)"
	# 按稀有度排序 (高在前)
	parts.sort_custom(func(a, b):
		var da = BodyPartManager.get_part_data(a)
		var db = BodyPartManager.get_part_data(b)
		return da.rarity > db.rarity
	)
	for i in parts.size():
		var data = BodyPartManager.get_part_data(parts[i])
		if data == null:
			continue
		var equipped_mark = ""
		# 检查该部件是否已装备
		for slot in BodyPartManager.get_all_equipped():
			if BodyPartManager.get_all_equipped()[slot].id == parts[i]:
				equipped_mark = "[已装备] "
				break
		var rarity_str = RARITY_NAMES.get(data.rarity, "")
		var text = equipped_mark + data.display_name + "  (" + rarity_str + " · " + FACTION_NAMES.get(data.faction, "") + ")"
		_item_list.add_item(text)
		_item_list.set_item_custom_fg_color(i, RARITY_COLORS.get(data.rarity, Color.WHITE))


## 刷新详情面板
func _refresh_detail() -> void:
	# 优先显示选中部件, 其次显示选中槽位已装备的部件
	var data = null
	if _selected_part_id != "":
		data = BodyPartManager.get_part_data(_selected_part_id)
	if data == null and _selected_slot >= 0:
		data = BodyPartManager.get_equipped_part(_selected_slot)

	if data == null:
		_name_label.text = "—"
		_name_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
		_source_label.text = ""
		_rarity_label.text = ""
		_faction_label.text = ""
		_desc_label.text = "选择左侧槽位或部件查看详情"
		_desc_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
		_stats_label.text = ""
		_san_label.text = ""
		_ability_label.text = ""
		_visual_label.text = ""
		_set_label.text = ""
		_equip_button.visible = false
		_unequip_button.visible = false
		return

	_name_label.text = data.display_name
	_name_label.add_theme_color_override("font_color", RARITY_COLORS.get(data.rarity, GameConstants.THEME_TEXT_LIGHT))
	_source_label.text = "来源神祇: " + data.deity_source
	_rarity_label.text = "稀有度: " + RARITY_NAMES.get(data.rarity, "")
	_rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(data.rarity, Color.WHITE))
	var faction_color = FACTION_COLORS.get(data.faction, GameConstants.THEME_TEXT_LIGHT)
	_faction_label.text = "流派: " + FACTION_NAMES.get(data.faction, "")
	_faction_label.add_theme_color_override("font_color", faction_color)
	_desc_label.text = data.description
	_desc_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_LIGHT)
	# 属性加成
	var stats_text = ""
	for stat_key in data.stat_bonuses:
		var stat_name = STAT_NAMES.get(stat_key, stat_key)
		var val = data.stat_bonuses[stat_key]
		var sign = "+" if float(val) >= 0 else ""
		if stat_key in ["attack_range", "move_speed", "spell_damage"]:
			stats_text += stat_name + ": " + sign + str(int(float(val) * 100)) + "%\n"
		else:
			stats_text += stat_name + ": " + sign + str(val) + "\n"
	_stats_label.text = stats_text if stats_text != "" else "无属性加成"
	# SAN污染
	var san_val = data.san_pollution_per_min
	if san_val > 0:
		_san_label.text = "SAN污染: " + str(san_val) + " / 分钟"
		_san_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_WARN)
	else:
		_san_label.text = "SAN污染: 无"
		_san_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_HEALTHY)
	# 能力解锁
	if data.unlock_ability != "":
		_ability_label.text = "解锁能力: " + data.unlock_ability
		_ability_label.add_theme_color_override("font_color", GameConstants.THEME_ACCENT_CYAN)
	elif data.unlock_terrain != "":
		_ability_label.text = "开启地形: " + data.unlock_terrain
		_ability_label.add_theme_color_override("font_color", GameConstants.THEME_ACCENT_CYAN)
	else:
		_ability_label.text = ""
	# 视觉畸变
	if data.visual_effect != "":
		_visual_label.text = "视觉畸变: " + data.visual_effect
		_visual_label.add_theme_color_override("font_color", GameConstants.THEME_TEXT_DIM)
	else:
		_visual_label.text = ""
	# 套装
	if data.set_id != "":
		_set_label.text = "所属套装: " + data.set_id
		_set_label.add_theme_color_override("font_color", GameConstants.THEME_ACCENT_GOLD)
	else:
		_set_label.text = ""
	# 按钮显示
	var is_equipped = false
	for slot in BodyPartManager.get_all_equipped():
		if BodyPartManager.get_all_equipped()[slot].id == data.id:
			is_equipped = true
			break
	_equip_button.visible = not is_equipped
	_unequip_button.visible = is_equipped
	# 装备按钮文本提示槽位
	if not is_equipped:
		var slot_name = SLOT_NAMES[data.slot]
		_equip_button.text = "装备到 " + slot_name


## 刷新底部状态
func _refresh_status() -> void:
	var used = BodyPartManager.get_used_slots()
	var max_slots = BodyPartManager.get_max_slots()
	_slot_used_label.text = "槽位: " + str(used) + " / " + str(max_slots)
	if BodyPartManager.is_overloaded():
		_overload_label.text = "⚠ 超载! SAN污染翻倍"
		_overload_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_DANGER)
	else:
		_overload_label.text = ""
	var san_pollution = BodyPartManager.get_total_san_pollution_per_min()
	if san_pollution > 0:
		_san_pollution_label.text = "SAN污染总量: " + str(san_pollution) + " / 分钟"
		if san_pollution > 1.0:
			_san_pollution_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_DANGER)
		else:
			_san_pollution_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_WARN)
	else:
		_san_pollution_label.text = "SAN污染: 无"
		_san_pollution_label.add_theme_color_override("font_color", GameConstants.THEME_SAN_HEALTHY)


## 选中槽位
func _on_slot_pressed(slot_idx: int) -> void:
	# 同槽位再次点击 = 取消筛选
	if _selected_slot == slot_idx:
		_selected_slot = -1
	else:
		_selected_slot = slot_idx
	_selected_part_id = ""
	_refresh_all()


## 选中部件
func _on_item_selected(index: int) -> void:
	var parts: Array[String]
	if _selected_slot >= 0:
		parts = BodyPartManager.get_owned_parts_for_slot(_selected_slot)
	else:
		parts = BodyPartManager.get_owned_parts()
	parts.sort_custom(func(a, b):
		var da = BodyPartManager.get_part_data(a)
		var db = BodyPartManager.get_part_data(b)
		return da.rarity > db.rarity
	)
	if index < parts.size():
		_selected_part_id = parts[index]
		_refresh_detail()


## 双击部件 = 直接装备
func _on_item_activated(index: int) -> void:
	_on_item_selected(index)
	_on_equip_pressed()


## 装备按钮
func _on_equip_pressed() -> void:
	if _selected_part_id == "":
		return
	var data = BodyPartManager.get_part_data(_selected_part_id)
	if data == null:
		return
	# 装备到部件对应槽位
	if BodyPartManager.equip_part(_selected_part_id, data.slot):
		_refresh_all()


## 卸下按钮
func _on_unequip_pressed() -> void:
	if _selected_part_id == "":
		return
	var data = BodyPartManager.get_part_data(_selected_part_id)
	if data == null:
		return
	# 找到装备的槽位卸下
	for slot in BodyPartManager.get_all_equipped():
		if BodyPartManager.get_all_equipped()[slot].id == _selected_part_id:
			BodyPartManager.unequip_part(slot)
			_refresh_all()
			return


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_B or event.keycode == KEY_ESCAPE or event.keycode == KEY_I:
			close()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# 右键卸下当前选中槽位的部件
			if _selected_slot >= 0 and BodyPartManager.get_equipped_part(_selected_slot) != null:
				BodyPartManager.unequip_part(_selected_slot)
				_refresh_all()
				get_viewport().set_input_as_handled()
