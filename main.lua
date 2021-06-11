require('gameConstants')
opponent = require('opponent')

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

   currentTurn = 5
   opponents[5].isTurn = true
   opponents[1].balance = 1
   opponents[2].balance = 15
   opponents[3].balance = 300
   opponents[4].balance = 600
   opponents[5].balance = 900
   opponents[6].balance = 1111
   updateTime = 0
end

function love.draw()
   love.graphics.draw(gameConstants.gameBg)

   for i,opponent in ipairs(opponents)
   do
      opponent:draw()
   end
end

-- function love.update(dt)
   -- updateTime = updateTime + dt
   -- if updateTime >= 1
   -- then
      -- opponents[currentTurn].isTurn = false
      -- currentTurn = (currentTurn % 7) +1
      -- opponents[currentTurn].isTurn = true

      -- updateTime = 0
   -- end
-- end

function love.mousereleased(x, y, button)
   if button == 1
   then
      opponents[currentTurn].isTurn = false
      currentTurn = (currentTurn % 7) +1
      opponents[currentTurn].isTurn = true
   end
end