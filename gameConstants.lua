gameConstants = {}

-- Global Constants
gameConstants.gameBg = love.graphics.newImage('resources/gameBg.png')
gameConstants.dealerToken = love.graphics.newImage('resources/dealer.png')
gameConstants.smallBlindToken = love.graphics.newImage('resources/smallBlind.png')
gameConstants.bigBlindToken = love.graphics.newImage('resources/bigBlind.png')

gameConstants.black = {0, 0, 0, 255}

gameConstants.initialBalance = 1234
gameConstants.numberOfChipPiles = 5
gameConstants.chipPileSizeFactor = gameConstants.initialBalance / gameConstants.numberOfChipPiles

gameConstants.tokenEnum = {
   none = 1,
   dealer = 2,
   smallBlind = 3,
   bigBlind = 4
}

gameConstants.dealtEnum = {
   none = 1,
   halfDealt = 2,
   dealt = 3
}

-- Player Constants
gameConstants.playerTurnOverlay = love.graphics.newImage('resources/playerTurn.png')

gameConstants.playerOrigin = {508, 623}

gameConstants.bigChipPiles = {
   love.graphics.newImage('resources/bigChipPile1.png'),
   love.graphics.newImage('resources/bigChipPile2.png'),
   love.graphics.newImage('resources/bigChipPile3.png'),
   love.graphics.newImage('resources/bigChipPile4.png'),
   love.graphics.newImage('resources/bigChipPile5.png')
}

gameConstants.playerChipX_Origins = {589, 572, 556, 539}
gameConstants.smallestBigChipPileX_Offset = -6
gameConstants.playerChipY_Origin = 666

gameConstants.playerBalanceFont = love.graphics.newFont('resources/monogram.ttf', 87, 'mono')
gameConstants.playerBalanceX_Origins = {631, 614, 598, 581}
gameConstants.playerBalanceY_Origin = 645

gameConstants.playerTokenOrigin = {441, 576}

-- Opponent Constants
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
gameConstants.opponentNameY_OffsetDescender = -8
gameConstants.opponentNameY_OffsetNoDescender = -4

gameConstants.smallChipPiles = {
   love.graphics.newImage('resources/smallChipPile1.png'),
   love.graphics.newImage('resources/smallChipPile2.png'),
   love.graphics.newImage('resources/smallChipPile3.png'),
   love.graphics.newImage('resources/smallChipPile4.png'),
   love.graphics.newImage('resources/smallChipPile5.png')
}

gameConstants.opponentChipX_Offsets = {100, 89, 79, 68}
gameConstants.smallestSmallChipPileX_Offset = -4
gameConstants.opponentChipY_Offset = 54

gameConstants.opponentBalanceFont = love.graphics.newFont('resources/monogram.ttf', 55, 'mono')
gameConstants.opponentBalanceX_Offsets = {128, 117, 107, 96}
gameConstants.opponentBalanceY_Offset = 41

gameConstants.opponentTokenOffset = {8, 103}

gameConstants.smallCardBacks = love.graphics.newImage('resources/smallBacks.png')
gameConstants.smallFoldOverlay = love.graphics.newImage('resources/smallFoldOverlay.png')
gameConstants.smallhalfDealtQuad = love.graphics.newQuad(0, 0, 45, 67, gameConstants.smallCardBacks:getWidth(), gameConstants.smallCardBacks:getHeight())
gameConstants.smallCardBacksX_Offset = 28
gameConstants.smallCardBacksX_ExtraTokenOffset = 20
gameConstants.smallCardBacksY_Offset = 88

-- Button Constants
gameConstants.buttonImage = love.graphics.newImage('resources/button.png')
gameConstants.buttonClickedImage = love.graphics.newImage('resources/buttonClicked.png')
gameConstants.buttonSize = {208, 58}

gameConstants.buttonFont = love.graphics.newFont('resources/monogram.ttf', 65, 'mono')
gameConstants.buttonX_Origins = {30, 269, 803, 1042}
gameConstants.buttonY_Origin = 638

gameConstants.buttonTextX_Offsets = {94, 82, 70, 58, 46, 34, 22, 10}
gameConstants.buttonTextY_Offset = -2

return gameConstants