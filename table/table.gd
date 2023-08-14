extends Node

@export var opponent_scene: PackedScene

var opponent_positions = [Vector2(12, 383),\
                          Vector2(12, 195),\
                          Vector2(187, 14),\
                          Vector2(507, 8),\
                          Vector2(827, 14),\
                          Vector2(1002, 195),\
                          Vector2(1002, 383)]
var opponents = Array()

# Called when the node enters the scene tree for the first time.
func _ready():
    # TO-DO: Remove and set based on game state data from server
    GameProperties.total_game_balance = 1000

    # Set initial button labels and behavior
    $TableButton1.set_text("Call")
    $TableButton1.pressed.connect(do_call)
    $TableButton2.set_text("Raise")
    $TableButton2.pressed.connect(do_raise)
    $TableButton3.set_text("Fold")
    $TableButton3.pressed.connect(do_fold)
    $TableButton4.set_text("Settings")
    $TableButton4.pressed.connect(do_settings)

    # Create and initialize opponents
    for pos in opponent_positions:
        var op = opponent_scene.instantiate()
        op.position = pos
        opponents.append(op)
        add_child(op)

    opponents[1].set_cards(Vector2(6, 1), Vector2(1, 0))
    opponents[1].set_op_name("Jeremy")
    opponents[1].set_turn(true)
    opponents[1].set_balance(1234)
    opponents[1].set_status("All\nin")

    $Player.set_blind_button(PokerTypes.BUTTON_BIG_BLIND)
    $Player.set_cards(Vector2(1, 0), Vector2(6, 1))
    $Player.set_balance(1337)
    $Player.set_status("Bet $100")
    $Player.set_turn(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func do_call():
    print("call")
    opponents[1].clear_hand()
    $Player.clear_hand()
    $Pot.set_pot(1000)
    $CommunityCards.clear_cards()
    #get_window().mode = Window.MODE_WINDOWED

func do_raise():
    print("raise")
    opponents[1].deal_next()
    $Player.deal_next()
    $Pot.set_pot(0)
    $CommunityCards.show_flop(Vector2(9, 0), Vector2(10, 1), Vector2(11, 2))
    #get_window().mode = Window.MODE_FULLSCREEN

func do_fold():
    print("fold")
    #opponents[1].set_blind_button(PokerTypes.BUTTON_SMALL_BLIND)
    opponents[1].show_hand()
    $CommunityCards.show_turn(Vector2(12, 3))
    #get_window().size = Vector2(1920, 1080)

func do_settings():
    print("settings")
    #opponents[1].set_blind_button(PokerTypes.BUTTON_NONE)
    opponents[1].fold()
    $Player.fold()
    $CommunityCards.show_river(Vector2(0, 0))
    #get_window().size = Vector2(1280, 720)

func _on_help_button_pressed():
    print("help")

# "Brighten" help button when hovering over it
func _on_help_button_mouse_entered():
    $HelpButton.modulate = Color(1, 1, 1)

func _on_help_button_mouse_exited():
    $HelpButton.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)
