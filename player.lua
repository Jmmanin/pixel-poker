require('gameConstants')

player = {}
player.__index = player

function player.new(position, initialBalance)
   newPlayer = {
      position = position,
      balance = initialBalance,
      isTurn = false,
      token = gameConstants.tokenEnum['none'],
      hand = {},
      dealtStatus = gameConstants.dealtEnum['none'],
      folded = false
   }

   setmetatable(newPlayer, player)

   return newPlayer
end

function player:setHand(card1, card2)
   self.hand = {
      love.graphics.newImage(gameConstants.deckFolder..card1..'.png'),
      love.graphics.newImage(gameConstants.deckFolder..card2..'.png')
   }
end

function player:dealNext()
   if self.dealtStatus == gameConstants.dealtEnum['none']
   then
      self.dealtStatus = gameConstants.dealtEnum['halfDealt']
   elseif self.dealtStatus == gameConstants.dealtEnum['halfDealt']
   then
      self.dealtStatus = gameConstants.dealtEnum['dealt']
   end
end

function player:draw()
   local chipPileSize = math.ceil(self.balance/gameConstants.chipPileSizeFactor)
   local balanceLen = math.floor(math.log10(self.balance)+1)

   local chipX = gameConstants.playerChipX_Origins[balanceLen]
   local balanceX = gameConstants.playerBalanceX_Origins[balanceLen]

   if chipPileSize == 1
   then
      chipX = chipX+gameConstants.smallestBigChipPileX_Offset
      balanceX = balanceX+gameConstants.smallestBigChipPileX_Offset
   end

   love.graphics.draw(gameConstants.bigChipPiles[chipPileSize], chipX, gameConstants.playerChipY_Origin)
   love.graphics.print({gameConstants.black, '$' .. self.balance}, gameConstants.playerBalanceFont, balanceX, gameConstants.playerBalanceY_Origin)

   if self.token ~= gameConstants.tokenEnum['none']
   then
      if self.token == gameConstants.tokenEnum['dealer']
      then
         love.graphics.draw(gameConstants.dealerToken, gameConstants.playerTokenOrigin[1], gameConstants.playerTokenOrigin[2])
      elseif self.token == gameConstants.tokenEnum['smallBlind']
      then
         love.graphics.draw(gameConstants.smallBlindToken, gameConstants.playerTokenOrigin[1], gameConstants.playerTokenOrigin[2])
      elseif self.token == gameConstants.tokenEnum['bigBlind']
      then
         love.graphics.draw(gameConstants.bigBlindToken, gameConstants.playerTokenOrigin[1], gameConstants.playerTokenOrigin[2])
      end
   end

   if self.dealtStatus == gameConstants.dealtEnum['halfDealt']
   then
      love.graphics.draw(self.hand[1], gameConstants.playerCard1_X_Origin, gameConstants.playerCardY_Origin)
   elseif self.dealtStatus == gameConstants.dealtEnum['dealt']
   then
      love.graphics.draw(self.hand[1], gameConstants.playerCard1_X_Origin, gameConstants.playerCardY_Origin)
      love.graphics.draw(self.hand[2], gameConstants.playerCard2_X_Origin, gameConstants.playerCardY_Origin)

      if self.folded
      then
         love.graphics.draw(gameConstants.bigFoldOverlay, gameConstants.playerCard1_X_Origin, gameConstants.playerCardY_Origin)
      end
   end

   if self.isTurn
   then
      love.graphics.draw(gameConstants.playerTurnOverlay, gameConstants.playerOrigin[1], gameConstants.playerOrigin[2])
   end
end

return player