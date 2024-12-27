extends TextureRect

var balance = 0
var blind_button_value = PokerTypes.BlindButtons.BB_NONE
var cards_dealt = 0
var revealed = false
var hand_indices = Array()

func set_turn(is_turn):
    $TurnIndicator.visible = is_turn

func set_op_name(op_name):
    # Adjust y pos to properly vertically center name if new name has descenders
    var descender_regex = RegEx.new()
    descender_regex.compile('(g|j|p|q|y)')
    var has_descenders = descender_regex.search(op_name)
    var had_descenders = descender_regex.search($NameLabel.text)
    if has_descenders and not had_descenders:
        $NameLabel.position -= Vector2(0, 4)
    if had_descenders and not has_descenders:
        $NameLabel.position += Vector2(0, 4)

    $NameLabel.text = op_name

func set_balance(new_balance):
    balance = new_balance

    if balance > 0:
        #TO-DO - Adjust percentages
        if balance >= (0.8 * GameProperties.total_game_balance):
            $Chips.set_region_rect(Rect2(96, 0, 24, 24))
        elif balance >= (0.6 * GameProperties.total_game_balance):
            $Chips.set_region_rect(Rect2(72, 0, 24, 24))
        elif balance >= (0.4 * GameProperties.total_game_balance):
            $Chips.set_region_rect(Rect2(48, 0, 24, 24))
        elif balance >= (0.2 * GameProperties.total_game_balance):
            $Chips.set_region_rect(Rect2(24, 0, 24, 24))
        else:
            $Chips.set_region_rect(Rect2(8, 0, 16, 24))

        $Chips.visible = true
    else:
        $Chips.visible = false

    $BalanceLabel.text = '$' + str(balance)

func set_blind_button(new_blind_button):
    if new_blind_button == PokerTypes.BlindButtons.BB_DEALER:
        $BlindButton.set_region_rect(Rect2(0, 0, 36, 36))
    elif new_blind_button == PokerTypes.BlindButtons.BB_SMALL_BLIND:
        $BlindButton.set_region_rect(Rect2(36, 0, 36, 36))
    elif new_blind_button == PokerTypes.BlindButtons.BB_BIG_BLIND:
        $BlindButton.set_region_rect(Rect2(72, 0, 36, 36))
    else:
        pass # No blind button

    # Adjust x pos of cards to properly horizontally center things
    if new_blind_button != blind_button_value:
        # On transition to no blind button
        if new_blind_button == PokerTypes.BlindButtons.BB_NONE:
            $CardParent.position -= Vector2(20, 0)
            $BlindButton.visible = false
        # On transition to some blind button
        elif blind_button_value == PokerTypes.BlindButtons.BB_NONE:
            $CardParent.position += Vector2(20, 0)
            $BlindButton.visible = true
        else:
            pass # No change needed

    blind_button_value = new_blind_button

func deal_next():
    assert(cards_dealt < 2)

    cards_dealt += 1

    if cards_dealt == 1:
        $CardParent/CardBack1.visible = true
    if cards_dealt == 2:
        $CardParent/CardBack2.visible = true

func is_full_dealt():
    return cards_dealt == 2

func set_status(new_status, make_visible = true):
    $StatusLabel.visible = make_visible

    var long_string = false
    for line in new_status.split('\n'):
        if line.length() >= 7:
            long_string = true
            break

    $StatusLabel.label_settings.font_size = 32 if long_string else 48
#    var ls = $StatusLabel.label_settings
#    if long_string:
#        ls.font_size = 32
#    else:
#        ls.font_size = 48

    $StatusLabel.text = new_status

func fold():
    $CardParent/CardBack1.modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)
    $CardParent/CardBack2.modulate = Color(137.0/255.0, 137.0/255.0, 137.0/255.0)
    revealed = true

func set_hand(cards):
    $CardParent/Card1.set_region_rect(Rect2(cards[0][0]*45, cards[0][1]*67, 45, 67))
    $CardParent/Card2.set_region_rect(Rect2(cards[1][0]*45, cards[1][1]*67, 45, 67))

func reveal_hand():
    $CardParent/Card1.visible = true
    $CardParent/Card2.visible = true
    $CardParent/CardBack1.visible = false
    $CardParent/CardBack2.visible = false
    $StatusLabel.visible = true
    revealed = true

func set_card_highlight(highlight1, highlight2):
    $CardParent/Card1/CardHighlight.visible = highlight1
    $CardParent/Card2/CardHighlight.visible = highlight2
