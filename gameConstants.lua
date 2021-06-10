gameConstants = {
   gameBg = love.graphics.newImage('resources/gameBg.png'),

   opponentBg = love.graphics.newImage('resources/opponentBg.png'),

   opponentTurnOverlay = love.graphics.newImage('resources/opponentTurn.png'),

   opponentOrigins = {
      {12, 383},
      {12, 195},
      {187, 14},
      {507, 8},
      {827, 14},
      {1002, 195},
      {1002, 383}
   },

   opponentNameFont = love.graphics.newFont('resources/monogram.ttf', 65, 'mono'),

   opponentNameY_OffsetDecender = -5,

   opponentNameY_OffsetNoDecender = -9,

   opponentNameX_Offsets = {123, 111, 99, 87, 75, 63, 51, 39, 27, 15}
}

return gameConstants