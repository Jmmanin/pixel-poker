extends Node

signal change_scene
signal player_connected
signal player_disconnected
signal set_game_info
signal update_player_ready
signal do_start_lobby_countdown
signal do_stop_lobby_countdown
signal set_table_players

var self_host_data : host_data = null # Only used if self-hosting

func _ready():
    multiplayer.peer_disconnected.connect(_on_player_disconnected)

    connect('change_scene', get_node('/root/Main/Scene_Switcher')._on_change_scene)

func _on_init_self_host(address,
                        port,
                        game_name,
                        game_pw,
                        starting_balance,
                        prebet_type,
                        ante_amount,
                        small_blind_amount,
                        big_blind_amount,
                        player_name):
    self_host_data = host_data.new(address,
                                   port,
                                   game_name,
                                   game_pw,
                                   starting_balance,
                                   prebet_type,
                                   ante_amount,
                                   small_blind_amount,
                                   big_blind_amount)

    var my_id = multiplayer.get_unique_id()
    self_host_data.add_player(multiplayer.get_unique_id(), player_name)

    # Add self to lobby scene
    emit_signal('change_scene', 'lobby')
    emit_signal('set_game_info', self_host_data.get_game_info())
    emit_signal('player_connected', {my_id : {'name' : player_name, 'ready' : false}})

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

        enter_lobby.rpc_id(new_player_id, self_host_data.get_game_info())
        add_new_players.rpc(new_player_id, self_host_data.get_players_lobby_data())
    else:
        pass

@rpc('authority', 'call_remote', 'reliable')
func enter_lobby(p_game_info):
    emit_signal('change_scene', 'lobby')
    emit_signal('set_game_info', p_game_info)

@rpc('authority', 'call_remote', 'reliable')
func add_new_players(new_player_id, p_players):
    # Set up newly joined player with existing players
    if new_player_id == multiplayer.get_unique_id():
        emit_signal('player_connected', p_players)
    # Players who already joined just need to add newly joined player
    else:
        emit_signal('player_connected', {new_player_id : p_players[new_player_id]})

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
    print('transition to table')

    var player_ids = self_host_data.get_player_ids()
    var player_names = self_host_data.get_player_names()
    var starting_balance = self_host_data.starting_balance
    var prebet_type = self_host_data.prebet_type
    var starting_dealer_id = self_host_data.get_starting_dealer()

    self_host_data.suffle_and_deal()

    for player_id in player_ids:
        var opponent_order = self_host_data.get_opponent_order(player_id)
        client_transition_to_table.rpc_id(player_id, opponent_order, player_names, starting_balance, prebet_type, starting_dealer_id, self_host_data.get_player_hand(player_id))

@rpc('authority', 'call_local', 'reliable')
func client_transition_to_table(opponent_order, player_names, starting_balance, prebet_type, starting_dealer_id, player_hand):
    emit_signal('change_scene', 'table')
    emit_signal('set_table_players', opponent_order, player_names, starting_balance, prebet_type, starting_dealer_id, player_hand)

func _on_leave_lobby():
    # Destroy old game data obj if we're the server (i.e. self-hosting)
    # Close connection first though, to avoid clients trying to obtain now-nonexistent data
    var was_server = multiplayer.is_server()
    multiplayer.multiplayer_peer.close()
    if was_server:
        self_host_data = null

    emit_signal('change_scene', 'title')

func _on_player_disconnected(leaving_player_id):
    if multiplayer.is_server():
        self_host_data.remove_player(leaving_player_id)
        handle_player_disconnected.rpc(leaving_player_id)

    # Server closed
    if leaving_player_id == 1:
        multiplayer.multiplayer_peer.close()
        emit_signal('change_scene', 'title')

@rpc('authority', 'call_local', 'reliable')
func handle_player_disconnected(leaving_player_id):
    emit_signal('player_disconnected', leaving_player_id)
