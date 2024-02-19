extends Node

signal change_scene
signal player_connected
signal player_disconnected
signal set_game_info
signal update_player_ready

var multiplayer_peer = ENetMultiplayerPeer.new()

var hosting_type = PokerTypes.HT_JOINING

var game_info = {}

var my_info = {}

var players = {}

func _ready():
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connected_fail)

    get_node('/root/Main/Scene_Switcher').connect('child_entered_tree',
                                                  _on_child_entered_tree)

    connect('change_scene', get_node('/root/Main/Scene_Switcher')._on_change_scene)

func _on_child_entered_tree(new_node):
    print(new_node.name)

func _on_do_join(address, port, game_name, game_pw, player_name):
    print('Joining...')

    game_info['name'] = game_name
    game_info['password'] = game_pw

    my_info['name'] = player_name
    my_info['ready'] = false

    #multiplayer_peer.get_peer(1).set_timeout(0,0,3000)#get_unique_id()
    var error = multiplayer_peer.create_client(address, port)
    if error:
        return error
    multiplayer.multiplayer_peer = multiplayer_peer

func _on_do_host(address,
                 port,
                 game_name,
                 game_pw,
                 starting_balance,
                 prebet_type,
                 ante_amount,
                 small_blind_amount,
                 big_blind_amount,
                 player_name):
    game_info['name'] = game_name
    game_info['password'] = game_pw
    game_info['starting_balance'] = starting_balance
    game_info['prebet_type'] = prebet_type

    if prebet_type == PokerTypes.PB_ANTE:
        game_info['ante_amount'] = ante_amount
    else:
        game_info['small_blind_amount'] = small_blind_amount
        game_info['big_blind_amount'] = big_blind_amount

    my_info['name'] = player_name
    my_info['ready'] = false

    if address == '':
        # TO-DO - Set IP to own public IP (need to get that via HTTP request)
        print('Self-Hosting...')
        hosting_type = PokerTypes.HT_SELF_HOSTING

        multiplayer_peer.create_server(port)
        multiplayer.multiplayer_peer = multiplayer_peer
        # TO-DO - Handle errors

        emit_signal('change_scene', 'lobby')

        emit_signal('set_game_info', game_info)

        var my_id = multiplayer.get_unique_id()
        players[my_id] = my_info

        # Add self to lobby scene
        emit_signal('player_connected', players)
    else:
        print('Hosting... (not impl\'d)')
        get_tree().quit()

func _on_connected_ok():
    if hosting_type == PokerTypes.HT_JOINING:
        process_join_request.rpc_id(1, game_info, my_info)
    elif hosting_type == PokerTypes.HT_HOSTING:
        # TO-DO - Implement hosting logic
        pass
    else:
        # Should not occur if self-hosting
        pass

func _on_connected_fail():
    # TO-DO - Handle connection failure
    print('Connection timeout')

@rpc('any_peer', 'call_remote', "reliable")
func process_join_request(joiner_game_info, joiner_player_info):
    var creds_good = true
    creds_good = creds_good && (game_info['name'] == joiner_game_info['name'])
    creds_good = creds_good && (game_info['password'] == joiner_game_info['password'])

    if creds_good:
        var new_player_id = multiplayer.get_remote_sender_id()
        players[new_player_id] = joiner_player_info

        emit_signal('player_connected', {new_player_id : joiner_player_info})

        enter_lobby.rpc_id(new_player_id, game_info)
        add_new_players.rpc(new_player_id, players)
    else:
        pass

@rpc('authority', 'call_remote', 'reliable')
func enter_lobby(the_game_info):
    game_info = the_game_info
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
        client_process_new_ready.rpc(multiplayer.get_unique_id(), new_ready)
    else:
        server_process_new_ready.rpc_id(1, new_ready)

@rpc('any_peer', 'call_remote', 'reliable')
func server_process_new_ready(new_ready):
    var player_id = multiplayer.get_remote_sender_id()
    client_process_new_ready.rpc(player_id, new_ready)

@rpc('authority', 'call_local', 'reliable')
func client_process_new_ready(player_id, new_ready):
    players[player_id]['ready'] = new_ready

    if player_id != multiplayer.get_unique_id():
        emit_signal('update_player_ready', player_id, new_ready)

func _on_leave_lobby():
    hosting_type = PokerTypes.HT_JOINING
    game_info = {}
    my_info = {}
    players = {}

    multiplayer.multiplayer_peer.close()
    emit_signal('change_scene', 'title')

func _on_player_disconnected(leaving_player_id):
    print(str(multiplayer_peer.get_unique_id()) + ' recv\'d id: ' + str(leaving_player_id) + ' disconnected')
    if multiplayer.is_server():
        remove_player.rpc(leaving_player_id)

    # Server closed
    if leaving_player_id == 1:
        print('server closed')
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
