extends Control

@onready var _start_button: Button = $VBox/StartButton
@onready var _continue_button: Button = $VBox/ContinueButton
@onready var _quit_button: Button = $VBox/QuitButton
@onready var _title: Label = $VBox/Title

func _ready() -> void:
    _start_button.pressed.connect(_on_start)
    _continue_button.pressed.connect(_on_continue)
    _quit_button.pressed.connect(_on_quit)
    _continue_button.disabled = not SaveManager.has_save(0)

func _on_start() -> void:
    var main = get_tree().current_scene
    if main.has_method("start_game"):
        main.start_game()

func _on_continue() -> void:
    if SaveManager.load_game(0):
        var main = get_tree().current_scene
        if main.has_method("start_game"):
            main.start_game()

func _on_quit() -> void:
    get_tree().quit()
