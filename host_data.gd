class_name host_data

var address : String
var port : int
var game_name : String
var game_pw : String
var starting_balance : int

var prebet_type : int: # PokerTypes.PrebetTypes
    get:
        return prebet_type

var ante_amount : int
var small_blind_amount : int
var big_blind_amount : int

var game_starting : bool:
    get:
        return game_starting
    set(new_value):
        game_starting = new_value

var players : Dictionary # [int, player_data]

var dealer : int
var player_turn : int

var deck : Array

func _init(p_address : String,
           p_port : int,
           p_game_name : String,
           p_game_pw : String,
           p_starting_balance : int,
           p_prebet_type : int,
           p_ante_amount : int,
           p_small_blind_amount : int,
           p_big_blind_amount : int) -> void:
    address = p_address
    port = p_port
    game_name = p_game_name
    game_pw = p_game_pw
    starting_balance = p_starting_balance
    prebet_type = p_prebet_type
    ante_amount = p_ante_amount
    small_blind_amount = p_small_blind_amount
    big_blind_amount = p_big_blind_amount

    game_starting = false

func add_player(player_id : int, player_name : String) -> void:
    players[player_id] = player_data.new(player_name, starting_balance)

func get_game_info() -> Dictionary: # [String, various game data params]
    var game_data : Dictionary = {}

    game_data['address'] = address
    game_data['port'] = port
    game_data['name'] = game_name
    game_data['starting_balance'] = starting_balance
    game_data['prebet_type'] = prebet_type
    game_data['ante_amount'] = ante_amount
    game_data['small_blind_amount'] = small_blind_amount
    game_data['big_blind_amount'] = big_blind_amount

    return game_data

func process_join_request(joiner_game_name, joiner_game_pw, joiner_id, joiner_name) -> bool:
    var creds_good = true
    creds_good = creds_good && (game_name == joiner_game_name)
    creds_good = creds_good && (game_pw == joiner_game_pw)

    if creds_good:
        add_player(joiner_id, joiner_name)
    else:
        pass

    return creds_good

func get_player_lobby_data(player_id : int) -> Dictionary: # player lobby data
    var player_lobby_data : Dictionary = {}
    player_lobby_data[player_id] = {}
    player_lobby_data[player_id]['name'] = players[player_id].player_name
    player_lobby_data[player_id]['ready'] = players[player_id].ready

    return player_lobby_data

func get_players_lobby_data() -> Dictionary: # lobby data for every player (key = player id)
    var players_lobby_data : Dictionary = {}
    for id in players:
        players_lobby_data[id] = {}
        players_lobby_data[id]['name'] = players[id].player_name
        players_lobby_data[id]['ready'] = players[id].ready

    return players_lobby_data

func update_player_ready(player_id : int, new_ready : bool) -> void:
    players[player_id].ready = new_ready

func get_all_ready():
    var all_ready = players.size() > 1
    if all_ready:
        for id in players:
            all_ready = all_ready and players[id].ready
            if not all_ready:
                break

    return all_ready

func remove_player(leaving_player_id : int) -> void:
    players.erase(leaving_player_id)

func get_player_ids() -> Array:
    return(players.keys())

func get_player_names() -> Dictionary:
    var player_names : Dictionary = {}
    for player_id in players:
        player_names[player_id] = players[player_id].player_name

    return player_names

func get_starting_dealer() -> int:
    var player_ids = players.keys()
    dealer = player_ids.pick_random()
    player_turn = (player_ids.find(dealer) + 1) % players.size()
    return dealer

func get_opponent_order(player_id : int) -> Array:
    var player_ids = players.keys()
    var player_index = player_ids.find(player_id)
    var curr_index = (player_index + 1) % players.size()

    var opponent_order = Array()
    while curr_index != player_index:
        opponent_order.append(player_ids[curr_index])
        curr_index = (curr_index + 1) % players.size()

    return opponent_order

func suffle_and_deal():
    deck = Array()
    for i in range(13):
        for j in range(4):
            deck.append([i, j])

    deck.shuffle()

    var player_ids = get_player_ids()
    while not players[player_ids[player_turn]].is_full_dealt():
        players[player_ids[player_turn]].deal_card(deck.pop_front())
        player_turn = (player_turn + 1) % player_ids.size()

func get_player_hand(player_id : int) -> Array:
    return players[player_id].hand

class player_data:
    var player_name : String:
        get:
            return player_name

    var balance : int:
        get:
            return balance
        set(new_value):
            balance = new_value

    var ready : bool:
        get:
            return ready
        set(new_value):
            ready = new_value

    var hand : Array = Array():
        get:
            return hand

    func _init(p_player_name : String, starting_balance) -> void:
        player_name = p_player_name
        balance = starting_balance
        ready = false

    func deal_card(card : Array):
        hand.push_back(card)

    func is_full_dealt() -> bool:
        return hand.size() == 2
