extends Node

signal change_scene
signal player_connected
signal player_disconnected
signal set_game_info
signal update_player_ready
signal do_start_lobby_countdown
signal do_stop_lobby_countdown

var hosting_type = PokerTypes.HT_JOINING

var game_info = {}

var my_info = {}

var players = {}

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
    hosting_type = PokerTypes.HT_SELF_HOSTING

    game_info['address'] = address
    game_info['port'] = port
    game_info['name'] = game_name
    game_info['password'] = game_pw
    game_info['starting_balance'] = starting_balance
    game_info['prebet_type'] = prebet_type

    if prebet_type == PokerTypes.PB_ANTE:
        game_info['ante_amount'] = ante_amount
    else:
        game_info['small_blind_amount'] = small_blind_amount
        game_info['big_blind_amount'] = big_blind_amount

    game_info['game_starting'] = false

    my_info['name'] = player_name
    my_info['ready'] = false
    players[multiplayer.get_unique_id()] = my_info

    var my_id = multiplayer.get_unique_id()
    players[my_id] = my_info

    # Add self to lobby scene
    emit_signal('change_scene', 'lobby')
    emit_signal('set_game_info', game_info)
    emit_signal('player_connected', players)

func _do_join_request(game_name, game_pw, player_name):
    my_info['name'] = player_name
    my_info['ready'] = false

    process_join_request.rpc_id(1, game_name, game_pw, my_info)

@rpc('any_peer', 'call_remote', "reliable")
func process_join_request(joiner_game_name, joiner_game_pw, joiner_player_info):
    var creds_good = true
    creds_good = creds_good && (game_info['name'] == joiner_game_name)
    creds_good = creds_good && (game_info['password'] == joiner_game_pw)

    if creds_good:
        var new_player_id = multiplayer.get_remote_sender_id()
        players[new_player_id] = joiner_player_info
        players[new_player_id]['ready'] = false

        if game_info['game_starting']:
            game_info['game_starting'] = false
            stop_lobby_countdown.rpc()

        emit_signal('player_connected', {new_player_id : joiner_player_info})

        enter_lobby.rpc_id(new_player_id, game_info)
        add_new_players.rpc(new_player_id, players)
    else:
        pass

@rpc('authority', 'call_remote', 'reliable')
func enter_lobby(p_game_info):
    game_info = p_game_info
    emit_signal('change_scene', 'lobby')
    emit_signal('set_game_info', game_info)

@rpc('authority', 'call_remote', 'reliable')
func add_new_players(new_player_id, new_players):
    players = new_players

    # Set up newly joined player with existing players
    if new_player_id == multiplayer.get_unique_id():
        emit_signal('player_connected', players)
    # Players who already joined just need to add newly joined player
    else:
        emit_signal('player_connected', {new_player_id : players[new_player_id]})

func _on_update_ready(new_ready):
    my_info['ready'] = new_ready

    if multiplayer.is_server():
        server_process_new_ready(new_ready)
    else:
        server_process_new_ready.rpc_id(1, new_ready)

@rpc('any_peer', 'call_remote', 'reliable')
func server_process_new_ready(new_ready):
    var player_id = 1 if (multiplayer.get_remote_sender_id() == 0) else multiplayer.get_remote_sender_id()
    client_process_new_ready.rpc(player_id, new_ready)

    var all_ready = new_ready and (players.size() > 1)
    if all_ready:
        for player in players:
            all_ready = all_ready and players[player]['ready']
            if not all_ready:
                break

    if not new_ready and game_info['game_starting']:
        game_info['game_starting'] = false
        stop_lobby_countdown.rpc()

    if all_ready:
        game_info['game_starting'] = true
        start_lobby_countdown.rpc()

@rpc('authority', 'call_local', 'reliable')
func client_process_new_ready(player_id, new_ready):
    players[player_id]['ready'] = new_ready

    if player_id != multiplayer.get_unique_id():
        emit_signal('update_player_ready', player_id, new_ready)

@rpc('authority', 'call_local', 'reliable')
func start_lobby_countdown():
    emit_signal('do_start_lobby_countdown')

@rpc('authority', 'call_local', 'reliable')
func stop_lobby_countdown():
    emit_signal('do_stop_lobby_countdown')

func _on_leave_lobby():
    hosting_type = PokerTypes.HT_JOINING
    game_info = {}
    my_info = {}
    players = {}

    multiplayer.multiplayer_peer.close()
    emit_signal('change_scene', 'title')

func _on_player_disconnected(leaving_player_id):
    if multiplayer.is_server():
        remove_player.rpc(leaving_player_id)

    # Server closed
    if leaving_player_id == 1:
        hosting_type = PokerTypes.HT_JOINING
        game_info = {}
        my_info = {}
        players = {}

        multiplayer.multiplayer_peer.close()
        emit_signal('change_scene', 'title')

@rpc('authority', 'call_local', 'reliable')
func remove_player(leaving_player_id):
    players.erase(leaving_player_id)
    emit_signal('player_disconnected', leaving_player_id)
