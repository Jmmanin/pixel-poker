require('gameConstants')

opponent = {}
opponent.__index = opponent

function opponent.new(origin, name, initialBalance, isTurn)
   nameOffsetX = gameConstants.opponentNameX_Offsets[string.len(name)]

   if string.find(name, 'g') == nil
      and string.find(name, 'j') == nil
      and string.find(name, 'p') == nil
      and string.find(name, 'q') == nil
      and string.find(name, 'y') == nil
   then
      nameOffsetY = gameConstants.opponentNameY_OffsetDecender
   else
      nameOffsetY = gameConstants.opponentNameY_OffsetNoDecender
   end

   newOpponent = {
      origin = origin,
      name = name,
      balance = initialBalance,
      isTurn = isTurn,
      nameOffsetX = nameOffsetX,
      nameOffsetY = nameOffsetY
   }

   setmetatable(newOpponent, opponent)

   return newOpponent
end

function opponent:draw()
   love.graphics.draw(gameConstants.opponentBg, self.origin[1], self.origin[2])

   love.graphics.print({{0, 0, 0, 255}, self.name}, gameConstants.opponentNameFont, self.origin[1] + self.nameOffsetX, self.origin[2] + self.nameOffsetY)

   if self.isTurn
   then
      love.graphics.draw(gameConstants.opponentTurnOverlay, self.origin[1], self.origin[2])
   end
end

return opponent