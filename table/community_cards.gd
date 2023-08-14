extends Node2D

func show_flop(flop1_val, flop2_val, flop3_val):
    $Flop1.set_region_rect(Rect2(flop1_val[0]*130, flop1_val[1]*180, 130, 180))
    $Flop2.set_region_rect(Rect2(flop2_val[0]*130, flop2_val[1]*180, 130, 180))
    $Flop3.set_region_rect(Rect2(flop3_val[0]*130, flop3_val[1]*180, 130, 180))
    $Flop1.visible = true
    $Flop2.visible = true
    $Flop3.visible = true
    $Burn.visible = true

func show_turn(turn_val):
    $Turn.set_region_rect(Rect2(turn_val[0]*130, turn_val[1]*180, 130, 180))
    $Turn.visible = true

func show_river(river_val):
    $River.set_region_rect(Rect2(river_val[0]*130, river_val[1]*180, 130, 180))
    $River.visible = true

func clear_cards():
    $Flop1.visible = false
    $Flop2.visible = false
    $Flop3.visible = false
    $Turn.visible = false
    $River.visible = false
    $Burn.visible = false
