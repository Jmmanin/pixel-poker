extends Node2D

var cards = Array()
var cards_dealt = -1

func add_cards(p_cards):
    cards.append_array(p_cards)

func deal_next():
    if cards.size() >= cards_dealt + 1:
        if cards_dealt == -1:
            $Burn.visible = true
            cards_dealt += 1
        elif cards_dealt == 0:
            $Flop1.set_region_rect(Rect2(cards[0][0]*130, cards[0][1]*180, 130, 180))
            $Flop1.visible = true
            cards_dealt += 1
        elif cards_dealt == 1:
            $Flop2.set_region_rect(Rect2(cards[1][0]*130, cards[1][1]*180, 130, 180))
            $Flop2.visible = true
            cards_dealt += 1
        elif cards_dealt == 2:
            $Flop3.set_region_rect(Rect2(cards[2][0]*130, cards[2][1]*180, 130, 180))
            $Flop3.visible = true
            cards_dealt += 1
        elif cards_dealt == 3:
            $Turn.set_region_rect(Rect2(cards[3][0]*130, cards[3][1]*180, 130, 180))
            $Turn.visible = true
            cards_dealt += 1
        elif cards_dealt == 4:
            $River.set_region_rect(Rect2(cards[4][0]*130, cards[4][1]*180, 130, 180))
            $River.visible = true
            cards_dealt += 1
        else:
            pass # There are only 5 cards to be dealt max

func is_full_dealt():
    return cards.size() == cards_dealt

func clear_cards():
    $Flop1.visible = false
    $Flop2.visible = false
    $Flop3.visible = false
    $Turn.visible = false
    $River.visible = false
    $Burn.visible = false
