extends Node

signal change_scene
signal send_player_action

const OPPONENT_POSITIONS = [[Vector2(507, 8)],
                            [Vector2(187, 14), Vector2(827, 14)],
                            [Vector2(12, 195), Vector2(507, 8),  Vector2(1002, 195)],
                            [Vector2(12, 383), Vector2(187, 14), Vector2(827, 14), Vector2(1002, 383)],
                            [Vector2(12, 383), Vector2(187, 14), Vector2(507, 8),  Vector2(827, 14), Vector2(1002, 383)],
                            [Vector2(12, 383), Vector2(12, 195), Vector2(187, 14), Vector2(827, 14), Vector2(1002, 195), Vector2(1002, 383)],
                            [Vector2(12, 383), Vector2(12, 195), Vector2(187, 14), Vector2(507, 8),  Vector2(827, 14),   Vector2(1002, 195), Vector2(1002, 383)]]

var opponents = Array()
var opponents_index_map = {}

var deal_index
var min_raise
var starting_bet_index
var previous_bet_made

func _ready():
    get_node('/root/Main/Networking').connect('set_table_players', _on_set_table_players)

    connect('send_player_action', get_node('/root/Main/Networking')._on_send_player_action)

    # Set initial button labels and behavior
    $TableButton1.set_text('Check')
    $TableButton1.disable_button()
    $TableButton1.pressed.connect(_do_check_call)

    $TableButton2.set_text('Bet')
    $TableButton2.disable_button()
    $TableButton2.pressed.connect(_do_bet_raise)

    $TableButton3.set_text('Fold')
    $TableButton3.disable_button()
    $TableButton3.pressed.connect(_do_fold)

    $TableButton4.set_text('Settings')
    $TableButton4.pressed.connect(_do_settings)

func _on_set_table_players(opponent_order,
                           player_info_dict,
                           player_hand,
                           prebet_type,
                           dealer_id,
                           starting_pot,
                           starting_min_raise):
    var opponent_scene = load('res://table/opponent.tscn')
    var num_opponents = opponent_order.size()
    var index = 0
    for opponent_id in opponent_order:
        var op_scene = opponent_scene.instantiate()

        op_scene.set_op_name(player_info_dict[opponent_id]['player_name'])
        op_scene.set_balance(player_info_dict[opponent_id]['balance'])
        op_scene.set_status(player_info_dict[opponent_id]['status'])

        op_scene.position = OPPONENT_POSITIONS[num_opponents - 1][index]

        opponents.append(op_scene)
        add_child(op_scene)

        opponents_index_map[opponent_id] = index

        index += 1

    $Player.set_balance(player_info_dict[multiplayer.get_unique_id()]['balance'])

    # Clear out blind buttons
    $Player.set_blind_button(PokerTypes.BlindButtons.BB_NONE)
    for opponent in opponents:
        opponent.set_blind_button(PokerTypes.BlindButtons.BB_NONE)

    # Get dealer index from id (-1 = player is dealer)
    var dealer_index = -1 if multiplayer.get_unique_id() == dealer_id else opponents_index_map[dealer_id]
    if dealer_index >= 0:
        opponents[dealer_index].set_blind_button(PokerTypes.BlindButtons.BB_DEALER)
    else:
        $Player.set_blind_button(PokerTypes.BlindButtons.BB_DEALER)

    # Person next to dealer is where dealing starts
    # Index should wraparound to the player (-1) after the last opponent
    deal_index = (dealer_index + 1) if (dealer_index + 1) < opponents.size() else -1

    # Betting starts with person next to dealer in ante games or 2-player blind games
    starting_bet_index = deal_index
    previous_bet_made = (prebet_type == PokerTypes.PrebetTypes.PB_BLIND)

    # Set blind buttons and starting action buttons for blind games (table already set up for ante games)
    if prebet_type == PokerTypes.PrebetTypes.PB_BLIND:
        $TableButton1.set_text('Call')
        $TableButton2.set_text('Raise')

        if opponents.size() > 1:
            # deal_index (the person next to the dealer) is the small blind
            if deal_index >= 0:
                opponents[deal_index].set_blind_button(PokerTypes.BlindButtons.BB_SMALL_BLIND)
            else:
                $Player.set_blind_button(PokerTypes.BlindButtons.BB_SMALL_BLIND)

            var big_blind_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1
            if big_blind_index >= 0:
                opponents[big_blind_index].set_blind_button(PokerTypes.BlindButtons.BB_BIG_BLIND)
            else:
                $Player.set_blind_button(PokerTypes.BlindButtons.BB_BIG_BLIND)

            # Betting starts with person next to big blind in blind games with 3+ players
            starting_bet_index = (big_blind_index + 1) if (big_blind_index + 1) < opponents.size() else -1
        else:
            # In a one-on-one game, the dealer also has the small blind while the other player has the big blind
            if dealer_index == -1:
                opponents[0].set_blind_button(PokerTypes.BlindButtons.BB_BIG_BLIND)
            else:
                $Player.set_blind_button(PokerTypes.BlindButtons.BB_BIG_BLIND)

    $Player.set_hand(player_hand)

    $Pot.set_pot(starting_pot)
    min_raise = starting_min_raise

    # Create timer to handle deal animation
    var deal_timer = Timer.new()
    deal_timer.name = 'DealTimer'
    deal_timer.autostart = true
    deal_timer.wait_time = 0.5
    deal_timer.timeout.connect(_on_deal_timer_timeout)
    add_child(deal_timer)

func _on_deal_timer_timeout():
    var to_be_dealt = opponents[deal_index] if deal_index >= 0 else $Player

    if not to_be_dealt.get_full_dealt():
        to_be_dealt.deal_next()
        deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1
    else:
        var deal_timer = get_node('DealTimer')
        if deal_timer:
            deal_timer.queue_free()

        # Once we are back around to the start of dealing a second time, the first round of betting can start
        # Highlight whose turn it is and enable betting buttons for self if it's our turn
        if starting_bet_index >= 0:
            opponents[starting_bet_index].set_turn(true)
        else:
            $Player.set_turn(true)
            $TableButton1.enable_button()
            $TableButton2.enable_button()
            $TableButton3.enable_button()

func _do_check_call():
    $TableButton1.disable_button()
    $TableButton2.disable_button()
    $TableButton3.disable_button()

    emit_signal('send_player_action', 0)

func _do_bet_raise():
    $TableButton1.visible = false
    $TableBetEntry/ValueLineEdit.text = str(min_raise)
    $TableButton2.set_text('Confirm')
    $TableButton2.pressed.disconnect(_do_bet_raise)
    $TableButton2.pressed.connect(_do_confirm)
    $TableButton3.set_text('Cancel')
    $TableButton3.pressed.disconnect(_do_fold)
    $TableButton3.pressed.connect(_do_cancel)

func _do_confirm():
    var amount = int($TableBetEntry/ValueLineEdit.text)

    if amount >= min_raise and amount <= $Player.balance:
        _do_cancel()
        $TableButton1.disable_button()
        $TableButton2.disable_button()
        $TableButton3.disable_button()

        emit_signal('send_player_action', int($TableBetEntry/ValueLineEdit.text))
    else:
        pass # TO-DO - Figure out way to alert player of invalid bet!

func _do_cancel():
    $TableButton1.visible = true
    
    $TableButton2.pressed.disconnect(_do_confirm)
    $TableButton2.pressed.connect(_do_bet_raise)
    if previous_bet_made:
        $TableButton2.set_text('Raise')
    else:
        $TableButton2.set_text('Bet')

    $TableButton3.set_text('Fold')
    $TableButton3.pressed.disconnect(_do_cancel)
    $TableButton3.pressed.connect(_do_fold)

func _do_fold():
    $TableButton1.disable_button()
    $TableButton2.disable_button()
    $TableButton3.disable_button()

    emit_signal('send_player_action', -1)

func _do_settings():
    print('settings')

func _on_help_button_pressed():
    print('help')

# 'Brighten' help button when hovering over it
func _on_help_button_mouse_entered():
    $HelpButton.modulate = Color(1, 1, 1)

func _on_help_button_mouse_exited():
    $HelpButton.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)
