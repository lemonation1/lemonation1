extends Control

func _ready() -> void:
    $VBox/RetryButton.pressed.connect(_on_retry)
    $VBox/MainMenuButton.pressed.connect(_on_main_menu)

func _on_retry() -> void:
    get_tree().reload_current_scene()

func _on_main_menu() -> void:
    get_tree().reload_current_scene()
