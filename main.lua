require('gameConstants')
button = require('button')
opponent = require('opponent')
player = require('player')

function love.load()
   love.window.setMode(1280, 720)
   love.graphics.setDefaultFilter('nearest', 'nearest', 1)
   love.window.setTitle('Pixel Poker')

   myName = 'John'
   playerNames = {'Shawn', 'Jeremy', 'John', 'Jeff', 'Geoff', 'Steven', 'Stephen', 'Sean'}
   numPlayers = table.getn(playerNames)

   local myID = 0
   for i, name in ipairs(playerNames)
   do
      if name == myName
      then
         myID = i
         break
      end
   end

   table.remove(playerNames, myID)

   for i=1, myID-1
   do
      temp = table.remove(playerNames, 1)
      table.insert(playerNames, temp)
   end

   playerDict = {}
   playerList = {}

   for i=1, table.getn(playerNames)
   do
      local newOpponent = opponent.new(i, gameConstants.opponentOrigins[i], playerNames[i], gameConstants.initialBalance)
      playerDict[playerNames[i]] = newOpponent
      table.insert(playerList, newOpponent)
   end

   local myPlayer = player.new(numPlayers, gameConstants.initialBalance)
   playerDict[myName] = myPlayer
   table.insert(playerList, myPlayer)

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

   playerDict['Jeff'].balance = 1
   playerDict['Geoff'].balance = 15
   playerDict['Steven'].balance = 300
   playerDict['Stephen'].balance = 600
   playerDict['Sean'].balance = 900
   playerDict['Sean'].isTurn = true
   playerDict['Sean'].token = gameConstants.tokenEnum['dealer']
   playerDict['Shawn'].balance = 1111
   playerDict['Shawn'].token = gameConstants.tokenEnum['smallBlind']
   playerDict['Jeremy'].token = gameConstants.tokenEnum['bigBlind']

   playerDict['John']:setHand('2s', '7s')
   currentTurn = playerDict['Sean'].position
   dealStart = playerDict['Shawn'].position
   dealPosition = dealStart
   dealing = true
   updateTime = 0
end

function love.draw()
   love.graphics.draw(gameConstants.gameBg)

   for _, currPlayer in pairs(playerDict)
   do
      currPlayer:draw()
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
         playerList[dealPosition]:dealNext()
         dealPosition = (dealPosition%numPlayers)+1

         updateTime = 0
      end

      if dealPosition == dealStart-1
         and playerList[dealPosition].cards == gameConstants.dealtEnum['dealt']
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
   playerList[currentTurn].isTurn = false
   currentTurn = (currentTurn%numPlayers)+1
   playerList[currentTurn].isTurn = true
end

function reverseTurn()
   playerList[currentTurn].isTurn = false
   currentTurn = currentTurn-1
   if currentTurn == 0
   then
      currentTurn = numPlayers
   end
   playerList[currentTurn].isTurn = true
end