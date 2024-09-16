extends Node2D

var balance = 0
var blind_button_value = PokerTypes.BlindButtons.BB_NONE
var cards_dealt = 0

func set_blind_button(new_blind_button):
    blind_button_value = new_blind_button

    if blind_button_value == PokerTypes.BlindButtons.BB_NONE:
        $BlindButton.visible = false
    else:
        if new_blind_button == PokerTypes.BlindButtons.BB_DEALER:
            $BlindButton.set_region_rect(Rect2(0, 0, 36, 36))
        elif new_blind_button == PokerTypes.BlindButtons.BB_SMALL_BLIND:
            $BlindButton.set_region_rect(Rect2(36, 0, 36, 36))
        elif new_blind_button == PokerTypes.BlindButtons.BB_BIG_BLIND:
            $BlindButton.set_region_rect(Rect2(72, 0, 36, 36))

        $BlindButton.visible = true

func set_hand(hand):
    $Card1.set_region_rect(Rect2(hand[0][0]*130, hand[0][1]*180, 130, 180))
    $Card2.set_region_rect(Rect2(hand[1][0]*130, hand[1][1]*180, 130, 180))

func deal_next():
    assert(cards_dealt < 2)

    cards_dealt += 1

    if cards_dealt == 1:
        $Card1.visible = true
    if cards_dealt == 2:
        $Card2.visible = true

func get_full_dealt():
    return cards_dealt == 2

func fold():
    # Use modulate to darken cards
    $Card1.modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)
    $Card2.modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)

func clear_hand():
    set_blind_button(PokerTypes.BlindButtons.BB_NONE)

    cards_dealt = 0

    $Card1.visible = false
    $Card2.visible = false
    $Card1.modulate = Color(1, 1, 1)
    $Card2.modulate = Color(1, 1, 1)

func set_status(new_status):
    $StatusBlock/StatusLabel.text = new_status

func set_balance(new_balance):
    balance = new_balance

    if balance > 0:
        #TO-DO - Adjust percentages
        if balance >= (0.8 * GameProperties.total_game_balance):
            $StatusBlock/Chips.set_region_rect(Rect2(144, 0, 36, 36))
        elif balance >= (0.6 * GameProperties.total_game_balance):
            $StatusBlock/Chips.set_region_rect(Rect2(108, 0, 36, 36))
        elif balance >= (0.4 * GameProperties.total_game_balance):
            $StatusBlock/Chips.set_region_rect(Rect2(72, 0, 36, 36))
        elif balance >= (0.2 * GameProperties.total_game_balance):
            $StatusBlock/Chips.set_region_rect(Rect2(36, 0, 36, 36))
        else:
            $StatusBlock/Chips.set_region_rect(Rect2(12, 0, 24, 36))

        $StatusBlock/Chips.visible = true
    else:
        $StatusBlock/Chips.visible = false

    $StatusBlock/BalanceLabel.text = "$" + str(balance)

func set_turn(is_turn):
    $TurnIndicator.visible = is_turn
