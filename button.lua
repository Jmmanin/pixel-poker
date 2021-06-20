require('gameConstants')

button = {}
button.__index = button

function button.new(buttonPos, text, action)
   if buttonPos < 1
      or buttonPos > 4
   then
      error('Attempt to create button with invalid position (must be 1-4).')
   end

   origin = {gameConstants.buttonX_Origins[buttonPos], gameConstants.buttonY_Origin}

   local textLen = string.len(text)

   if textLen > 8
   then
      error('Attempt to create button with text that is too long (max 8 characters).')
   end

   textOffset = {
      gameConstants.buttonTextX_Offsets[textLen],
      gameConstants.buttonTextY_Offset
   }

   newButton = {
      origin = origin,
      text = text,
      action = action,
      textOffset = textOffset,
      active = false,
      clicked = false
   }

   setmetatable(newButton, button)

   return newButton
end

function button:draw(moused)
   if self.active
   then
      local curImage = gameConstants.buttonImage
      if moused
      then
         curImage = gameConstants.buttonClickedImage
      end

      love.graphics.draw(curImage, self.origin[1], self.origin[2])
      love.graphics.print({gameConstants.black, self.text}, gameConstants.buttonFont, self.origin[1]+self.textOffset[1], self.origin[2]+self.textOffset[2])
   end
end

function button:contains(x, y)
   local retVal = false

   if x >= self.origin[1]
      and x <= self.origin[1]+gameConstants.buttonSize[1]
      and y >= self.origin[2]
      and y <= self.origin[2]+gameConstants.buttonSize[2]
   then
      retVal = true
   end

   return retVal
end

return button