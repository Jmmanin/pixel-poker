extends Node

func set_title(title):
    $DialogBoxFrame/TitleLabel.text = title

func set_message(message):
    $DialogBoxFrame/MessageLabel.text = message

func set_single_button_text(button_text):
    $DialogBoxFrame/CenterButton/ButtonLabel.text = button_text
    $DialogBoxFrame/CenterButton.visible = true

func set_double_button_text(button1_text, button2_text):
    $DialogBoxFrame/LeftButton/ButtonLabel.text  = button1_text
    $DialogBoxFrame/RightButton/ButtonLabel.text = button2_text

    $DialogBoxFrame/LeftButton.visible   = true
    $DialogBoxFrame/RightButton.visible  = true
