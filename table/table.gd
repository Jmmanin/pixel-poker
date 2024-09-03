extends Node

signal change_scene

const OPPONENT_POSITIONS = [[Vector2(507, 8)],
                            [Vector2(187, 14), Vector2(827, 14)],
                            [Vector2(12, 195), Vector2(507, 8),  Vector2(827, 14)],
                            [Vector2(12, 383), Vector2(187, 14), Vector2(827, 14), Vector2(1002, 383)],
                            [Vector2(12, 383), Vector2(187, 14), Vector2(507, 8),  Vector2(827, 14), Vector2(1002, 383)],
                            [Vector2(12, 383), Vector2(12, 195), Vector2(187, 14), Vector2(827, 14), Vector2(1002, 195), Vector2(1002, 383)],
                            [Vector2(12, 383), Vector2(12, 195), Vector2(187, 14), Vector2(507, 8),  Vector2(827, 14),   Vector2(1002, 195), Vector2(1002, 383)]]

var opponents = Array()
var opponents_index_map = {}

func _ready():
    get_node('/root/Main/Networking').connect('set_table_players', _on_set_table_players)

    # Set initial button labels and behavior
    $TableButton1.set_text('Check')
    $TableButton1.disable_button()
    $TableButton1.pressed.connect(do_check)

    $TableButton2.set_text('Bet')
    $TableButton2.disable_button()
    $TableButton2.pressed.connect(do_bet)

    $TableButton3.set_text('Fold')
    $TableButton3.disable_button()
    $TableButton3.pressed.connect(do_fold)

    $TableButton4.set_text('Settings')
    $TableButton4.pressed.connect(do_settings)

func _on_set_table_players(opponent_ids, opponent_names, starting_balance):
    var opponent_scene = load('res://table/opponent.tscn')
    var num_opponents = opponent_ids.size()
    var index = 0
    for opponent_id in opponent_ids:
        var op_scene = opponent_scene.instantiate()
        op_scene.set_op_name(opponent_names[opponent_id])
        op_scene.set_balance(starting_balance)
        op_scene.position = OPPONENT_POSITIONS[num_opponents - 1][index]
        opponents.append(op_scene)
        add_child(op_scene)
        opponents_index_map[opponent_id] = index
        index += 1

    $Player.set_balance(starting_balance)

func do_check():
    print('check')

func do_bet():
    print('bet')

func do_call():
    print('call')
    opponents[1].clear_hand()
    $Player.clear_hand()
    $Pot.set_pot(1000)
    $CommunityCards.clear_cards()
    #get_window().mode = Window.MODE_WINDOWED

func do_raise():
    print('raise')
    opponents[1].deal_next()
    $Player.deal_next()
    $Pot.set_pot(0)
    $CommunityCards.show_flop(Vector2(9, 0), Vector2(10, 1), Vector2(11, 2))
    #get_window().mode = Window.MODE_FULLSCREEN

func do_fold():
    print('fold')
    #opponents[1].set_blind_button(PokerTypes.BlindButtons.BUTTON_SMALL_BLIND)
    opponents[1].show_hand()
    $CommunityCards.show_turn(Vector2(12, 3))
    #get_window().size = Vector2(1920, 1080)

func do_settings():
    print('settings')
    #opponents[1].set_blind_button(PokerTypes.BlindButtons.BUTTON_NONE)
    opponents[1].fold()
    $Player.fold()
    $CommunityCards.show_river(Vector2(0, 0))
    #get_window().size = Vector2(1280, 720)

func _on_help_button_pressed():
    print('help')

# 'Brighten' help button when hovering over it
func _on_help_button_mouse_entered():
    $HelpButton.modulate = Color(1, 1, 1)

func _on_help_button_mouse_exited():
    $HelpButton.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)
