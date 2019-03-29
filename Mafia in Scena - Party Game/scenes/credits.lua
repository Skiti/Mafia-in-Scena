local composer = require( "composer" )
local loadsave = require( "loadsave" )

local scene = composer.newScene()

local uiGroup = display.newGroup()

local ui = {
  background,
  title, backborder, back
}

local function clearAll()
  ui.background:removeSelf()
  ui.background = nil

  ui.title:removeSelf()
  ui.title = nil

  ui.thanks:removeSelf()
  ui.thanks = nil

  ui.backborder:removeSelf()
  ui.backborder = nil

  ui.back:removeSelf()
  ui.back = nil
end

local function gotoNewGame()
  clearAll()
  composer.removeScene( "scenes.welcome" )
  composer.gotoScene( "scenes.welcome" )
end

-- create()
function scene:create( event )

  -- background

  ui.background = display.newImageRect( uiGroup, "images/backgrounds/neutralbackground.png", display.contentWidth, display.contentHeight )
  ui.background.x, ui.background.y = display.contentCenterX, display.contentCenterY

  -- title

  ui.title = display.newText( uiGroup, "Mafia in Scena", display.contentWidth * 0.5, display.contentHeight * 0.08, "GosmickSans.ttf", 46 )
  ui.title:setFillColor( 1, 1, 1, 1 )

  local credits_text = "Mafia in Scena è un progetto di Marco Casagrande. \nRecapito email: <m.casagrande.1993@gmail.com>. \nServer Discord di Mafia in Scena: <https://discord.gg/Vf4wFrr>. \nMafia in Scena si basa sul famoso party game di Dmitry Davidoff, comunemente chiamato Mafia, Werewolves, Lupus in Tabula. \n\nUn ringraziamento davvero speciale va ad EpicMafia <https://epicmafia.com>, la community da cui ho tratto praticamente ogni spunto, in particolare per gli scenari e le relative strategie. \nConsiglio vivamente agli appassionati di farci un giro! \n\nLe risorse grafiche sono state scaricate da Vecteezy <https://www.vecteezy.com>.\n\nLe icone sono state scaricate da GameIcons <https://game-icons.net>.\n\nLe risorse audio sono state scaricate da Zapsplat <https://www.zapsplat.com>."

  local options = {
    text = credits_text,
    x = display.contentCenterX,
    y = display.contentHeight * 0.53,
    width = display.contentWidth * 0.9,
    height = display.contentHeight * 0.7,
    font = "GosmickSans.ttf",
    fontSize = 11,
    align = "left"
  }

  ui.thanks = display.newText( options )
  ui.thanks:setFillColor( 1, 1, 1, 1 )

  -- back

  ui.backborder = display.newRect( uiGroup, display.contentWidth * 0.24, display.contentHeight * 0.9, display.contentWidth * 0.36, display.contentHeight * 0.08 )
  ui.backborder:setFillColor( 0, 0, 0, 1 )
  ui.backborder.strokeWidth = 2
  ui.backborder:setStrokeColor( 1, 1, 1, 1 )

  ui.back = display.newText( uiGroup, "Indietro", ui.backborder.x, ui.backborder.y, "GosmickSans.ttf", 18 )
  ui.back:setFillColor( 1, 1, 1, 1 )

  ui.backborder:addEventListener( "tap", gotoNewGame )

end

-- scene event listener
scene:addEventListener( "create", scene )

return scene
