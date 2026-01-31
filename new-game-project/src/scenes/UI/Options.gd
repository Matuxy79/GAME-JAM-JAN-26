extends PopupPanel

@onready var btn_easy := $VBox/Easy
@onready var btn_medium := $VBox/Medium
@onready var btn_hard := $VBox/Hard
@onready var btn_close := $VBox/Close

func _ready():
    if btn_easy:
        btn_easy.pressed.connect(_on_easy_pressed)
    if btn_medium:
        btn_medium.pressed.connect(_on_medium_pressed)
    if btn_hard:
        btn_hard.pressed.connect(_on_hard_pressed)
    if btn_close:
        btn_close.pressed.connect(_on_close_pressed)

func _on_easy_pressed():
    if Engine.has_singleton("BalanceDB"):
        var balance = Engine.get_singleton("BalanceDB")
        if balance.has_method("set_difficulty"):
            balance.set_difficulty("easy")
    hide()

func _on_medium_pressed():
    if Engine.has_singleton("BalanceDB"):
        var balance = Engine.get_singleton("BalanceDB")
        if balance.has_method("set_difficulty"):
            balance.set_difficulty("medium")
    hide()

func _on_hard_pressed():
    if Engine.has_singleton("BalanceDB"):
        var balance = Engine.get_singleton("BalanceDB")
        if balance.has_method("set_difficulty"):
            balance.set_difficulty("hard")
    hide()

func _on_close_pressed():
    hide()
