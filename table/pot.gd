extends Node2D

var total_game_balance = 0
var pots = [0]

func set_pots(new_pots):
    pots = new_pots

    var total_val = pots[0]
    var total_str = '$' + str(pots[0])

    var index = 1
    while index < pots.size():
        total_str += '+$' + str(pots[index])
        total_val += pots[index]
        index += 1

    if total_str.length() <= 7:
        $PixelLabel.visible = true
        $LeftDivider.visible = true
        $RightDivider.visible = true
        $PokerLabel.visible = true

        $PotValueLabel.label_settings.font_size = 87
        $PotValueLabel.position = Vector2(46, -15)
    elif total_str.length() == 8:
        $PixelLabel.visible = true
        $LeftDivider.visible = false
        $RightDivider.visible = false
        $PokerLabel.visible = true

        $PotValueLabel.label_settings.font_size = 87
        $PotValueLabel.position = Vector2(46, -15)
    elif (total_str.length() > 8) and (total_str.length() <= 16):
        $PixelLabel.visible = false
        $LeftDivider.visible = false
        $RightDivider.visible = false
        $PokerLabel.visible = false

        $PotValueLabel.label_settings.font_size = 87
        $PotValueLabel.position = Vector2(46, -15)
    elif (total_str.length() > 17) and (total_str.length() <= 22):
        $PixelLabel.visible = false
        $LeftDivider.visible = false
        $RightDivider.visible = false
        $PokerLabel.visible = false

        $PotValueLabel.label_settings.font_size = 64
        $PotValueLabel.position = Vector2(45, -14)
    else:
        $PixelLabel.visible = false
        $LeftDivider.visible = false
        $RightDivider.visible = false
        $PokerLabel.visible = false

        $PotValueLabel.label_settings.font_size = 32
        $PotValueLabel.position = Vector2(44, -13)

    if total_val > 0:
        # TO-DO - Adjust percentages
        if total_val >= (0.8 * total_game_balance):
            $LeftChips.set_region_rect(Rect2(144, 0, 36, 36))
            $RightChips.set_region_rect(Rect2(144, 0, 36, 36))
        elif total_val >= (0.6 * total_game_balance):
            $LeftChips.set_region_rect(Rect2(108, 0, 36, 36))
            $RightChips.set_region_rect(Rect2(108, 0, 36, 36))
        elif total_val >= (0.4 * total_game_balance):
            $LeftChips.set_region_rect(Rect2(72, 0, 36, 36))
            $RightChips.set_region_rect(Rect2(72, 0, 36, 36))
        elif total_val >= (0.2 * total_game_balance):
            $LeftChips.set_region_rect(Rect2(36, 0, 36, 36))
            $RightChips.set_region_rect(Rect2(36, 0, 36, 36))
        else:
            $LeftChips.set_region_rect(Rect2(12, 0, 24, 36))
            $RightChips.set_region_rect(Rect2(12, 0, 24, 36))

        $LeftStar.visible = false
        $RightStar.visible = false
        $LeftChips.visible = true
        $RightChips.visible = true

        $PotValueLabel.text = total_str
    else:
        $LeftStar.visible = true
        $RightStar.visible = true
        $LeftChips.visible = false
        $RightChips.visible = false
        $PotValueLabel.text = ""

    if pots.size() == 2:
        $TopOutlineMain.visible = false
        $TopOutlineMainSplit.visible = true
        $TopOutlineMainSplits.visible = false
    elif pots.size() > 2:
        $TopOutlineMain.visible = false
        $TopOutlineMainSplit.visible = false
        $TopOutlineMainSplits.visible = true
    else:
        $TopOutlineMain.visible = true
        $TopOutlineMainSplit.visible = false
        $TopOutlineMainSplits.visible = false
