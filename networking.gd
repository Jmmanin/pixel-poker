extends Node

signal change_scene
signal player_connected
signal player_disconnected
signal set_game_info
signal update_player_ready
signal do_start_lobby_countdown
signal do_stop_lobby_countdown
signal do_start_game
signal continue_betting_round
signal start_new_betting_round
signal end_game

var self_host_data : host_data = null # Only used if self-hosting

func _ready():
    multiplayer.peer_disconnected.connect(_on_player_disconnected)

    connect('change_scene', get_node('/root/Main/Scene_Switcher')._on_change_scene)

func _on_init_self_host(game_info,
                        player_name):
    self_host_data = host_data.new(game_info)

    var my_id = multiplayer.get_unique_id()
    self_host_data.add_player(multiplayer.get_unique_id(), player_name)

    # Add self to lobby scene
    emit_signal('change_scene', 'lobby')
    emit_signal('set_game_info', self_host_data.game_info)
    emit_signal('player_connected', self_host_data.get_player_lobby_data(my_id))

func _do_join_request(game_name, game_pw, player_name):
    join_request.rpc_id(1, game_name, game_pw, player_name)

@rpc('any_peer', 'call_remote', "reliable")
func join_request(joiner_game_name, joiner_game_pw, joiner_name):
    var new_player_id = multiplayer.get_remote_sender_id()
    var success = self_host_data.process_join_request(joiner_game_name, joiner_game_pw, new_player_id, joiner_name)

    if success:
        if self_host_data.game_starting:
            self_host_data.game_starting = false
            stop_lobby_countdown.rpc()

        emit_signal('player_connected', self_host_data.get_player_lobby_data(new_player_id))

        enter_lobby.rpc_id(new_player_id, self_host_data.game_info.to_dict())
        add_new_players.rpc(new_player_id, self_host_data.get_players_lobby_data())
    else:
        pass

@rpc('authority', 'call_remote', 'reliable')
func enter_lobby(game_info_dict):
    emit_signal('change_scene', 'lobby')
    emit_signal('set_game_info', game_info_dict)

@rpc('authority', 'call_remote', 'reliable')
func add_new_players(new_player_id, player_info_dict):
    # Set up newly joined player with existing players
    if new_player_id == multiplayer.get_unique_id():
        emit_signal('player_connected', player_info_dict)
    # Players who already joined just need to add newly joined player
    else:
        emit_signal('player_connected', {new_player_id : player_info_dict[new_player_id]})

func _on_update_ready(new_ready):
    if multiplayer.is_server():
        server_process_new_ready(new_ready)
    else:
        server_process_new_ready.rpc_id(1, new_ready)

@rpc('any_peer', 'call_remote', 'reliable')
func server_process_new_ready(new_ready):
    var player_id = 1 if (multiplayer.get_remote_sender_id() == 0) else multiplayer.get_remote_sender_id()

    self_host_data.update_player_ready(player_id, new_ready)
    client_process_new_ready.rpc(player_id, new_ready)

    var all_ready = new_ready and self_host_data.get_all_ready()

    if not new_ready and self_host_data.game_starting:
        self_host_data.game_starting = false
        get_node('LobbyCountdownTimer').queue_free()
        stop_lobby_countdown.rpc()

    if all_ready:
        self_host_data.game_starting = true

        var countdown_timer = Timer.new()
        countdown_timer.name = 'LobbyCountdownTimer'
        countdown_timer.autostart = true
        countdown_timer.one_shot = true
        countdown_timer.wait_time = 10.0
        countdown_timer.timeout.connect(_server_tranistion_to_table)
        add_child(countdown_timer)

        start_lobby_countdown.rpc()

@rpc('authority', 'call_local', 'reliable')
func client_process_new_ready(player_id, new_ready):
    if player_id != multiplayer.get_unique_id():
        emit_signal('update_player_ready', player_id, new_ready)

@rpc('authority', 'call_local', 'reliable')
func start_lobby_countdown():
    emit_signal('do_start_lobby_countdown')

@rpc('authority', 'call_local', 'reliable')
func stop_lobby_countdown():
    emit_signal('do_stop_lobby_countdown')

func _server_tranistion_to_table():
    get_node('LobbyCountdownTimer').queue_free()

    self_host_data.start_game()
    var player_info_dict = self_host_data.get_client_player_table_data()

    for player_id in self_host_data.players.keys():
        var opponent_order = self_host_data.get_opponent_order(player_id)
        client_transition_to_table.rpc_id(player_id,
                                          opponent_order,
                                          player_info_dict,
                                          self_host_data.get_player_pocket(player_id),
                                          self_host_data.game_info.prebet_type,
                                          self_host_data.dealer,
                                          self_host_data.pot,
                                          self_host_data.min_raise)

@rpc('authority', 'call_local', 'reliable')
func client_transition_to_table(opponent_order,
                                client_player_table_data,
                                player_hand,
                                prebet_type,
                                dealer_id,
                                starting_pot,
                                min_raise):
    emit_signal('change_scene', 'table')
    emit_signal('do_start_game',
                opponent_order,
                client_player_table_data,
                player_hand,
                prebet_type,
                dealer_id,
                starting_pot,
                min_raise)

func _on_leave_lobby():
    # Destroy old game data obj if we're the server (i.e. self-hosting)
    # Close connection first though, to avoid clients trying to obtain now-nonexistent data
    var was_server = multiplayer.is_server()
    multiplayer.multiplayer_peer.close()
    if was_server:
        self_host_data = null

    emit_signal('change_scene', 'title')

func _on_send_player_action(action):
    server_process_player_action.rpc_id(1, action)

@rpc('any_peer', 'call_local', 'reliable')
func server_process_player_action(action):
    self_host_data.process_player_action(multiplayer.get_remote_sender_id(), action)

    if self_host_data.phase_complete:
        if self_host_data.game_phase == PokerTypes.GamePhases.GP_FLOP:
            client_start_new_betting_round.rpc(self_host_data.get_client_player_table_data(),
                                               self_host_data.get_turn_player_id(),
                                               self_host_data.community_cards,
                                               self_host_data.pot,
                                               self_host_data.min_raise)
        elif self_host_data.game_phase == PokerTypes.GamePhases.GP_TURN:
            client_start_new_betting_round.rpc(self_host_data.get_client_player_table_data(),
                                               self_host_data.get_turn_player_id(),
                                               [self_host_data.community_cards[3]],
                                               self_host_data.pot,
                                               self_host_data.min_raise)
        elif self_host_data.game_phase == PokerTypes.GamePhases.GP_RIVER:
            client_start_new_betting_round.rpc(self_host_data.get_client_player_table_data(),
                                               self_host_data.get_turn_player_id(),
                                               [self_host_data.community_cards[4]],
                                               self_host_data.pot,
                                               self_host_data.min_raise)
        elif self_host_data.game_phase == PokerTypes.GamePhases.GP_END:
            client_end_game.rpc(self_host_data.get_client_end_game_table_data(),
                                self_host_data.get_client_end_game_results_data(),
                                self_host_data.get_player_pockets(),
                                self_host_data.players_in_hand.size() == 1)
        else:
            pass # TO-DO - Should not enter this phase. Crash the game or something...
    else:
        client_continue_betting_round.rpc(self_host_data.get_client_player_table_data(),
                                          self_host_data.get_turn_player_id(),
                                          self_host_data.pot,
                                          self_host_data.curr_bet != 0,
                                          self_host_data.min_raise)

@rpc('authority', 'call_local', 'reliable')
func client_continue_betting_round(new_player_data, turn_player_id, new_pot, new_prev_bet_made, new_min_raise):
    emit_signal('continue_betting_round', new_player_data, turn_player_id, new_pot, new_prev_bet_made, new_min_raise)

@rpc('authority', 'call_local', 'reliable')
func client_start_new_betting_round(new_player_data, turn_player_id, new_community_cards, new_pot, new_min_raise):
    emit_signal('start_new_betting_round', new_player_data, turn_player_id, new_community_cards, new_pot, new_min_raise)

@rpc('authority', 'call_local', 'reliable')
func client_end_game(end_game_table_data, end_game_results_data, player_pockets, lone_player_in_hand):
    emit_signal('end_game', end_game_table_data, end_game_results_data, player_pockets, lone_player_in_hand)

func _on_player_disconnected(leaving_player_id):
    if multiplayer.is_server():
        self_host_data.remove_player(leaving_player_id)
        handle_player_disconnected.rpc(leaving_player_id)

    # Server closed
    if leaving_player_id == 1:
        # TO-DO - ADD DIALOG BOX
        multiplayer.multiplayer_peer.close()
        emit_signal('change_scene', 'title')

@rpc('authority', 'call_local', 'reliable')
func handle_player_disconnected(leaving_player_id):
    emit_signal('player_disconnected', leaving_player_id)
