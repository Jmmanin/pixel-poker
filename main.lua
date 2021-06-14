require('gameConstants')
opponent = require('opponent')
button = require('button')

function love.load()
   love.window.setMode(1280, 720)
   love.graphics.setDefaultFilter('nearest', 'nearest', 1)
   love.window.setTitle('Pixel Poker')

   numOpponents = 7
   opponentNames = {'Jeff', 'Geoff', 'Steven', 'Stephen', 'Sean', 'Shawn', 'Jeremy'}

   opponents = {}
   for i=1, numOpponents
   do
      local newOpponent = opponent.new(gameConstants.opponentOrigins[i], opponentNames[i], gameConstants.initialBalance)
      table.insert(opponents, newOpponent)
   end

   buttons = {
      ['check'] = button.new(1, 'Check', advanceTurn),
      ['call'] = button.new(1, 'Call', nil),
      ['bet'] = button.new(2, 'Bet', reverseTurn),
      ['raise'] = button.new(2, 'Raise', nil),
      ['fold'] = button.new(3, 'Fold', nil),
      ['settings'] = button.new(4, 'Settings', nil),
      ['allIn'] = button.new(2, 'All-In', nil),
      ['confirm'] = button.new(3, 'Confirm', nil),
      ['cancel'] = button.new(4, 'Cancel', nil)
   }

   buttons['check'].active = true
   buttons['bet'].active = true
   buttons['fold'].active = true
   buttons['settings'].active = true

   currentTurn = 5
   dealStart = 5
   dealPosition = dealStart
   dealing = true

   opponents[1].balance = 1
   opponents[2].balance = 15
   opponents[3].balance = 300
   opponents[4].balance = 600
   opponents[5].balance = 900
   opponents[5].isTurn = true
   opponents[5].token = gameConstants.tokenEnum['dealer']
   opponents[6].balance = 1111
   opponents[6].token = gameConstants.tokenEnum['smallBlind']
   opponents[7].token = gameConstants.tokenEnum['bigBlind']
   updateTime = 0
end

function love.draw()
   love.graphics.draw(gameConstants.gameBg)

   for _, currOpponent in ipairs(opponents)
   do
      currOpponent:draw()
   end

   local x, y = love.mouse.getPosition()

   for _, currButton in pairs(buttons)
   do
      if currButton:contains(x, y)
      then
         currButton:draw(true)
      else
         currButton:draw(false)
      end
   end
end

function love.update(dt)
   if dealing
   then
      updateTime = updateTime + dt
      if updateTime >= 1
      then
         opponents[dealPosition]:dealNext()
         dealPosition = (dealPosition%7)+1

         updateTime = 0
      end

      if dealPosition == dealStart-1
         and opponents[dealPosition].cards == gameConstants.dealtEnum['dealt']
      then
         dealing = false
      end
   end
end

function love.mousepressed(x, y, button)
   if button == 1
   then
      for _, currButton in pairs(buttons)
      do
         if currButton.active
            and currButton:contains(x, y)
         then
            currButton.clicked = true
         end
      end
   end
end

function love.mousereleased(x, y, button)
   if button == 1
   then
      for _, currButton in pairs(buttons)
      do
         if currButton.clicked
            and currButton:contains(x, y)
         then
            currButton.action()
         end

         currButton.clicked = false
      end
   end
end

function advanceTurn()
   opponents[currentTurn].isTurn = false
   currentTurn = (currentTurn%7)+1
   opponents[currentTurn].isTurn = true
end

function reverseTurn()
   opponents[currentTurn].isTurn = false
   currentTurn = currentTurn-1
   if currentTurn == 0
   then
      currentTurn = 7
   end
   opponents[currentTurn].isTurn = true
end