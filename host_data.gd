class_name host_data

enum PokerHands {PH_HIGH_CARD, PH_PAIR, PH_TWO_PAIR, PH_THREE_OF_A_KIND, PH_STRAIGHT, PH_FLUSH, PH_FULL_HOUSE, PH_FOUR_OF_A_KIND, PH_STRAIGHT_FLUSH, PH_ROYAL_FLUSH}

var game_info : PokerTypes.GameInfo

var game_starting : bool

var players : Dictionary # [int, player_data]

var deck : Array

var players_in_hand : Array
var dealer : int
var player_turn_index : int

var curr_bet : int
var min_raise : int
var pot : int

var game_phase : int
var once_around_the_table : bool
var phase_complete : bool

var community_cards : Array

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

func start_game() -> void:
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
    player_turn_index = (dealer_index + 1) % players.size()
    while player_turn_index != dealer_index:
        players_in_hand.append(player_ids[player_turn_index])
        player_turn_index = (player_turn_index + 1) % players.size()
    players_in_hand.append(dealer)

    # Deal
    for i in players.size() * 2:
        players[players_in_hand[i % players.size()]].deal_card(deck.pop_front())

    # Set up initial game parameters based on prebet type
    # TO-DO - MAKE SURE ALL RELEVANT VALUES HAVE BEEN RESET PROPERLY
    if game_info.prebet_type == PokerTypes.PrebetTypes.PB_ANTE:
        for player in players:
            player.balance -= game_info.ante_amount
            player.curr_bet = 0
            player.status = ''

        pot = game_info.ante_amount * players.size()
        curr_bet = 0
        min_raise = game_info.ante_amount
        player_turn_index = 0
    else:
        if players.size() > 2:
            players[players_in_hand[0]].balance -= game_info.small_blind_amount
            players[players_in_hand[0]].curr_bet = game_info.small_blind_amount
            players[players_in_hand[0]].status = 'Bet\n$' + str(game_info.small_blind_amount)

            players[players_in_hand[1]].balance -= game_info.big_blind_amount
            players[players_in_hand[1]].curr_bet = game_info.big_blind_amount
            players[players_in_hand[1]].status = 'Bet\n$' + str(game_info.big_blind_amount)
        else:
            # In two-player blind games, the dealer also has the small blind while the other player has the big blind
            players[players_in_hand[1]].balance -= game_info.small_blind_amount
            players[players_in_hand[1]].curr_bet = game_info.small_blind_amount
            players[players_in_hand[1]].status = 'Bet\n$' + str(game_info.small_blind_amount)

            players[players_in_hand[0]].balance -= game_info.big_blind_amount
            players[players_in_hand[0]].curr_bet = game_info.big_blind_amount
            players[players_in_hand[0]].status = 'Bet\n$' + str(game_info.big_blind_amount)

        pot = game_info.small_blind_amount + game_info.big_blind_amount
        curr_bet = game_info.big_blind_amount
        min_raise = curr_bet * 2
        player_turn_index = 2

    game_phase = PokerTypes.GamePhases.GP_PRE_FLOP
    once_around_the_table = false
    phase_complete = false

func get_client_player_table_data() -> Dictionary:
    var client_player_table_data = {}
    for player in players:
        client_player_table_data[player] = {'player_name': players[player].player_name,
                                            'balance': players[player].balance,
                                            'status': players[player].status}

    return client_player_table_data

func get_opponent_order(player_id : int) -> Array:
    var player_ids = players.keys()
    var player_index = player_ids.find(player_id)
    var curr_index = (player_index + 1) % players.size()

    var opponent_order = Array()
    while curr_index != player_index:
        opponent_order.append(player_ids[curr_index])
        curr_index = (curr_index + 1) % players.size()

    return opponent_order

func get_player_pocket(player_id : int) -> Array:
    return players[player_id].pocket

func process_player_action(player_id : int, action : int):
    phase_complete = false

    if action == -1:
        players[player_id].status = 'Fold'
        players_in_hand.erase(player_id)
        # DO NOT increment player turn index
    elif action == 0:
        if curr_bet == 0:
            players[player_id].status = 'Check'
        else:
            pot += curr_bet - players[player_id].curr_bet

            players[player_id].status = 'Call'
            players[player_id].balance -= curr_bet - players[player_id].curr_bet
            players[player_id].curr_bet = curr_bet

        player_turn_index += 1
    else:
        if curr_bet == players[player_id].balance:
            players[player_id].status = 'All-in'
            # TO-DO - HANDLE SPLIT POTS
        else:
            players[player_id].status = 'Raise\n$' + str(action)

        pot += action - players[player_id].curr_bet
        min_raise = action + action - curr_bet
        curr_bet = action

        players[player_id].balance -= action - players[player_id].curr_bet
        players[player_id].curr_bet = action

        player_turn_index += 1

    if player_turn_index >= players_in_hand.size():
        player_turn_index = 0
        once_around_the_table = true

    # Game advances to next phase once round of betting is complete
    if players_in_hand.size() == 1:
        # TO-DO - PAY OUT POT
        game_phase = PokerTypes.GamePhases.GP_END
        print('game ended by folding')
    elif once_around_the_table and players[players_in_hand[player_turn_index]].curr_bet == curr_bet:
        player_turn_index = 0
        once_around_the_table = false
        phase_complete = true

        for player in players:
            players[player].curr_bet = 0
            players[player].status = ''

        curr_bet = 0
        min_raise = game_info.ante_amount if game_info.prebet_type == PokerTypes.PrebetTypes.PB_ANTE else game_info.big_blind_amount

        if game_phase == PokerTypes.GamePhases.GP_PRE_FLOP:
            deck.pop_front() # burn card
            community_cards.push_back(deck.pop_front())
            community_cards.push_back(deck.pop_front())
            community_cards.push_back(deck.pop_front())

            game_phase = PokerTypes.GamePhases.GP_FLOP
        elif game_phase == PokerTypes.GamePhases.GP_FLOP:
            deck.pop_front() # burn card
            community_cards.push_back(deck.pop_front())

            game_phase = PokerTypes.GamePhases.GP_TURN
        elif game_phase == PokerTypes.GamePhases.GP_TURN:
            deck.pop_front() # burn card
            community_cards.push_back(deck.pop_front())

            game_phase = PokerTypes.GamePhases.GP_RIVER
        elif game_phase == PokerTypes.GamePhases.GP_RIVER:
            score_game()
            # TO-DO - SCORE GAME AND PAY OUT POT
            game_phase = PokerTypes.GamePhases.GP_END
            print('game ended')
        else:
            pass # TO-DO - should not get here. Crash the game or something...
    else:
        pass # Current round of betting continues

func get_turn_player_id() -> int:
    return players_in_hand[player_turn_index]

func score_game():
    for player in players:
        # Sort all cards available for player to make hand from by value
        var hand_value = players[player].pocket.duplicate(true)
        hand_value.append_array(community_cards)
        hand_value.sort_custom(func(a, b): return a[0] < b[0])

        # Sort all cards available for player to make hand from by suit
        var hand_suit = [[], [], [], []]
        for card in hand_value:
            hand_suit[card[1]].append(card)

        # Get longest, sequence from set of all sequences
        var flush = hand_suit.reduce(get_longest)

        # A player's hand can only be 5 cards, so get the highest sequence if there are more
        while flush.size() > 5:
            flush.pop_front()

        # Remove cards with the same value for purposes of finding straights
        var hand_value_no_repeat = [hand_value[0]]
        for i in range(1, hand_value.size()):
            if hand_value[i][0] != hand_value[i-1][0]:
                hand_value_no_repeat.append(hand_value[i])

        if hand_value_no_repeat[-1][0] == 12: # Add ace to front of array if applicable to cover low straights
            hand_value_no_repeat.push_front(hand_value_no_repeat[-1])

        # Find all incrementing sequences of cards in available set
        var possible_straights = [[]]
        for card in hand_value_no_repeat:
            # Add card to current sequence if one value higher than previous, otherwise create new sequence
            if not possible_straights[-1] \
               or ((card[0] - possible_straights[-1][-1][0]) == 1) \
               or (card[0] == 2 and possible_straights[-1].size() == 1 and possible_straights[-1][-1][0] == 12): # Handle straights starting with ace
                possible_straights[-1].append(card)
            else:
                possible_straights.append([card])

        # Get longest, highest-value sequence from set of all sequences
        var straight = possible_straights.reduce(get_longest)

        # A player's hand can only be 5 cards, so get the highest sequence if there are more
        while straight.size() > 5:
            straight.pop_front()

        # Find all multiples in available set of cards
        var multiples = [[]]
        for card in hand_value:
            # Add card to current sequence if equal to previous, otherwise create new sequence
            if not multiples[-1] or card[0] == multiples[-1][-1][0]:
                multiples[-1].append(card)
            else:
                multiples.append([card])

        # Iterate through list of multiples and pull out those of interest
        var first_pair_index = -1
        var second_pair_index = -1
        var toak_index = -1
        var foak_index = -1
        for index in multiples.size():
            if multiples[index].size() == 2:
                if first_pair_index == -1:
                    first_pair_index = index
                elif second_pair_index == -1:
                    second_pair_index = index
                else:
                    first_pair_index = second_pair_index
                    second_pair_index = index
            elif multiples[index].size() == 3:
                toak_index = index
            elif multiples[index].size() == 4:
                foak_index = index
            else:
                pass # Do nothing

        if straight.size() == 5:
            var straight_flush = true
            for index in range(1, straight.size()):
                straight_flush = straight_flush and (straight[index][1] == straight[index-1][1])
                if not straight_flush:
                    break
    
            if straight_flush and straight[4][0] == 9:
                players[player].hand = straight
                players[player].hand_type = PokerHands.PH_ROYAL_FLUSH
                continue

            if straight_flush:
                players[player].hand = straight
                players[player].hand_type = PokerHands.PH_STRAIGHT_FLUSH
                continue

        if foak_index != -1:
            players[player].hand.append_array(multiples[foak_index])

            # Add highest value card available to fill out rest of hand
            multiples.remove_at(foak_index)
            players[player].hand.append(multiples[-1][-1])

            players[player].hand_type = PokerHands.PH_FOUR_OF_A_KIND
            continue

        if toak_index != -1 and first_pair_index != -1:
            players[player].hand.append_array(multiples[toak_index])
            players[player].hand_type = PokerHands.PH_FULL_HOUSE
            if second_pair_index != -1:
                players[player].hand.append_array(multiples[second_pair_index])
            else:
                players[player].hand.append_array(multiples[first_pair_index])
            continue

        if flush.size() == 5:
            players[player].hand = flush
            players[player].hand_type = PokerHands.PH_FLUSH
            continue

        if straight.size() == 5:
            players[player].hand = straight
            players[player].hand_type = PokerHands.PH_STRAIGHT
            continue

        if toak_index != -1:
            players[player].hand.append_array(multiples[toak_index])

            # Add two highest value cards available to fill out rest of hand
            multiples.remove_at(toak_index)
            players[player].hand.append(multiples[-1].pop_back())
            if multiples[-1].is_empty():
                multiples.resize(multiples.size() - 1)
            players[player].hand.append(multiples[-1][-1])

            players[player].hand_type = PokerHands.PH_THREE_OF_A_KIND
            continue

        if second_pair_index != -1 and first_pair_index != -1:
            players[player].hand.append_array(multiples[second_pair_index])
            players[player].hand.append_array(multiples[first_pair_index])

            # Add highest value card available to fill out rest of hand
            multiples.remove_at(second_pair_index)
            multiples.remove_at(first_pair_index)
            players[player].hand.append(multiples[-1][-1])

            players[player].hand_type = PokerHands.PH_TWO_PAIR
            continue

        if first_pair_index != -1:
            players[player].hand.append_array(multiples[first_pair_index])

            # Add three highest value cards available to fill out rest of hand
            multiples.remove_at(first_pair_index)
            players[player].hand.append(multiples[-1].pop_back())
            if multiples[-1].is_empty():
                multiples.resize(multiples.size() - 1)
            players[player].hand.append(multiples[-1].pop_back())
            if multiples[-1].is_empty():
                multiples.resize(multiples.size() - 1)
            players[player].hand.append(multiples[-1][-1])

            players[player].hand_type = PokerHands.PH_PAIR
            continue

        hand_value.reverse().resize(5)
        players[player].hand = hand_value
        players[player].hand_type = PokerHands.PH_HIGH_CARD

func sort_value(a : Array, b : Array) -> bool:
    if a[0] < b[0]:
        return true
    return false

func get_longest(longest : Array, next : Array) -> Array:
    if next.size() >= longest.size():
        return next
    else:
        return longest

class player_data:
    var player_name : String
    var ready : bool
    var balance : int
    var pocket : Array = Array()
    var curr_bet : int
    var status : String
    var hand : Array = Array()
    var hand_type : int

    func _init(p_player_name : String, starting_balance) -> void:
        player_name = p_player_name
        ready = false
        balance = starting_balance
        curr_bet = 0
        status = ''
        hand_type = -1

    func deal_card(card : Array):
        pocket.push_back(card)

    func is_full_dealt() -> bool:
        return pocket.size() == 2
