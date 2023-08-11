extends Node2D

var pot = 0

func set_pot(new_pot):
    pot = new_pot

    if pot > 0:
        #TO-DO - Adjust percentages
        if pot >= (0.8 * GameProperties.total_game_balance):
            $Chips1.set_region_rect(Rect2(144, 0, 36, 36))
            $Chips2.set_region_rect(Rect2(144, 0, 36, 36))
        elif pot >= (0.6 * GameProperties.total_game_balance):
            $Chips1.set_region_rect(Rect2(108, 0, 36, 36))
            $Chips1.set_region_rect(Rect2(108, 0, 36, 36))
        elif pot >= (0.4 * GameProperties.total_game_balance):
            $Chips1.set_region_rect(Rect2(72, 0, 36, 36))
            $Chips1.set_region_rect(Rect2(72, 0, 36, 36))
        elif pot >= (0.2 * GameProperties.total_game_balance):
            $Chips1.set_region_rect(Rect2(36, 0, 36, 36))
            $Chips1.set_region_rect(Rect2(36, 0, 36, 36))
        else:
            $Chips1.set_region_rect(Rect2(12, 0, 24, 36))
            $Chips1.set_region_rect(Rect2(12, 0, 24, 36))

        $Star1.visible = false
        $Star2.visible = false
        $Chips1.visible = true
        $Chips2.visible = true

        $PotLabel.text = "$" + str(pot)
    else:
        $Star1.visible = true
        $Star2.visible = true
        $Chips1.visible = false
        $Chips2.visible = false
        $PotLabel.text = ""


