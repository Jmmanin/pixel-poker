class_name HostData

enum PokerHands {PH_FOLD = -1, PH_DEFAULT = 0, PH_HIGH_CARD, PH_PAIR, PH_TWO_PAIR, PH_THREE_OF_A_KIND, PH_STRAIGHT, PH_FLUSH, PH_FULL_HOUSE, PH_FOUR_OF_A_KIND, PH_STRAIGHT_FLUSH, PH_ROYAL_FLUSH}

var game_info : PokerTypes.GameInfo

var game_starting : bool

var players : Dictionary # [int, player_data]

var deck : Array

var dealer_index : int
var players_in_hand : Array
var player_turn_index : int

var pots : Array
var start_pot_index : int
var pot_players : Array
var players_exactly_all_in : Array

var min_raise : int

var game_phase : int
var once_around_the_table : bool
var phase_complete : bool
var all_players_all_in : bool

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

func start_game(new_dealer_index : int) -> void:
    # Create and shuffle deck
    deck = Array()
    for i in range(13):
        for j in range(4):
            deck.append([i, j])
    deck.shuffle()

    # BEGIN OVERRIDES FOR TESTING
    new_dealer_index = 2

    deck[0]  = [12, 0] # A-S
    deck[1]  = [ 3, 0] # 5-S
    deck[2]  = [ 9, 3] # J-D
    deck[3]  = [ 7, 0] # 9-S
    deck[4]  = [ 5, 0] # 7-S
    deck[5]  = [ 9, 1] # J-C
    deck[6]  = [ 1, 0] # 3-S
    deck[7]  = [12, 3] # A-D
    #deck[8] # Flop burn card - DNC
    deck[9]  = [ 7, 2] # 9-H
    deck[10] = [ 5, 2] # 7-H
    deck[11] = [11, 2] # K-H
    #deck[12] # Turn burn card - DNC
    deck[13] = [10, 2] # Q-H
    #deck[14] # River burn card - DNC
    deck[15] = [ 6, 3] # 8-D
    # END OVERRIDES

    # Pick dealer and arrange players in hand in correct order (left of dealer -> dealer)
    dealer_index = new_dealer_index

    var player_ids = players.keys()
    var dealer = player_ids[dealer_index]

    player_turn_index = (dealer_index + 1) % players.size()
    players_in_hand = Array()
    while player_turn_index != dealer_index:
        players_in_hand.append(player_ids[player_turn_index])
        player_turn_index = (player_turn_index + 1) % players.size()
    players_in_hand.append(dealer)

    player_turn_index = 0

    # BEGIN OVERRIDES FOR TESTING
    players[players_in_hand[0]].balance = 100
    players[players_in_hand[1]].balance = 30
    players[players_in_hand[2]].balance = 40
    players[players_in_hand[3]].balance = 80
    # END OVERRIDES

    # Reset player state
    for i in players.size():
        var player_id = players_in_hand[i]

        players[player_id].ready = false
        players[player_id].initial_balance = players[player_id].balance
        players[player_id].pocket = Array()
        players[player_id].curr_bet = 0
        players[player_id].status  = ""
        players[player_id].hand = Array()
        players[player_id].hand_type = PokerHands.PH_DEFAULT
        players[player_id].hand_indices = Array()
        players[player_id].winner = false

    # Deal cards
    for i in players.size() * 2:
        players[players_in_hand[i % players.size()]].pocket.push_back(deck.pop_front())

    # Create initial main pot
    pots = [pot_elem.new()]
    start_pot_index = 0

    pot_players = [players_in_hand.duplicate()]

    players_exactly_all_in = Array()

    # Set up initial game parameters based on prebet type
    # TO-DO - Handle cases where player can't afford ante/blind (immediately all-in)
    if game_info.prebet_type == PokerTypes.PrebetTypes.PB_ANTE:
        for player in players:
            player.balance -= game_info.ante_amount

        pots[-1].pot_amount = game_info.ante_amount * players.size()
        min_raise = game_info.ante_amount
    else:
        if players.size() > 2:
            players[players_in_hand[0]].balance -= game_info.small_blind_amount
            players[players_in_hand[0]].curr_bet = game_info.small_blind_amount
            players[players_in_hand[0]].status = 'Bet\n$' + str(game_info.small_blind_amount)

            players[players_in_hand[1]].balance -= game_info.big_blind_amount
            players[players_in_hand[1]].curr_bet = game_info.big_blind_amount
            players[players_in_hand[1]].status = 'Bet\n$' + str(game_info.big_blind_amount)

            # Place player after big blind as first in the betting order just for the initial betting round
            players_in_hand.append_array([players_in_hand.pop_front(), players_in_hand.pop_front()])
        else:
            # In two-player blind games, the dealer also has the small blind while the other player has the big blind
            players[players_in_hand[1]].balance -= game_info.small_blind_amount
            players[players_in_hand[1]].curr_bet = game_info.small_blind_amount
            players[players_in_hand[1]].status = 'Bet\n$' + str(game_info.small_blind_amount)

            players[players_in_hand[0]].balance -= game_info.big_blind_amount
            players[players_in_hand[0]].curr_bet = game_info.big_blind_amount
            players[players_in_hand[0]].status = 'Bet\n$' + str(game_info.big_blind_amount)

            # Place dealer as first in the betting order just for the initial betting round
            players_in_hand.append(players_in_hand.pop_front())

        pots[0].pot_amount = game_info.small_blind_amount + game_info.big_blind_amount
        pots[0].bet_amount = game_info.big_blind_amount
        min_raise = pots[0].bet_amount * 2

    game_starting = false
    game_phase = PokerTypes.GamePhases.GP_PRE_FLOP
    once_around_the_table = false
    phase_complete = false
    all_players_all_in = false
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

func get_curr_bet() -> int:
    var curr_bet = 0
    for pot in pots:
        curr_bet += pot.bet_amount
    return curr_bet

func get_pot_amounts() -> Array:
    var pot_amounts = Array()
    for pot in pots:
        pot_amounts.append(pot.pot_amount)
    return pot_amounts

func get_total_game_balance() -> int:
    return game_info.starting_balance * players.size()

func process_player_action(player_id : int, new_bet : int):
    # Fold
    if new_bet == -1:
        players[player_id].status = 'Fold'
        players_in_hand.erase(player_id)

        for players_in_pot in pot_players: # Remove player from contention for all pots
            players_in_pot.erase(player_id)

        # DO NOT increment player turn index
    elif new_bet == 0:
        # Check
        if pots[-1].bet_amount == 0:
            players[player_id].status = 'Check'
        # Call
        else:
            players[player_id].status = 'Call'

            # Apply bet to all split pots as applicable
            var new_curr_bet = 0
            var prev_curr_bet = players[player_id].curr_bet
            for i in range(start_pot_index, pots.size()):
                if prev_curr_bet == 0:
                    new_curr_bet += pots[i].bet_amount
                    pots[i].pot_amount += pots[i].bet_amount

                if prev_curr_bet > 0:
                    prev_curr_bet -= pots[i].bet_amount

                if prev_curr_bet < 0:
                    new_curr_bet -= prev_curr_bet
                    pots[i].pot_amount -= prev_curr_bet
                    prev_curr_bet = 0

            players[player_id].curr_bet = new_curr_bet
            players[player_id].balance -= new_curr_bet

        player_turn_index += 1
    else:
        players[player_id].balance -= (new_bet - players[player_id].curr_bet)

        # Bet/Raise
        if players[player_id].balance > 0:
            if pots[-1].bet_amount == 0:
                players[player_id].status = 'Bet\n$' + str(new_bet)
            else:
                players[player_id].status = 'Raise\n$' + str(new_bet)

            # Apply bet to all split pots as applicable
            var temp_curr_bet = players[player_id].curr_bet
            var temp_new_bet = new_bet
            for i in range(start_pot_index, pots.size()):
                if temp_curr_bet == 0:
                    temp_new_bet -= pots[i].bet_amount
                    if temp_new_bet > 0:
                        pots[i].pot_amount += pots[i].bet_amount
                    else:
                        pots[i].pot_amount += pots[i].bet_amount + temp_new_bet
                        break

                if temp_curr_bet > 0:
                    temp_curr_bet -= pots[i].bet_amount

                if temp_curr_bet < 0:
                    if temp_new_bet >= (temp_curr_bet * -1):
                        temp_new_bet += temp_curr_bet
                        pots[i].pot_amount -= temp_curr_bet
                        temp_curr_bet = 0
                    else:
                        pots[i].pot_amount += temp_new_bet
                        temp_new_bet = 0
                        break

            # Add raise amount (if any) to last pot, or make new split pot, if applicable
            if temp_new_bet > 0:
                if players_exactly_all_in.size() != 0:
                    pots.append(pot_elem.new())
                    pot_players.append(pot_players[-1].duplicate())

                    # Remove all-in players from conetention for new pot
                    for all_in_player in players_exactly_all_in:
                        pot_players[-1].erase(all_in_player)

                pots[-1].bet_amount += temp_new_bet
                pots[-1].pot_amount += temp_new_bet

            players[player_id].curr_bet += new_bet

            # Next raise needs to be by at least as much as this one was
            min_raise = new_bet + temp_new_bet
        # All-in
        else:
            players[player_id].status = 'All-In'

            var new_split_pot_bet_amount = players[player_id].curr_bet + new_bet
            var new_split_index = start_pot_index
            while new_split_index < pots.size():
                new_split_pot_bet_amount -= pots[new_split_index].bet_amount
                if new_split_pot_bet_amount < 0:
                    break
                new_split_index += 1

            # With the logic above, new_split_pot_bet_amount should (now) never be greater than 0
            assert(new_split_pot_bet_amount <= 0, 'Split pot logic issue - new split pot bet amount did not yield valid value (' + str(new_split_pot_bet_amount) + ')')

            # New split pot needed
            if new_split_pot_bet_amount < 0:
                players[player_id].curr_bet += new_bet
                new_split_pot_bet_amount += pots[new_split_index].bet_amount # value of variable is now actually new split pot bet amount

                # Create new split pot
                pots.insert(new_split_index, pot_elem.new())
                pot_players.insert(new_split_index, pot_players[new_split_index].duplicate())

                # Remove player from contention in subsequent pots
                for i in range(new_split_index + 1, pots.size()):
                    pot_players[i].erase(player_id)

                # Set starting value for new acting "main" pot to what it was at the end of
                # the previous round (if applicable)
                if new_split_index == start_pot_index:
                    pots[new_split_index].prev_amount = pots[new_split_index + 1].prev_amount
                    pots[new_split_index + 1].prev_amount = 0

                # Set new split pot bet amount to current player's bet
                # and adjust the bet amount for the pot that was just split
                pots[new_split_index].bet_amount = new_split_pot_bet_amount
                pots[new_split_index + 1].bet_amount -= new_split_pot_bet_amount

                # Reset pots amounts
                for i in range(start_pot_index, pots.size()):
                    pots[i].pot_amount = pots[i].prev_amount

                # Recalculate pot amounts
                for player in players:
                    var remaining_bet = players[player].curr_bet
                    for i in range(start_pot_index, pots.size()):
                        remaining_bet -= pots[i].bet_amount
                        if remaining_bet >= 0:
                            pots[i].pot_amount += pots[i].bet_amount
                        else:
                            pots[i].pot_amount += remaining_bet + pots[i].bet_amount
                            break
            # Exactly all-in (no new split pot needed, yet)
            else:
                # Apply bet to all split pots as applicable
                var temp_curr_bet = players[player_id].curr_bet
                var temp_new_bet = new_bet
                for i in range(start_pot_index, pots.size()):
                    if temp_curr_bet == 0:
                        temp_new_bet -= pots[i].bet_amount
                        if temp_new_bet > 0:
                            pots[i].pot_amount += pots[i].bet_amount
                        else:
                            pots[i].pot_amount += pots[i].bet_amount + temp_new_bet
                            break

                    if temp_curr_bet > 0:
                        temp_curr_bet -= pots[i].bet_amount

                    if temp_curr_bet < 0:
                        if temp_new_bet >= (temp_curr_bet * -1):
                            temp_new_bet += temp_curr_bet
                            pots[i].pot_amount -= temp_curr_bet
                            temp_curr_bet = 0
                        else:
                            pots[i].pot_amount += temp_new_bet
                            break

                players[player_id].curr_bet += new_bet

        player_turn_index += 1

func advance_game_state():
    phase_complete = false

    if player_turn_index >= players_in_hand.size():
        player_turn_index = 0
        once_around_the_table = true

    # Check if all players are all-in
    var all_in_player_count = 0
    for player in players_in_hand:
        if players[player].balance == 0:
            all_in_player_count += 1

    # Skip players that are all-in
    while players[players_in_hand[player_turn_index]].balance == 0:
        player_turn_index += 1
        if player_turn_index >= players_in_hand.size():
            player_turn_index = 0
            once_around_the_table = true

    # TO-DO - Autoplay rest of hand if all, or all less one, players are all-in
    #print("Players all-in = " + str(all_in_player_count))

    var total_round_bet = 0
    for i in range(start_pot_index, pots.size()):
        total_round_bet += pots[i].bet_amount

    # Game advances to next phase once round of betting is complete
    if players_in_hand.size() == 1:
        # TO-DO - PAY OUT POT
        game_phase = PokerTypes.GamePhases.GP_END

        print('game ended by folding')
    elif once_around_the_table and players[players_in_hand[player_turn_index]].curr_bet == total_round_bet:
        player_turn_index = 0
        once_around_the_table = false
        phase_complete = true

        for player in players:
            players[player].curr_bet = 0
            if not ((players[player].status == 'Fold') or (players[player].status == 'All-In')):
                players[player].status = ''

        pots[-1].prev_amount = pots[-1].pot_amount
        start_pot_index = pots.size() - 1

        for pot in pots:
            pot.bet_amount = 0

        min_raise = game_info.ante_amount if game_info.prebet_type == PokerTypes.PrebetTypes.PB_ANTE else game_info.big_blind_amount

        if game_phase == PokerTypes.GamePhases.GP_PRE_FLOP:
            deck.pop_front() # burn card
            community_cards.push_back(deck.pop_front())
            community_cards.push_back(deck.pop_front())
            community_cards.push_back(deck.pop_front())

            # Place players in proper betting order now that initial betting round has completed
            if game_info.prebet_type == PokerTypes.PrebetTypes.PB_BLIND:
                if players.size() > 2:
                    players_in_hand.push_front(players_in_hand.pop_back())
                    players_in_hand.push_front(players_in_hand.pop_back())
                else:
                    players_in_hand.push_front(players_in_hand.pop_back())

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
            printerr('Game has entered unknown state.')
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
            elif multiples[index].size() == 4: # With seven total cards to pick from, only one four-of-a-kind is possible
                foak_index = index
            else:
                pass # Do nothing

        # Check if straight is a straight flush
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

    # Determine the winner(s) of the hand for each pot
    for pot_index in pots.size():
        var winners = Array()

        for player in pot_players[pot_index]:
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
                elif   hand_type == PokerHands.PH_FOUR_OF_A_KIND \
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
                elif   hand_type == PokerHands.PH_FLUSH \
                    or hand_type == PokerHands.PH_HIGH_CARD:
                    var better = false
                    var worse = false
                    # Compare each card in hand, player with higher cards has better hand
                    for player_index in players[player].hand.size():
                        if (players[player].hand[player_index][0] > players[winners[-1]].hand[player_index][0]):
                            better = true
                            break

                        if (players[player].hand[player_index][0] < players[winners[-1]].hand[player_index][0]):
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
            var split_winnings = pots[pot_index].pot_amount / winners.size()
            var split_remainder = pots[pot_index].pot_amount % winners.size()
            for winner in winners:
                players[winner].balance += split_winnings
                if split_remainder:
                    players[winner].balance += 1
                    split_remainder -= 1
        else:
            players[winners[0]].balance += pots[pot_index].pot_amount

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
    var pocket : Array
    var curr_bet : int
    var status : String
    var hand : Array
    var hand_type : int
    var hand_indices : Array
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
        return (pocket.size() == 2)

class pot_elem:
    var pot_amount : int = 0
    var bet_amount : int = 0
    var prev_amount : int = 0
