extends TextureButton

func set_text(text):
    $ButtonLabel.text = text

func enable_button():
    $DisabledMask.visible = false
    self.disabled = false

func disable_button():
    $DisabledMask.visible = true
    self.disabled = true
