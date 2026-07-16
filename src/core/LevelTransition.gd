extends CanvasLayer
## 关卡转场 - 淡入淡出效果
## 用法: LevelTransition.transition_to(scene_path) 或 LevelTransition.fade_in() / fade_out()

signal transition_finished

var _overlay: ColorRect
var _tween: Tween
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0.02, 0.02, 0.04, 0.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


## 淡入到黑屏，执行回调，再淡出
func transition_to(scene_path: String, delay: float = 0.3) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	fade_in(delay)
	await transition_finished

	# 切换场景
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("场景加载失败: " + scene_path)

	# 等待一帧确保场景初始化
	await get_tree().process_frame
	fade_out(delay)
	_is_transitioning = false


## 带回调的转场
func transition_with_callback(callback: Callable, delay: float = 0.3) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	fade_in(delay)
	await transition_finished
	callback.call()
	await get_tree().process_frame
	fade_out(delay)
	_is_transitioning = false


## 淡入到黑屏
func fade_in(duration: float = 0.3) -> void:
	if _tween:
		_tween.kill()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 拦截输入
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, duration)
	_tween.tween_callback(func(): transition_finished.emit())


## 从黑屏淡出
func fade_out(duration: float = 0.3) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 0.0, duration)
	_tween.tween_callback(func():
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)
