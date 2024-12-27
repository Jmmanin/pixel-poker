class_name host_data

enum PokerHands {PH_FOLD = -1, PH_DEFAULT = 0, PH_HIGH_CARD, PH_PAIR, PH_TWO_PAIR, PH_THREE_OF_A_KIND, PH_STRAIGHT, PH_FLUSH, PH_FULL_HOUSE, PH_FOUR_OF_A_KIND, PH_STRAIGHT_FLUSH, PH_ROYAL_FLUSH}

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

func remove_player(leaving_player_id : int) -> void:
    players.erase(leaving_player_id)

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

    # Deal first card and reset player state
    for i in players.size():
        var player_id = players_in_hand[i]

        players[player_id].pocket.push_back(deck.pop_front())

        players[player_id].ready = false
        players[player_id].initial_balance = players[player_id].balance
        players[player_id].curr_bet = 0
        players[player_id].status  = ""
        players[player_id].hand = Array()
        players[player_id].hand_type = PokerHands.PH_DEFAULT
        players[player_id].hand_indices = Array()
        players[player_id].winner = false

    # Deal second card
    for i in players.size():
        players[players_in_hand[i]].pocket.push_back(deck.pop_front())

    # Set up initial game parameters based on prebet type
    # TO-DO - Handle cases where player can't afford anter/blind (immediately all-in)
    if game_info.prebet_type == PokerTypes.PrebetTypes.PB_ANTE:
        for player in players:
            player.balance -= game_info.ante_amount
            player.curr_bet = 0

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

    game_starting = false
    game_phase = PokerTypes.GamePhases.GP_PRE_FLOP
    once_around_the_table = false
    phase_complete = false
    community_cards = Array()

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
        elif curr_bet == 0:
            players[player_id].status = 'Bet $' + str(action)
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
            if players[player].status != 'Fold':
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
            game_phase = PokerTypes.GamePhases.GP_END
        else:
            pass # TO-DO - should not get here. Crash the game or something...
    else:
        pass # Current round of betting continues

func get_turn_player_id() -> int:
    return players_in_hand[player_turn_index]

func score_game():
    for player in players_in_hand:
        # A hand of five cards can be made from the players pocket and the community cards
        var hand_value = players[player].pocket.duplicate(true)
        hand_value.append_array(community_cards)

        # Create dictionary of cards to where they came from (0-1 = pocket, 2-6 = community cards)
        var hand_dict = {}
        for index in hand_value.size():
            hand_dict[hand_value[index]] = index

        # Sort available cards by value, greatest to least
        hand_value.sort_custom(func(a, b): return a[0] > b[0])

        # Sort all cards available for player to make hand from by suit
        var hand_suit = [[], [], [], []]
        for card in hand_value:
            hand_suit[card[1]].append(card)

        # Get longest sequence from set of all sequences
        var flush = hand_suit.reduce(get_longest)

        # A player's hand can only be 5 cards, so get the highest sequence if there are more
        while flush.size() > 5:
            flush.pop_back()

        # Remove cards with the same value for purposes of finding straights
        var hand_value_no_repeat = [hand_value[0]]
        for i in range(1, hand_value.size()):
            if hand_value[i][0] != hand_value[i-1][0]:
                hand_value_no_repeat.append(hand_value[i])

        if hand_value_no_repeat[0][0] == 12: # Add ace to back of array if applicable to cover low straights
            hand_value_no_repeat.push_back(hand_value_no_repeat[0])

        # Find all decrementing sequences of cards in available set
        var possible_straights = [[]]
        for card in hand_value_no_repeat:
            # Add card to current sequence if one value lower than previous, otherwise create new sequence
            if not possible_straights[-1] \
               or ((possible_straights[-1][-1][0] - card[0]) == 1) \
               or (card[0] == 12 and (possible_straights[-1].size() == 4) and (possible_straights[-1][-1][0] == 2)): # Handle straights with low card ace
                possible_straights[-1].append(card)
            else:
                possible_straights.append([card])

        # Get longest, highest-value sequence from set of all sequences
        var straight = possible_straights.reduce(get_longest)

        # A player's hand can only be 5 cards, so get the highest sequence if there are more
        while straight.size() > 5:
            straight.pop_back()

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
                    pass # Don't nothing, subsequent pairs have a lower value
            elif (multiples[index].size() == 3) and (toak_index == -1):
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

            players[player].hand = straight
            players[player].hand_indices = get_hand_indices(hand_dict, straight)

            if straight_flush and straight[0][0] == 12:
                players[player].hand_type = PokerHands.PH_ROYAL_FLUSH
                players[player].status = 'Royal\nFlush'
                continue

            if straight_flush:
                players[player].hand_type = PokerHands.PH_STRAIGHT_FLUSH
                players[player].status = 'Straight\nFlush'
                continue

        if foak_index != -1:
            players[player].hand.append_array(multiples.pop_at(foak_index))

            # Add highest value card available to fill out rest of hand
            players[player].hand.append(multiples[0][0])

            players[player].hand_indices = get_hand_indices(hand_dict, players[player].hand)

            players[player].hand_type = PokerHands.PH_FOUR_OF_A_KIND
            players[player].status = 'Four of\na Kind'
            continue

        if toak_index != -1 and first_pair_index != -1:
            players[player].hand.append_array(multiples[toak_index])
            players[player].hand.append_array(multiples[first_pair_index])

            players[player].hand_indices = get_hand_indices(hand_dict, players[player].hand)

            players[player].hand_type = PokerHands.PH_FULL_HOUSE
            players[player].status = 'Full\nHouse'
            continue

        if flush.size() == 5:
            players[player].hand = flush
            players[player].hand_indices = get_hand_indices(hand_dict, flush)
            players[player].hand_type = PokerHands.PH_FLUSH
            players[player].status = 'Flush'
            continue

        if straight.size() == 5:
            players[player].hand = straight
            players[player].hand_indices = get_hand_indices(hand_dict, straight)
            players[player].hand_type = PokerHands.PH_STRAIGHT
            players[player].status = 'Straight'
            continue

        if toak_index != -1:
            players[player].hand.append_array(multiples.pop_at(toak_index))

            # Add two highest value cards available to fill out rest of hand
            players[player].hand.append(multiples[0].pop_front())
            if multiples[0].is_empty():
                multiples.pop_front()
            players[player].hand.append(multiples[0][0])

            players[player].hand_indices = get_hand_indices(hand_dict, players[player].hand)

            players[player].hand_type = PokerHands.PH_THREE_OF_A_KIND
            players[player].status = 'Three of\na Kind'
            continue

        if first_pair_index != -1 and second_pair_index != -1:
            players[player].hand.append_array(multiples.pop_at(first_pair_index))
            players[player].hand.append_array(multiples.pop_at(second_pair_index - 1))

            # Add highest value card available to fill out rest of hand
            players[player].hand.append(multiples[0][0])

            players[player].hand_indices = get_hand_indices(hand_dict, players[player].hand)

            players[player].hand_type = PokerHands.PH_TWO_PAIR
            players[player].status = 'Two\nPair'
            continue

        if first_pair_index != -1:
            players[player].hand.append_array(multiples.pop_at(first_pair_index))

            # Add three highest value cards available to fill out rest of hand
            players[player].hand.append(multiples[0].pop_front())
            if multiples[0].is_empty():
                multiples.pop_front()
            players[player].hand.append(multiples[0].pop_front())
            if multiples[0].is_empty():
                multiples.pop_front()
            players[player].hand.append(multiples[0][0])

            players[player].hand_indices = get_hand_indices(hand_dict, players[player].hand)

            players[player].hand_type = PokerHands.PH_PAIR
            players[player].status = 'Pair'
            continue

        hand_value.resize(5)
        players[player].hand = hand_value
        players[player].hand_indices = get_hand_indices(hand_dict, players[player].hand)
        players[player].hand_type = PokerHands.PH_HIGH_CARD
        players[player].status = 'High\nCard'

    # Determine the winner(s) of the hand
    var winners = Array()
    for player in players_in_hand:
        if not winners:
            winners.append(player)
        elif players[winners[-1]].hand_type == players[player].hand_type:
            # Check to see who has the better hand of the two (or if both players have the exact same hand)
            var hand_type = players[player].hand_type
            if hand_type == PokerHands.PH_ROYAL_FLUSH:
                winners.append(player) # Royal flush is unique (i.e. nothing to compare)
            elif    hand_type == PokerHands.PH_STRAIGHT_FLUSH \
                 or hand_type == PokerHands.PH_STRAIGHT:
                if (players[player].hand[0][0] == players[winners[-1]].hand[0][0]):
                    winners.append(player) # Players have same hand
                elif (players[player].hand[0][0] > players[winners[-1]].hand[0][0]):
                    winners = [player] # Player has better hand
                else:
                    pass # Current player has worse hand
            elif    hand_type == PokerHands.PH_FOUR_OF_A_KIND \
                 or hand_type == PokerHands.PH_FULL_HOUSE:
                if (players[player].hand[0][0] == players[winners[-1]].hand[0][0]): # Check F/ToaK value
                    if (players[player].hand[-1][0] == players[winners[-1]].hand[-1][0]): # Check high card/pair value
                        winners.append(player)
                    elif (players[player].hand[-1][0] > players[winners[-1]].hand[-1][0]):
                        winners = [player]
                    else:
                        pass # Current player has worse hand
                elif (players[player].hand[0][0] > players[winners[-1]].hand[0][0]):
                    winners = [player]
                else:
                    pass # Current player has worse hand
            elif    hand_type == PokerHands.PH_FLUSH \
                 or hand_type == PokerHands.PH_HIGH_CARD:
                var better = false
                var worse = false
                # Compare each card in hand, player with higher "straight" has better hand
                for index in players[player].hand.size():
                    if (players[player].hand[index][0] > players[winners[-1]].hand[index][0]):
                        better = true
                        break

                    if (players[player].hand[index][0] < players[winners[-1]].hand[index][0]):
                        worse = true
                        break

                if better:
                    winners = [player]
                elif not worse:
                    winners.append(player)
                else:
                    pass # Current player has worse hand
            elif hand_type == PokerHands.PH_THREE_OF_A_KIND:
                if (players[player].hand[0][0] == players[winners[-1]].hand[0][0]): # Check ToaK value
                    if (players[player].hand[-2][0] == players[winners[-1]].hand[-2][0]): # Check high card
                        if (players[player].hand[-1][0] == players[winners[-1]].hand[-1][0]): # Check next high card
                            winners.append(player)
                        elif (players[player].hand[-1][0] > players[winners[-1]].hand[-1][0]):
                            winners = [player]
                        else:
                            pass # Current player has worse hand
                    elif (players[player].hand[-2][0] > players[winners[-1]].hand[-2][0]):
                        winners = [player]
                    else:
                        pass # Current player has worse hand
                elif (players[player].hand[0][0] > players[winners[-1]].hand[0][0]):
                    winners = [player]
                else:
                    pass # Current player has worse hand
            elif hand_type == PokerHands.PH_TWO_PAIR:
                if (players[player].hand[0][0] == players[winners[-1]].hand[0][0]): # Check first pair value
                    if (players[player].hand[2][0] == players[winners[-1]].hand[2][0]): # Check second pair value
                        if (players[player].hand[-1][0] == players[winners[-1]].hand[-1][0]): # Check high card
                            winners.append(player)
                        elif (players[player].hand[-1][0] > players[winners[-1]].hand[-1][0]):
                            winners = [player]
                        else:
                            pass # Current player has worse hand
                    elif (players[player].hand[2][0] > players[winners[-1]].hand[2][0]):
                        winners = [player]
                    else:
                        pass # Current player has worse hand
                elif (players[player].hand[0][0] > players[winners[-1]].hand[0][0]):
                    winners = [player]
                else:
                    pass # Current player has worse hand
            elif hand_type == PokerHands.PH_PAIR:
                if (players[player].hand[0][0] == players[winners[-1]].hand[0][0]): # Check pair
                    if (players[player].hand[-3][0] == players[winners[-1]].hand[-3][0]): # Check high card
                        if (players[player].hand[-2][0] == players[winners[-1]].hand[-2][0]): # Check next high card
                            if (players[player].hand[-1][0] == players[winners[-1]].hand[-1][0]): # Check next next high card
                                winners.append(player)
                            elif (players[player].hand[-1][0] > players[winners[-1]].hand[-1][0]):
                                winners = [player]
                            else:
                                pass # Current player has worse hand
                        elif (players[player].hand[-2][0] > players[winners[-1]].hand[-2][0]):
                            winners = [player]
                        else:
                            pass # Current player has worse hand
                    elif (players[player].hand[-3][0] > players[winners[-1]].hand[-3][0]):
                        winners = [player]
                    else:
                        pass # Current player has worse hand
                elif (players[player].hand[0][0] > players[winners[-1]].hand[0][0]):
                    winners = [player]
                else:
                    pass # Current player has worse hand
            else:
                pass # All enum options already covered
        elif players[player].hand_type > players[winners[-1]].hand_type:
            winners = [player] # Player has better hand
        else:
            pass # Player has worse hand

    # Award winnings
    if winners.size() > 1:
        # Integer division and modulo used to handle a pot that must be split unevenly
        @warning_ignore("integer_division")
        var split_winnings = pot / winners.size()
        var split_remainder = pot % winners.size()
        for winner in winners:
            players[winner].balance += split_winnings
            if split_remainder:
                players[winner].balance += 1
                split_remainder -= 1
    else:
        players[winners[0]].balance += pot

    for winner in winners:
        players[winner].winner = true

func get_longest(longest : Array, next : Array) -> Array:
    if next.size() > longest.size():
        return next
    else:
        return longest # Assumes earlier array has higher value if equal in size

func get_hand_indices(hand_dict : Dictionary, hand : Array) -> Array:
    var hand_indices = Array()
    for card in hand:
        hand_indices.append(hand_dict[card])
    return hand_indices

func get_client_end_game_table_data() -> Dictionary:
    var end_game_table_data = {}
    for player in players:
        end_game_table_data[player] = {'status': players[player].status,
                                       'hand_indices': players[player].hand_indices,
                                       'winner': players[player].winner}
    return end_game_table_data

func get_client_end_game_results_data() -> Array:
    var end_game_results_dialog_data = Array()
    for player in players:
        end_game_results_dialog_data.append({'id': player,
                                             'name': players[player].player_name,
                                             'winnings': players[player].balance - players[player].initial_balance,
                                             'balance': players[player].balance})
    return end_game_results_dialog_data

func get_player_pockets() -> Dictionary:
    var player_pockets = {}
    if players_in_hand.size() > 1: # Player does not reveal hand if everyone else folds
        for player in players_in_hand:
            player_pockets[player] = players[player].pocket
    return player_pockets

class player_data:
    var player_name : String
    var ready : bool
    var balance : int
    var initial_balance : int
    var pocket : Array = Array()
    var curr_bet : int
    var status : String
    var hand : Array = Array()
    var hand_type : int
    var hand_indices : Array = Array()
    var winner : bool

    func _init(p_player_name : String, starting_balance) -> void:
        player_name = p_player_name
        ready = false
        balance = starting_balance
        initial_balance = balance
        curr_bet = 0
        status = ''
        hand_type = PokerHands.PH_DEFAULT
        winner = false

    func is_full_dealt() -> bool:
        return pocket.size() == 2
