extends Node

@warning_ignore("unused_signal") # TO-DO - Figure out how to resolve this warning
signal change_scene
signal send_player_action

var button_action_map = {PokerTypes.ButtonActions.BA_CHECK : _do_check_call,
                         PokerTypes.ButtonActions.BA_CALL : _do_check_call,
                         PokerTypes.ButtonActions.BA_BET : _do_bet_raise,
                         PokerTypes.ButtonActions.BA_RAISE : _do_bet_raise,
                         PokerTypes.ButtonActions.BA_CONFIRM : _do_confirm,
                         PokerTypes.ButtonActions.BA_CANCEL : _do_cancel,
                         PokerTypes.ButtonActions.BA_ALL_IN : _do_all_in,
                         PokerTypes.ButtonActions.BA_FOLD : _do_fold,
                         PokerTypes.ButtonActions.BA_SETTINGS : _do_settings,
                         PokerTypes.ButtonActions.BA_RESULTS : _do_results}

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
var curr_bet
var starting_curr_bet

func _ready():
    get_node('/root/Main/Networking').connect('do_start_game', _on_do_start_game)
    get_node('/root/Main/Networking').connect('update_table_data', _on_update_table_data)
    get_node('/root/Main/Networking').connect('continue_betting_round', _on_continue_betting_round)
    get_node('/root/Main/Networking').connect('start_new_betting_round', _on_start_new_betting_round)
    get_node('/root/Main/Networking').connect('end_game', _on_end_game)

    connect('send_player_action', get_node('/root/Main/Networking')._on_send_player_action)

    update_button_action($TableButton4, PokerTypes.ButtonActions.BA_SETTINGS)

func _on_do_start_game(opponent_order,
                       player_info_dict,
                       player_hand,
                       prebet_type,
                       dealer_id,
                       starting_pots,
                       starting_curr_bet,
                       starting_min_raise,
                       total_game_balance):
    # Set starting pot and starting betting state
    $Pot.total_game_balance = total_game_balance
    $Pot.set_pots(starting_pots)

    current_player_turn = deal_index

    min_raise = starting_min_raise
    curr_bet = starting_curr_bet
    self.starting_curr_bet = starting_curr_bet

    # Create opponents
    var opponent_scene = load('res://table/opponent.tscn')
    var num_opponents = opponent_order.size()
    var index = 0
    for opponent_id in opponent_order:
        var op_scene = opponent_scene.instantiate()

        op_scene.name = 'Opponent' + str(opponent_id)
        op_scene.set_op_name(player_info_dict[opponent_id]['player_name'])
        op_scene.total_game_balance = total_game_balance
        op_scene.set_balance(player_info_dict[opponent_id]['balance'])
        op_scene.set_status(player_info_dict[opponent_id]['status'])

        op_scene.position = OPPONENT_POSITIONS[num_opponents - 1][index]

        opponents.append(op_scene)
        add_child(op_scene)

        opponents_index_map[opponent_id] = index

        index += 1

    # Initialize player data
    $Player.total_game_balance = total_game_balance
    $Player.set_balance(player_info_dict[multiplayer.get_unique_id()]['balance'])
    $Player.set_status(player_info_dict[multiplayer.get_unique_id()]['status'])
    $Player.set_hand(player_hand)

    # Get dealer index from id (-1 = player is dealer)
    var dealer_index = -1 if multiplayer.get_unique_id() == dealer_id else opponents_index_map[dealer_id]
    if dealer_index >= 0:
        opponents[dealer_index].set_blind_button(PokerTypes.BlindButtons.BB_DEALER)
    else:
        $Player.set_blind_button(PokerTypes.BlindButtons.BB_DEALER)

    # Person next to dealer is where dealing starts
    # Index should wraparound to the player (-1) after the last opponent
    # Betting starts with person next to dealer in ante games or 2-player blind games
    deal_index = (dealer_index + 1) if (dealer_index + 1) < opponents.size() else -1

    # Set blind buttons and starting action buttons for blind games (table already set up for ante games)
    # TO-DO - Handle case where player is all-in at the start
    if prebet_type == PokerTypes.PrebetTypes.PB_BLIND:
        if opponents.size() > 1:
            # The person next to the dealer is the small blind
            if deal_index >= 0:
                opponents[deal_index].set_blind_button(PokerTypes.BlindButtons.BB_SMALL_BLIND)
            else:
                $Player.set_blind_button(PokerTypes.BlindButtons.BB_SMALL_BLIND)

            # The person next to small blind is the big blind
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

            # Button actions depend on whether or not a bet has already been made (blind game),
            # or if no bet has been made yet (ante game).
            # - For blind games, if the player cannot afford the blind, they must go all-in or fold
            if curr_bet > 0:
                if (curr_bet < $Player.balance):
                    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CALL)
                    update_button_action($TableButton2, PokerTypes.ButtonActions.BA_RAISE)
                else:
                    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_ALL_IN)
                    # Leave button 2 with no action
            else:
                update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CHECK)
                update_button_action($TableButton2, PokerTypes.ButtonActions.BA_BET)

            update_button_action($TableButton3, PokerTypes.ButtonActions.BA_FOLD)
    else:
        to_be_dealt.deal_next()
        deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1

func _on_update_table_data(new_player_data, new_pots):
    # Update player and game state data
    for player_id in new_player_data:
        if player_id == multiplayer.get_unique_id():
            $Player.set_balance(new_player_data[player_id]['balance'])
            $Player.set_status(new_player_data[player_id]['status'])
        else:
            opponents[opponents_index_map[player_id]].set_balance(new_player_data[player_id]['balance'])
            opponents[opponents_index_map[player_id]].set_status(new_player_data[player_id]['status'])

            # Fold opponent if that is their new state. Player fold is handled within this scene
            if new_player_data[player_id]['status'] == 'Fold':
                opponents[opponents_index_map[player_id]].fold()

    $Pot.set_pots(new_pots)

func _on_continue_betting_round(turn_player_id, new_curr_bet, new_min_raise):
    curr_bet = new_curr_bet
    min_raise = new_min_raise

    # Clear previous player turn
    var cur_player = opponents[current_player_turn] if current_player_turn >= 0 else $Player
    cur_player.set_turn(false)

    # Update player turn
    current_player_turn = -1 if turn_player_id == multiplayer.get_unique_id() else opponents_index_map[turn_player_id]
    cur_player = opponents[current_player_turn] if current_player_turn >= 0 else $Player
    cur_player.set_turn(true)

    # Enable buttons if it's our turn
    if current_player_turn == -1:
        # Button actions depend on whether or not a bet has already been made
        # - If the player cannot afford the current bet, they must go all-in or fold
        if curr_bet > 0:
            if (curr_bet < $Player.balance):
                # A player "calls" only if their current bet does not match the current bet
                # If the big blind player does not wish to bet more than the big blind,
                # they "check" instead of checking.
                if     (curr_bet == starting_curr_bet) \
                   and ($Player.blind_button_value == PokerTypes.BlindButtons.BB_BIG_BLIND) \
                   and ($CommunityCards.cards_dealt == -1):
                    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CHECK)
                else:
                    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CALL)
                update_button_action($TableButton2, PokerTypes.ButtonActions.BA_RAISE)
            else:
                update_button_action($TableButton1, PokerTypes.ButtonActions.BA_ALL_IN)
                # Leave button 2 with no action
        else:
            update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CHECK)
            update_button_action($TableButton2, PokerTypes.ButtonActions.BA_BET)

        update_button_action($TableButton3, PokerTypes.ButtonActions.BA_FOLD)

func _on_start_new_betting_round(new_player_data, turn_player_id, new_community_cards, new_min_raise):
    # Sleep for a bit to let people see the final state of the last round of betting before clearing stuff out to prepare for the next one
    await get_tree().create_timer(0.75).timeout

    # Update player and game state data
    for player_id in new_player_data:
        if player_id == multiplayer.get_unique_id():
            $Player.set_balance(new_player_data[player_id]['balance'])
            $Player.set_status(new_player_data[player_id]['status'])
        else:
            opponents[opponents_index_map[player_id]].set_balance(new_player_data[player_id]['balance'])
            opponents[opponents_index_map[player_id]].set_status(new_player_data[player_id]['status'])

    $CommunityCards.add_cards(new_community_cards)

    curr_bet = 0
    min_raise = new_min_raise

    # Clear previous player turn
    var cur_player = opponents[current_player_turn] if current_player_turn >= 0 else $Player
    cur_player.set_turn(false)

    # Set new player turn
    current_player_turn = -1 if turn_player_id == multiplayer.get_unique_id() else opponents_index_map[turn_player_id]

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

            # Button actions depend on whether or not a bet has already been made
            # - If the player cannot afford the current bet, they must go all-in or fold
            if curr_bet > 0:
                if (curr_bet < $Player.balance):
                    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CALL)
                    update_button_action($TableButton2, PokerTypes.ButtonActions.BA_RAISE)
                else:
                    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_ALL_IN)
                    # Leave button 2 with no action
            else:
                update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CHECK)
                update_button_action($TableButton2, PokerTypes.ButtonActions.BA_BET)

            update_button_action($TableButton3, PokerTypes.ButtonActions.BA_FOLD)

func _on_end_game(end_game_table_data, end_game_results_data, player_pockets, lone_player_in_hand):
    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_RESULTS)

    var results_dialog = load("res://table/results_dialog.tscn").instantiate()
    results_dialog.name = 'ResultsDialog'
    results_dialog.set_results(end_game_results_data)
    add_child(results_dialog)

    if lone_player_in_hand:
        # Sleep for a bit to let people see the final state of the last round of betting before showing results
        await get_tree().create_timer(0.75).timeout

        # Go straight to results if there's only one player left in the hand (i.e. everyone else folded)
        results_dialog.visible = true
    else:
        for player_id in end_game_table_data:
            var new_status = end_game_table_data[player_id]['status']
            var folded = (new_status == 'Fold')
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
    else:
        if deal_index == -1:
            $Player.reveal_hand()
            $Player/StatusBlock.mouse_entered.connect(_on_mouse_entered_player)
            $Player/StatusBlock.mouse_exited.connect(_on_mouse_exited_player)
        else:
            opponents[deal_index].reveal_hand()
            opponents[deal_index].mouse_entered.connect(_on_mouse_entered_opponent.bind(deal_index))
            opponents[deal_index].mouse_exited.connect(_on_mouse_exited_opponent.bind(deal_index))

        deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1
        while true:
            revealed = $Player.revealed if deal_index == -1 else opponents[deal_index].revealed
            if not revealed or (deal_index == current_player_turn):
                reveal_timer.start()
                break
            else:
                deal_index = (deal_index + 1) if (deal_index + 1) < opponents.size() else -1

func _on_mouse_entered_player():
    for card_index in $Player.hand_indices:
        if card_index < 2:
            $Player.highlight_card(card_index + 1) # Normalize to player pocket card 1 or 2
        else:
            $CommunityCards.highlight_card(card_index - 1) # Normalize to community cards 1-5

func _on_mouse_exited_player():
    $Player.clear_card_highlighting()
    $CommunityCards.clear_card_highlighting()

func _on_mouse_entered_opponent(index):
    for card_index in opponents[index].hand_indices:
        if card_index < 2:
            opponents[index].highlight_card(card_index + 1) # Normalize to player pocket card 1 or 2
        else:
            $CommunityCards.highlight_card(card_index - 1) # Normalize to community cards 1-5

func _on_mouse_exited_opponent(index):
    opponents[index].clear_card_highlighting()
    $CommunityCards.clear_card_highlighting()

func update_button_action(button, action):
    if button.current_action != PokerTypes.ButtonActions.BA_NONE:
        button.pressed.disconnect(button_action_map[button.current_action])

    button.set_action(action)

    if action != PokerTypes.ButtonActions.BA_NONE:
        button.pressed.connect(button_action_map[action])

func _do_check_call():
    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_NONE)
    update_button_action($TableButton2, PokerTypes.ButtonActions.BA_NONE)
    update_button_action($TableButton3, PokerTypes.ButtonActions.BA_NONE)

    send_player_action.emit(0)

func _do_bet_raise():
    $TableButton1.visible = false
    $TableBetEntry/ValueLineEdit.text = str(min_raise)

    update_button_action($TableButton2, PokerTypes.ButtonActions.BA_CONFIRM)
    update_button_action($TableButton3, PokerTypes.ButtonActions.BA_CANCEL)
    update_button_action($TableButton4, PokerTypes.ButtonActions.BA_ALL_IN)

func _do_confirm():
    var amount = int($TableBetEntry/ValueLineEdit.text)

    if (amount > 0) and (amount <= $Player.balance) and ((amount >= min_raise) or (amount == $Player.balance)):
        update_button_action($TableButton1, PokerTypes.ButtonActions.BA_NONE)
        update_button_action($TableButton2, PokerTypes.ButtonActions.BA_NONE)
        update_button_action($TableButton3, PokerTypes.ButtonActions.BA_NONE)
        update_button_action($TableButton4, PokerTypes.ButtonActions.BA_SETTINGS)
        $TableButton1.visible = true

        send_player_action.emit(amount)
    else:
        $TableBetEntry/ValueLineEdit.text = 'Invalid'

func _do_cancel():
    $TableButton1.visible = true

    if (curr_bet >= $Player.balance):
        update_button_action($TableButton1, PokerTypes.ButtonActions.BA_ALL_IN)
        update_button_action($TableButton2, PokerTypes.ButtonActions.BA_NONE)
    elif curr_bet > 0:
        update_button_action($TableButton2, PokerTypes.ButtonActions.BA_RAISE)
    else:
        update_button_action($TableButton1, PokerTypes.ButtonActions.BA_CHECK)
        update_button_action($TableButton2, PokerTypes.ButtonActions.BA_BET)

    update_button_action($TableButton3, PokerTypes.ButtonActions.BA_FOLD)
    update_button_action($TableButton4, PokerTypes.ButtonActions.BA_SETTINGS)

func _do_all_in():
    $TableButton1.visible = false
    $TableBetEntry/ValueLineEdit.text = str($Player.balance)

    update_button_action($TableButton2, PokerTypes.ButtonActions.BA_CONFIRM)
    update_button_action($TableButton3, PokerTypes.ButtonActions.BA_CANCEL)

func _do_fold():
    update_button_action($TableButton1, PokerTypes.ButtonActions.BA_NONE)
    update_button_action($TableButton2, PokerTypes.ButtonActions.BA_NONE)
    update_button_action($TableButton3, PokerTypes.ButtonActions.BA_NONE)

    $Player.fold()

    send_player_action.emit(-1)

func _do_settings():
    print('settings')

func _do_results():
    get_node('ResultsDialog').visible = true

# 'Brighten' help button when hovering over it
func _on_help_button_mouse_entered():
    $HelpButton.modulate = Color(1, 1, 1)

func _on_help_button_mouse_exited():
    $HelpButton.modulate = Color(95.0/255.0, 95.0/255.0, 95.0/255.0)

func _on_help_button_pressed():
    print('help')
