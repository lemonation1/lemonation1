class_name UITheme
extends RefCounted
## UI主题工具 - 统一应用阴郁低调风格

static func make_panel_style(bg: Color = GameConstants.THEME_PANEL_BG, border: Color = GameConstants.THEME_PANEL_BORDER, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_top = 8
	s.content_margin_right = 10
	s.content_margin_bottom = 8
	return s

static func style_panel(panel: Panel, bg: Color = GameConstants.THEME_PANEL_BG, border: Color = GameConstants.THEME_PANEL_BORDER, radius: int = 8) -> void:
	panel.add_theme_stylebox_override("panel", make_panel_style(bg, border, radius))

static func style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = GameConstants.THEME_PANEL_BG
	normal.border_color = GameConstants.THEME_PANEL_BORDER
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 16
	normal.content_margin_top = 10
	normal.content_margin_right = 16
	normal.content_margin_bottom = 10

	var hover := normal.duplicate()
	hover.bg_color = GameConstants.THEME_PANEL_HOVER
	hover.border_color = GameConstants.THEME_ACCENT_GOLD

	var pressed := normal.duplicate()
	pressed.bg_color = GameConstants.THEME_BG_LIGHT
	pressed.border_color = GameConstants.THEME_ACCENT_CYAN

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.1, 0.1, 0.15, 0.5)
	disabled.border_color = Color(0.2, 0.2, 0.3, 0.5)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", GameConstants.THEME_TEXT_LIGHT)
	btn.add_theme_color_override("font_hover_color", GameConstants.THEME_TEXT_ACCENT)
	btn.add_theme_color_override("font_disabled_color", GameConstants.THEME_TEXT_DIM)

static func style_label(label: Label, color: Color = GameConstants.THEME_TEXT_LIGHT, shadow: bool = true) -> void:
	label.add_theme_color_override("font_color", color)
	if shadow:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

static func make_bar_styles(fill_color: Color) -> Dictionary:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.14, 0.9)
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(1)
	bg.border_color = GameConstants.THEME_PANEL_BORDER

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(5)

	return {"background": bg, "fill": fill}

## 为 Control 及其子节点应用淡入动画
static func fade_in(control: Control, duration: float = 0.3, delay: float = 0.0) -> void:
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(control, "modulate:a", 1.0, duration)
