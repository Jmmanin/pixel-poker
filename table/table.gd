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
var current_player_turn

var min_raise
var previous_bet_made

func _ready():
    get_node('/root/Main/Networking').connect('do_start_game', _on_do_start_game)
    get_node('/root/Main/Networking').connect('continue_betting_round', _on_continue_betting_round)
    get_node('/root/Main/Networking').connect('start_new_betting_round', _on_start_new_betting_round)
    get_node('/root/Main/Networking').connect('end_game', _on_end_game)

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

func _on_do_start_game(opponent_order,
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

        op_scene.name = 'Opponent' + str(opponent_id)
        op_scene.set_op_name(player_info_dict[opponent_id]['player_name'])
        op_scene.set_balance(player_info_dict[opponent_id]['balance'])
        op_scene.set_status(player_info_dict[opponent_id]['status'])

        op_scene.position = OPPONENT_POSITIONS[num_opponents - 1][index]

        opponents.append(op_scene)
        add_child(op_scene)

        opponents_index_map[opponent_id] = index

        index += 1

    $Player.set_balance(player_info_dict[multiplayer.get_unique_id()]['balance'])
    $Player.set_status(player_info_dict[multiplayer.get_unique_id()]['status'])

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
    current_player_turn = deal_index
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
            current_player_turn = (big_blind_index + 1) if (big_blind_index + 1) < opponents.size() else -1
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
    deal_timer.name = 'HandDealTimer'
    deal_timer.autostart = true
    deal_timer.wait_time = 0.5
    deal_timer.timeout.connect(_on_hand_deal_timer_timeout)
    add_child(deal_timer)

func _on_hand_deal_timer_timeout():
    var to_be_dealt = opponents[deal_index] if deal_index >= 0 else $Player

    if to_be_dealt.is_full_dealt():
        var deal_timer = get_node('HandDealTimer')
        deal_timer.queue_free()

        # Once we are back around to the start of dealing a second time, the first round of betting can start
        # Highlight whose turn it is and enable betting buttons for self if it's our turn
        if current_player_turn >= 0:
            opponents[current_player_turn].set_turn(true)
        else:
            $Player.set_turn(true)
            $TableButton1.enable_button()
            $TableButton2.enable_button()
            $TableButton3.enable_button()
    else:
        to_be_dealt.deal_next()
        deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1

func _on_continue_betting_round(new_player_data, turn_player_id, new_pot, new_prev_bet_made, new_min_raise):
    for player_id in new_player_data:
        if player_id == multiplayer.get_unique_id():
            $Player.set_balance(new_player_data[player_id]['balance'])
            $Player.set_status(new_player_data[player_id]['status'])
        else:
            opponents[opponents_index_map[player_id]].set_balance(new_player_data[player_id]['balance'])
            opponents[opponents_index_map[player_id]].set_status(new_player_data[player_id]['status'])

            if new_player_data[player_id]['status'] == 'Fold':
                opponents[opponents_index_map[player_id]].fold()

    $Pot.set_pot(new_pot)

    if current_player_turn >= 0:
        opponents[current_player_turn].set_turn(false)
    else:
        $Player.set_turn(false)

    previous_bet_made = new_prev_bet_made
    if previous_bet_made:
        $TableButton1.set_text('Call')
        $TableButton2.set_text('Raise')
    else:
        $TableButton1.set_text('Check')
        $TableButton2.set_text('Bet')

    min_raise = new_min_raise

    current_player_turn = -1 if turn_player_id == multiplayer.get_unique_id() else opponents_index_map[turn_player_id]
    if current_player_turn >= 0:
        opponents[current_player_turn].set_turn(true)
    else:
        $Player.set_turn(true)
        $TableButton1.enable_button()
        $TableButton2.enable_button()
        $TableButton3.enable_button()

func _on_start_new_betting_round(new_player_data, turn_player_id, new_community_cards, new_pot, new_min_raise):
    # Sleep for a bit to let people see the final state of the last round of betting before clearing stuff out to prepare for the next one
    await get_tree().create_timer(0.75).timeout

    for player_id in new_player_data:
        if player_id == multiplayer.get_unique_id():
            $Player.set_balance(new_player_data[player_id]['balance'])
            $Player.set_status(new_player_data[player_id]['status'])
        else:
            opponents[opponents_index_map[player_id]].set_balance(new_player_data[player_id]['balance'])
            opponents[opponents_index_map[player_id]].set_status(new_player_data[player_id]['status'])

            if new_player_data[player_id]['status'] == 'Fold':
                opponents[opponents_index_map[player_id]].fold()

    $Pot.set_pot(new_pot)

    if current_player_turn >= 0:
        opponents[current_player_turn].set_turn(false)
    else:
        $Player.set_turn(false)

    previous_bet_made = false
    $TableButton1.set_text('Check')
    $TableButton2.set_text('Bet')

    min_raise = new_min_raise

    current_player_turn = -1 if turn_player_id == multiplayer.get_unique_id() else opponents_index_map[turn_player_id]

    $CommunityCards.add_cards(new_community_cards)

    # Create timer to handle deal animation
    var deal_timer = Timer.new()
    deal_timer.name = 'FlopDealTimer'
    deal_timer.wait_time = 0.75
    deal_timer.timeout.connect(_on_flop_deal_timer_timeout)
    add_child(deal_timer)

    _on_flop_deal_timer_timeout()

func _on_flop_deal_timer_timeout():
    var deal_timer = get_node('FlopDealTimer')

    if not $CommunityCards.is_full_dealt():
        $CommunityCards.deal_next()
        deal_timer.start()

    if $CommunityCards.is_full_dealt():
        deal_timer.queue_free()

        # Once all new community cards have been dealt the next betting round can begin
        if current_player_turn >= 0:
            opponents[current_player_turn].set_turn(true)
        else:
            $Player.set_turn(true)
            $TableButton1.enable_button()
            $TableButton2.enable_button()
            $TableButton3.enable_button()

func _on_end_game(end_game_table_data, end_game_results_data, player_pockets, lone_player_in_hand):
    $TableButton1.disable_button()
    $TableButton2.disable_button()
    $TableButton3.disable_button()
    $TableButton1.set_text('Results')
    $TableButton1.pressed.disconnect(_do_check_call)
    $TableButton1.pressed.connect(_on_results_button_pressed)
    $TableButton2.set_text('')
    $TableButton3.set_text('')

    var results_dialog = load("res://table/results_dialog.tscn").instantiate()
    results_dialog.name = 'ResultsDialog'
    results_dialog.set_results(end_game_results_data)
    add_child(results_dialog)

    if lone_player_in_hand:
        # Sleep for a bit to let people see the final state of the last round of betting before showing results
        await get_tree().create_timer(0.75).timeout

        # Go straight to results if there's only one player left in the hand (i.e. everyone else folded)
        results_dialog.visible = true
        $TableButton1.enable_button()
    else:
        for player_id in end_game_table_data:
            var new_status = end_game_table_data[player_id]['status']
            var folded = new_status == 'Fold'
            if player_id == multiplayer.get_unique_id():
                $Player.set_turn(false)
                $Player.set_status(new_status, folded)
                $Player.hand_indices = end_game_table_data[player_id]['hand_indices']
            else:
                opponents[opponents_index_map[player_id]].set_turn(false)
                opponents[opponents_index_map[player_id]].set_status(new_status, folded)
                opponents[opponents_index_map[player_id]].hand_indices = end_game_table_data[player_id]['hand_indices']
                if not folded:
                    opponents[opponents_index_map[player_id]].set_hand(player_pockets[player_id])

        # Set up reveals and get first hand to reveal
        var first_player_id = end_game_results_data[0]['id']
        deal_index = -1 if first_player_id == multiplayer.get_unique_id() else opponents_index_map[first_player_id]
        current_player_turn = -1 if first_player_id == multiplayer.get_unique_id() else opponents_index_map[first_player_id]
        while true:
            var revealed = $Player.revealed if deal_index == -1 else opponents[deal_index].revealed
            if revealed:
                deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1
            else:
                break

        # Create timer to handle reveal animation
        var reveal_timer = Timer.new()
        reveal_timer.name = 'HandRevealTimer'
        reveal_timer.autostart = true
        reveal_timer.wait_time = 0.75
        reveal_timer.timeout.connect(_on_hand_reveal_timer_timeout)
        add_child(reveal_timer)

func _on_hand_reveal_timer_timeout():
    var reveal_timer = get_node('HandRevealTimer')

    var revealed = $Player.revealed if deal_index == -1 else opponents[deal_index].revealed
    if revealed:
        reveal_timer.queue_free()
        get_node('ResultsDialog').visible = true
        $TableButton1.enable_button()
    else:
        if deal_index == -1:
            $Player.reveal_hand()
        else:
            opponents[deal_index].reveal_hand()

        deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1
        while true:
            revealed = $Player.revealed if deal_index == -1 else opponents[deal_index].revealed
            if not revealed or (deal_index == current_player_turn):
                reveal_timer.start()
                break
            else:
                deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1

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

    $Player.fold()

    emit_signal('send_player_action', -1)

func _do_settings():
    print('settings')

func _on_help_button_pressed():
    print('help')

func _on_results_button_pressed():
    get_node('ResultsDialog').visible = true

# 'Brighten' help button when hovering over it
func _on_help_button_mouse_entered():
    $HelpButton.modulate = Color(1, 1, 1)

func _on_help_button_mouse_exited():
    $HelpButton.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)
