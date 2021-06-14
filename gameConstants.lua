gameConstants = {}

gameConstants.gameBg = love.graphics.newImage('resources/gameBg.png')

gameConstants.opponentBg = love.graphics.newImage('resources/opponentBg.png')
gameConstants.opponentTurnOverlay = love.graphics.newImage('resources/opponentTurn.png')
gameConstants.opponentOrigins = {
   {12, 383},
   {12, 195},
   {187, 14},
   {507, 8},
   {827, 14},
   {1002, 195},
   {1002, 383}
}

gameConstants.opponentNameFont = love.graphics.newFont('resources/monogram.ttf', 65, 'mono')
gameConstants.opponentNameX_Offsets = {123, 111, 99, 87, 75, 63, 51, 39, 27, 15}
gameConstants.opponentNameY_OffsetDescender = -4
gameConstants.opponentNameY_OffsetNoDescender = -8

gameConstants.smallChipPiles = {
   love.graphics.newImage('resources/opponentChipPile1.png'),
   love.graphics.newImage('resources/opponentChipPile2.png'),
   love.graphics.newImage('resources/opponentChipPile3.png'),
   love.graphics.newImage('resources/opponentChipPile4.png'),
   love.graphics.newImage('resources/opponentChipPile5.png')
}
gameConstants.opponentChipX_Offsets = {100, 89, 79, 68}
gameConstants.opponentChipY_Offset = 54

gameConstants.opponentBalanceFont = love.graphics.newFont('resources/monogram.ttf', 55, 'mono')
gameConstants.opponentBalanceX_Offsets = {128, 117, 107, 96}
gameConstants.opponentBalanceY_Offset = 41
gameConstants.initialBalance = 1234

gameConstants.chipPileSizeFactor = gameConstants.initialBalance / table.getn(gameConstants.smallChipPiles)
gameConstants.smallestOpponentChipPileX_Offset = -4

gameConstants.dealerToken = love.graphics.newImage('resources/dealer.png')
gameConstants.smallBlindToken = love.graphics.newImage('resources/smallBlind.png')
gameConstants.bigBlindToken = love.graphics.newImage('resources/bigBlind.png')
gameConstants.tokenOffset = {8, 103}

gameConstants.tokenEnum = {
   none = 1,
   dealer = 2,
   smallBlind = 3,
   bigBlind = 4
}

gameConstants.smallCardBacks = love.graphics.newImage('resources/smallBacks.png')
gameConstants.smallFoldOverlay = love.graphics.newImage('resources/smallFoldOverlay.png')
gameConstants.halfDealtQuad = love.graphics.newQuad(0, 0, 45, 67, gameConstants.smallCardBacks:getWidth(), gameConstants.smallCardBacks:getHeight())
gameConstants.smallCardBacksX_Offset = 28
gameConstants.smallCardBacksX_ExtraTokenOffset = 20
gameConstants.smallCardBacksY_Offset = 88

gameConstants.dealtEnum = {
   none = 1,
   halfDealt = 2,
   dealt = 3
}

return gameConstants