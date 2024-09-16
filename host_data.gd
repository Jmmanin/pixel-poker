class_name host_data

var game_info : PokerTypes.GameInfo

var game_starting : bool

var players : Dictionary # [int, player_data]

var deck : Array

var players_in_hand : Array
var dealer : int
var player_turn : int
var curr_bet : int
var min_raise : int
var pot : int

func _init(p_game_info : PokerTypes.GameInfo) -> void:
    game_info = p_game_info
    game_starting = false

func add_player(player_id : int, player_name : String) -> void:
    players[player_id] = player_data.new(player_name, game_info.starting_balance)

func process_join_request(joiner_game_name, joiner_game_pw, joiner_id, joiner_name) -> bool:
    var creds_good = true
    creds_good = creds_good && (game_info.game_name == joiner_game_name)
    creds_good = creds_good && (game_info.game_pw == joiner_game_pw)

    if creds_good:
        add_player(joiner_id, joiner_name)
    else:
        pass

    return creds_good

func get_player_lobby_data(player_id : int) -> Dictionary: # player lobby data
    var player_lobby_data : Dictionary = {}
    player_lobby_data[player_id] = {'player_name': players[player_id].player_name, 'ready': players[player_id].ready}
    return player_lobby_data

func get_players_lobby_data() -> Dictionary: # lobby data for every player (key = player id)
    var players_lobby_data : Dictionary = {}
    for id in players:
        players_lobby_data[id] = {'player_name': players[id].player_name, 'ready': players[id].ready}
    return players_lobby_data

func update_player_ready(player_id : int, new_ready : bool) -> void:
    players[player_id].ready = new_ready

func get_all_ready() -> bool:
    var all_ready : bool = players.size() > 1
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

func get_opponent_order(player_id : int) -> Array:
    var player_ids = players.keys()
    var player_index = player_ids.find(player_id)
    var curr_index = (player_index + 1) % players.size()

    var opponent_order = Array()
    while curr_index != player_index:
        opponent_order.append(player_ids[curr_index])
        curr_index = (curr_index + 1) % players.size()

    return opponent_order

func get_client_player_table_data() -> Dictionary:
    var client_player_table_data = {}
    for player in players:
        client_player_table_data[player] = {'player_name': players[player].player_name,
                                            'balance': players[player].balance,
                                            'status': players[player].status}

    return client_player_table_data

func start_round() -> void:
    # Create and shuffle deck
    deck = Array()
    for i in range(13):
        for j in range(4):
            deck.append([i, j])
    deck.shuffle()

    # Pick dealer and arrange players in hand in correct order (left of dealer -> dealer)
    var player_ids = players.keys()
    var dealer_index = randi() % players.size()
    dealer = player_ids[dealer_index]
    player_turn = (dealer_index + 1) % players.size()
    while player_turn != dealer_index:
        players_in_hand.append(player_ids[player_turn])
        player_turn = (player_turn + 1) % players.size()
    players_in_hand.append(dealer)

    for i in players.size() * 2:
        players[players_in_hand[i % players.size()]].deal_card(deck.pop_front())

    # TO-DO - MAKE SURE ALL RELEVANT VALUES HAVE BEEN RESET PROPERLY
    if game_info.prebet_type == PokerTypes.PrebetTypes.PB_ANTE:
        for player in players:
            player.balance -= game_info.ante_amount
            player.curr_bet = 0
            player.status = ''

        pot = game_info.ante_amount * players.size()
        curr_bet = 0
        min_raise = game_info.ante_amount
    else:
        players[players_in_hand[0]].balance -= game_info.small_blind_amount
        players[players_in_hand[0]].curr_bet = game_info.small_blind_amount
        players[players_in_hand[0]].status = 'Bet\n$' + str(game_info.small_blind_amount)

        players[players_in_hand[1]].balance -= game_info.big_blind_amount
        players[players_in_hand[1]].curr_bet = game_info.big_blind_amount
        players[players_in_hand[1]].status = 'Bet\n$' + str(game_info.big_blind_amount)

        pot = game_info.small_blind_amount + game_info.big_blind_amount
        curr_bet = game_info.big_blind_amount
        min_raise = curr_bet * 2

func get_player_hand(player_id : int) -> Array:
    return players[player_id].hand

func process_player_action(player_id : int, action : int):
    if action == -1:
        players[player_id].status = 'Fold'
        players_in_hand.erase(player_id)
    elif action == 0:
        if curr_bet == 0:
            players[player_id].status = 'Check'
        else:
            players[player_id].status = 'Call'
            players[player_id].balance -= action
            players[player_id].curr_bet = action
            pot += action
    else:
        if curr_bet == players[player_id].balance:
            players[player_id].status = 'All-in'
            # TO-DO - HANDLE SPLIT POTS
        else:
            players[player_id].status = 'Raise\n$' + str(action)

        players[player_id].balance -= action
        players[player_id].curr_bet = action
        pot += action
        min_raise = action + action - curr_bet
        curr_bet = action

class player_data:
    var player_name : String
    var ready : bool
    var balance : int
    var hand : Array = Array()
    var curr_bet : int
    var status : String

    func _init(p_player_name : String, starting_balance) -> void:
        player_name = p_player_name
        ready = false
        balance = starting_balance
        curr_bet = 0
        status = ''

    func deal_card(card : Array):
        hand.push_back(card)

    func is_full_dealt() -> bool:
        return hand.size() == 2
