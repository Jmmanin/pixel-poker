require('gameConstants')

opponent = {}
opponent.__index = opponent

function opponent.new(position, origin, name, initialBalance)
   nameX_Offset = gameConstants.opponentNameX_Offsets[string.len(name)]

   if string.find(name, 'g') == nil
      and string.find(name, 'j') == nil
      and string.find(name, 'p') == nil
      and string.find(name, 'q') == nil
      and string.find(name, 'y') == nil
   then
      nameY_Offset = gameConstants.opponentNameY_OffsetNoDescender
   else
      nameY_Offset = gameConstants.opponentNameY_OffsetDescender
   end

   newOpponent = {
      position = position,
      origin = origin,
      name = name,
      balance = initialBalance,
      isTurn = false,
      nameX_Offset = nameX_Offset,
      nameY_Offset = nameY_Offset,
      token = gameConstants.tokenEnum['none'],
      dealtStatus = gameConstants.dealtEnum['none'],
      folded = false
   }

   setmetatable(newOpponent, opponent)

   return newOpponent
end

function opponent:dealNext()
   if self.dealtStatus == gameConstants.dealtEnum['none']
   then
      self.dealtStatus = gameConstants.dealtEnum['halfDealt']
   elseif self.dealtStatus == gameConstants.dealtEnum['halfDealt']
   then
      self.dealtStatus = gameConstants.dealtEnum['dealt']
   end
end

function opponent:draw()
   love.graphics.draw(gameConstants.opponentBg, self.origin[1], self.origin[2])

   love.graphics.print({gameConstants.black, self.name}, gameConstants.opponentNameFont, self.origin[1]+self.nameX_Offset, self.origin[2]+self.nameY_Offset)

   local chipPileSize = math.ceil(self.balance/gameConstants.chipPileSizeFactor)
   local balanceLen = math.floor(math.log10(self.balance)+1)

   local chipX = self.origin[1]+gameConstants.opponentChipX_Offsets[balanceLen]
   local balanceX = self.origin[1]+gameConstants.opponentBalanceX_Offsets[balanceLen]

   if chipPileSize == 1
   then
      chipX = chipX+gameConstants.smallestSmallChipPileX_Offset
      balanceX = balanceX+gameConstants.smallestSmallChipPileX_Offset
   end

   love.graphics.draw(gameConstants.smallChipPiles[chipPileSize], chipX, self.origin[2]+gameConstants.opponentChipY_Offset)
   love.graphics.print({gameConstants.black, '$' .. self.balance}, gameConstants.opponentBalanceFont, balanceX, self.origin[2]+gameConstants.opponentBalanceY_Offset)

   local cardX = self.origin[1]+gameConstants.smallCardBacksX_Offset

   if self.token ~= gameConstants.tokenEnum['none']
   then
      if self.token == gameConstants.tokenEnum['dealer']
      then
         love.graphics.draw(gameConstants.dealerToken, self.origin[1]+gameConstants.opponentTokenOffset[1], self.origin[2]+gameConstants.opponentTokenOffset[2])
      elseif self.token == gameConstants.tokenEnum['smallBlind']
      then
         love.graphics.draw(gameConstants.smallBlindToken, self.origin[1]+gameConstants.opponentTokenOffset[1], self.origin[2]+gameConstants.opponentTokenOffset[2])
      elseif self.token == gameConstants.tokenEnum['bigBlind']
      then
         love.graphics.draw(gameConstants.bigBlindToken, self.origin[1]+gameConstants.opponentTokenOffset[1], self.origin[2]+gameConstants.opponentTokenOffset[2])
      end

      cardX = cardX+gameConstants.smallCardBacksX_ExtraTokenOffset
   end

   if self.dealtStatus == gameConstants.dealtEnum['halfDealt']
   then
      love.graphics.draw(gameConstants.smallCardBacks, gameConstants.smallhalfDealtQuad, cardX, self.origin[2]+gameConstants.smallCardBacksY_Offset)
   elseif self.dealtStatus == gameConstants.dealtEnum['dealt']
   then
      love.graphics.draw(gameConstants.smallCardBacks, cardX, self.origin[2]+gameConstants.smallCardBacksY_Offset)

      if self.folded
      then
         love.graphics.draw(gameConstants.smallFoldOverlay, cardX, self.origin[2]+gameConstants.smallCardBacksY_Offset)
      end
   end

   if self.isTurn
   then
      love.graphics.draw(gameConstants.opponentTurnOverlay, self.origin[1], self.origin[2])
   end
end

return opponent