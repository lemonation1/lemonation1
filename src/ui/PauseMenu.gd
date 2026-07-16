extends Control

func _ready() -> void:
    $VBox/ResumeButton.pressed.connect(_on_resume)
    $VBox/SaveButton.pressed.connect(_on_save)
    $VBox/MainMenuButton.pressed.connect(_on_main_menu)

func _on_resume() -> void:
    GameManager.change_state(GameManager.GameState.PLAYING)
    queue_free()

func _on_save() -> void:
    SaveManager.save_game(0)
    EventBus.show_notification.emit("游戏已保存", 0)

func _on_main_menu() -> void:
    GameManager.change_state(GameManager.GameState.MAIN_MENU)
    get_tree().reload_current_scene()
