local composer = require( "composer" )
local loadsave = require( "loadsave" )

local scene = composer.newScene()

local uiGroup = display.newGroup()

local ui = {
  background,
  title, narratorborder, narrator, narratorlessborder, narratorless, creditsborder, credits
}

local function clearAll()
  ui.background:removeSelf()
  ui.background = nil

  ui.title:removeSelf()
  ui.title = nil

  ui.narratorborder:removeSelf()
  ui.narratorborder = nil

  ui.narrator:removeSelf()
  ui.narrator = nil

  ui.narratorlessborder:removeSelf()
  ui.narratorlessborder = nil

  ui.narratorless:removeSelf()
  ui.narratorless = nil

  ui.creditsborder:removeSelf()
  ui.creditsborder = nil

  ui.credits:removeSelf()
  ui.credits = nil
end

local function gotoNarrator()
  clearAll()
  composer.removeScene( "scenes.narrator" )
  composer.gotoScene( "scenes.narrator" )
end

local function gotoNarratorless()
  clearAll()
  composer.removeScene( "scenes.setups" )
  composer.gotoScene( "scenes.setups" )
end

local function gotoCredits()
  clearAll()
  composer.removeScene( "scenes.credits" )
  composer.gotoScene( "scenes.credits" )
end

-- create()
function scene:create( event )

  -- background

  ui.background = display.newImageRect( uiGroup, "images/backgrounds/neutralbackground.png", display.contentWidth, display.contentHeight )
  ui.background.x, ui.background.y = display.contentCenterX, display.contentCenterY

  -- title

  ui.title = display.newText( uiGroup, "Mafia in Scena", display.contentWidth * 0.5, display.contentHeight * 0.08, "GosmickSans.ttf", 46 )
  ui.title:setFillColor( 1, 1, 1, 1 )

  -- narrator

  ui.narratorborder = display.newRect( uiGroup, display.contentWidth * 0.5, display.contentHeight * 0.38, display.contentWidth * 0.82, display.contentHeight * 0.14 )
  ui.narratorborder:setFillColor( 0, 0, 0, 1 )
  ui.narratorborder.strokeWidth = 2
  ui.narratorborder:setStrokeColor( 1, 1, 1, 1 )

  ui.narrator = display.newText( uiGroup, "Gioco con il Narratore", ui.narratorborder.x, ui.narratorborder.y, "GosmickSans.ttf", 24 )
  ui.narrator:setFillColor( 1, 1, 1, 1 )

  ui.narratorborder:addEventListener( "tap", gotoNarrator )

  -- narratorless

  ui.narratorlessborder = display.newRect( uiGroup, display.contentWidth * 0.5, display.contentHeight * 0.58, display.contentWidth * 0.82, display.contentHeight * 0.14 )
  ui.narratorlessborder:setFillColor( 20/255, 50/255, 10/255, 0 )
  ui.narratorlessborder.strokeWidth = 2
  ui.narratorlessborder:setStrokeColor( 1, 1, 1, 0 )

  ui.narratorless = display.newText( uiGroup, "Gioco senza il Narratore", ui.narratorlessborder.x, ui.narratorlessborder.y, "GosmickSans.ttf", 24 )
  ui.narratorless:setFillColor( 1, 1, 1, 1 )
  ui.narratorless.alpha = 0
  --ui.narratorlessborder:addEventListener( "tap", gotoNarratorless )

  -- credits

  ui.creditsborder = display.newRect( uiGroup, display.contentWidth * 0.24, display.contentHeight * 0.9, display.contentWidth * 0.36, display.contentHeight * 0.08 )
  ui.creditsborder:setFillColor( 0, 0, 0, 1 )
  ui.creditsborder.strokeWidth = 2
  ui.creditsborder:setStrokeColor( 1, 1, 1, 1 )

  ui.credits = display.newText( uiGroup, "Crediti", ui.creditsborder.x, ui.creditsborder.y, "GosmickSans.ttf", 18 )
  ui.credits:setFillColor( 1, 1, 1, 1 )

  ui.creditsborder:addEventListener( "tap", gotoCredits )

  -- first scenario shown

  composer.setVariable( "scenario", 1 )

end

-- scene event listener
scene:addEventListener( "create", scene )

return scene
