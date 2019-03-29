local composer = require( "composer" )
local loadsave = require( "loadsave" )
local roleslib = require( "scenes.library.roles" )

local scene = composer.newScene()

local uiGroup = display.newGroup()

local settings = loadsave.loadTable( "settings.json" )

local ui = {
  background,
  step, greetcount,
  frontbox, title, roles = {}, playericon,
  helper, playersnamefield, deathmsg, deathmsgrec, recording, recordcount,
  factionroles, factionscount,
  revealedtext, revealedrole, handbook,
  start, starttext, back, backtext,
  nextrevealborder, nextreveal
}

local listPlayernames

local function titleCase( first, rest )
   return first:upper() .. rest:lower()
end

local function playersnameListener( event )
  if event.phase == "ended" or event.phase == "submitted" then
    if event.target.text ~= "" then
      event.target.text = string.sub( event.target.text, 1, 18 )
      event.target.text = string.gsub( event.target.text, "(%a)([%w_']*)", titleCase )
      settings.playernames[event.target.number] = string.gsub( event.target.text, "(%a)([%w_']*)", titleCase )
      loadsave.saveTable( settings, "settings.json" )
    end
  end
  display.setStatusBar( display.HiddenStatusBar )
  native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
end

listPlayernames = function()

  settings = loadsave.loadTable( "settings.json" )

  ui.playersnamefield = {}

  for i=1, settings.setup.players do
    ui.playersnamefield[i] = native.newTextField( display.contentCenterX, display.contentHeight * 0.22 + (i-1)*38, display.contentWidth * 0.8, display.contentHeight * 0.065 )
    ui.playersnamefield[i].number = i
    ui.playersnamefield[i].placeholder = settings.playernames[i]
    ui.playersnamefield[i]:addEventListener( "userInput", playersnameListener )
  end

end

local function gotoScenario()

  local function clearScenario()
    ui.background:removeSelf()
    ui.background = nil

    ui.title:removeSelf()
    ui.title= nil

    for i=1, settings.setup.players do
      ui.roles[i]:removeSelf()
      ui.roles[i] = nil
    end

    ui.helper:removeSelf()
    ui.helper = nil

    ui.deathmsg:removeSelf()
    ui.deathmsg = nil

    ui.start:removeSelf()
    ui.start = nil
    ui.starttext:removeSelf()
    ui.starttext = nil
  end

  if settings.setup.title == "Mafia Classica" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.classic" )
    composer.gotoScene( "scenes.scenarios.classic" )
  elseif settings.setup.title == "Pistole & Prostitute" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.gnh" )
    composer.gotoScene( "scenes.scenarios.gnh" )
  elseif settings.setup.title == "Amore a Prima Vista" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.btb" )
    composer.gotoScene( "scenes.scenarios.btb" )
  elseif settings.setup.title == "Lode al Culto" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.shrink" )
    composer.gotoScene( "scenes.scenarios.shrink" )
  elseif settings.setup.title == "Il Villaggio Selvaggio" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.kvsm" )
    composer.gotoScene( "scenes.scenarios.kvsm" )
  elseif settings.setup.title == "Giustizia o Follia?" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.ft3" )
    composer.gotoScene( "scenes.scenarios.ft3" )
  elseif settings.setup.title == "Io adoro i Linciaggi!" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.gallows" )
    composer.gotoScene( "scenes.scenarios.gallows" )
  elseif settings.setup.title == "Dottori, Pazienti e Pazzi" then
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
    composer.removeScene( "scenes.scenarios.everyman" )
    composer.gotoScene( "scenes.scenarios.everyman" )
  else
    clearScenario()
    loadsave.saveTable( settings, "settings.json" )
  end

end

local function revealGreeted( pl )

  local function revealRoles()
    ui.key:removeEventListener( "tap", revealRoles )
    ui.key.alpha = 0
    ui.helper.text = ""
    ui.revealedtext.text = settings.playernames[pl] .. ", hai il Ruolo di " .. settings.playerroles[pl] .. "."
    transition.fadeIn( ui.revealedtext, { time = 1500 } )

    ui.rolehandbook.text = roleslib.getRole( settings.setup.title, settings.playerroles[pl], 0 )
    transition.fadeIn( ui.rolehandbook, { time = 1500 } )

    -- revealimage
    ui.revealedrole = display.newImageRect( "images/roles/" .. settings.playerroles[pl] .. ".png", display.contentWidth * 0.25, display.contentWidth * 0.25 )
    ui.revealedrole.x, ui.revealedrole.y = display.contentWidth * 0.17, display.contentHeight * 0.32
    ui.revealedrole.alpha = 0
    transition.fadeIn( ui.revealedrole, { time = 1000 } )

    transition.fadeIn( ui.start, { delay = 1500, time = 300 } )
    transition.fadeIn( ui.starttext, { delay = 1500, time = 300 } )
  end

  ui.deathmsg.text = ""
  if pl == 0 then
    ui.helper.text = "Adesso, a turno, ogni Giocatore potrà inserire il proprio nome e registrare un audio che scatti alla propria morte. Altrimenti, saranno utilizzate le impostazioni di default.\n\nMi duole chiedertelo, " .. settings.playernames[10] .. ", ma ti dispiacerebbe passarmi al Giocatore 1?"
  elseif pl <= settings.setup.players then
    ui.start.alpha = 0
    ui.starttext.alpha = 0
    ui.helper.text = settings.playernames[pl] .. ", tocca la chiave per rivelare il tuo Ruolo. Mi raccomando, non farti spiare da nessuno!"
    ui.key.alpha = 1
    ui.key:addEventListener( "tap", revealRoles )
  end

end

local function greetPlayer( pl )

  local function playDeathAudio()
    if settings.playerdeaths[pl] == "audio/deaths/death" .. pl .. ".wav" then
      local deathsound = audio.loadSound( settings.playerdeaths[pl] )
      local deathchannel = audio.play( deathsound )
    else
      local deathsound = audio.loadSound( settings.playerdeaths[pl], system.DocumentsDirectory )
      local deathchannel = audio.play( deathsound )
    end
  end

  local function recordDeathAudio( event )

    local function timedRecordDeathAudio()
      settings.playerdeaths[pl] = "death" .. ui.recordcount .. ".wav"
      local filePath = system.pathForFile( settings.playerdeaths[pl], system.DocumentsDirectory )
      ui.recording = media.newRecording( filePath )
      ui.recording:startRecording()
    end

    if event.phase == "began" then
      ui.audioplay.alpha = 0.3
      ui.audioplay:removeEventListener( "tap", playDeathAudio )
      system.vibrate()
      timer.performWithDelay( 50, timedRecordDeathAudio )
    elseif event.phase == "ended" or event.phase == "cancelled" then
      ui.recordcount = ui.recordcount + 1
      ui.recording:stopRecording()
      ui.audioplay.alpha = 1
      ui.audioplay:addEventListener( "tap", playDeathAudio )
      system.vibrate()
    end

  end

  display.remove( ui.playersnamefield )
  ui.helper.text = "Ciao Giocatore " .. pl .. ", sono al tuo servizio. Come posso chiamarti?"

  local function createPlayerstextfield()
    ui.playersnamefield = native.newTextField( display.contentCenterX, display.contentHeight * 0.42, display.contentWidth * 0.9, display.contentHeight * 0.09 )
    ui.playersnamefield.number = pl
    ui.playersnamefield.placeholder = settings.playernames[pl]
    ui.playersnamefield:addEventListener( "userInput", playersnameListener )
  end

  timer.performWithDelay( 10, createPlayerstextfield )

  ui.deathmsg.text = "Vuoi registrare un audio speciale per la tua morte? Tieni premuto il microfono e parla."

  ui.audiorec = display.newImageRect( "images/interface/microphone.png", display.contentWidth * 0.24, display.contentWidth * 0.24 )
  ui.audiorec.x, ui.audiorec.y = display.contentWidth * 0.25, display.contentHeight * 0.69
  ui.audiorec:addEventListener( "touch", recordDeathAudio )

  ui.audioplay = display.newImageRect( "images/interface/play.png", display.contentWidth * 0.14, display.contentWidth * 0.14 )
  ui.audioplay.x, ui.audioplay.y = display.contentWidth * 0.5, display.contentHeight * 0.69
  ui.audioplay:addEventListener( "tap", playDeathAudio )

end

local function nextGreet( pl )
  ui.start.alpha = 1
  ui.starttext.alpha = 1
  if pl < settings.setup.players then
    ui.helper.text = settings.playernames[pl] .. ", grazie della collaborazione. Ti auguro di divertirti e mi raccomando: non prendere il gioco troppo sul serio!\n\nAdesso potresti gentilmente passarmi al prossimo Giocatore?"
  else
    ui.helper.text = settings.playernames[pl] .. ", con te abbiamo concluso il giro. Ti auguro di divertirti e mi raccomando: non prendere il gioco troppo sul serio!\n\nAdesso potresti gentilmente passarmi al Narratore, così iniziamo subito?"
  end
end

local function greetNarrator()
  ui.back:removeSelf()
  ui.back = nil
  ui.backtext:removeSelf()
  ui.backtext = nil
  ui.helper.text = "Grazie per voler partecipare come Narratore. Questo incarico non ti permette di competere nello Scenario, ma sono sicuro che ci divertiremo lo stesso.\n\nCome posso chiamarti?"
  ui.playersnamefield = native.newTextField( display.contentCenterX, display.contentHeight * 0.66, display.contentWidth * 0.9, display.contentHeight * 0.09 )
  ui.playersnamefield.number = 10 -- narrator
  ui.playersnamefield.placeholder = settings.playernames[10]
  ui.playersnamefield:addEventListener( "userInput", playersnameListener )
end

local function factionsOverview()

  ui.greetcount = ui.greetcount - 1
  ui.factionscount = ui.factionscount + 1
  ui.helper.text = ""
  display.remove( ui.factionroles )
  if ui.factionscount == 0 then
    ui.helper.text = "D'accordo " .. settings.playernames[10] .. "! Procediamo con la panoramica delle Fazioni presenti in questo Scenario.\n\nA partire da ora, dovrai leggere ad alta voce, affinchè tutti possano sentire. [Unica eccezione: le informazioni riservate contenute nelle parentesi quadrate]"
  else
    ui.revealedtext.text = "\n" .. settings.setup.factions[ui.factionscount]
    ui.revealedtext.alpha = 1
    ui.factionroles = display.newImageRect( "images/factions/" .. settings.setup.factions[ui.factionscount] .. ".png", display.contentWidth * 0.25, display.contentWidth * 0.25 )
    ui.factionroles.x, ui.factionroles.y = display.contentWidth * 0.17, display.contentHeight * 0.32
    ui.rolehandbook.text = roleslib.getFactionsOverview( settings.setup.factions[ui.factionscount] )
    ui.rolehandbook.alpha = 1
    if ui.factionscount == table.getn( settings.setup.factions ) then
      ui.greetcount = ui.greetcount + 1
    end
  end

end

local function gotoNextStep()

  display.remove( ui.playersnamefield )
  display.remove( ui.audiorec )
  display.remove( ui.audioplay )
  ui.revealedtext.alpha = 0
  ui.rolehandbook.alpha = 0
  display.remove( ui.revealedrole )

  transition.cancel( ui.start )
  ui.start.alpha = 1
  transition.cancel( ui.starttext )
  ui.starttext.alpha = 1

  if ui.greetcount == -2 then
    greetNarrator()
  elseif ui.greetcount == -1 then
    factionsOverview()
  elseif ui.greetcount == 0 then
    display.remove( ui.factionroles )
    revealGreeted( math.ceil( ui.greetcount/3 ) )
  elseif math.floor( ui.greetcount/3 ) < settings.setup.players then
    if ui.greetcount%3 == 1 then
      greetPlayer( math.ceil( ui.greetcount/3 ) )
    elseif ui.greetcount%3 == 2 then
      revealGreeted( math.ceil( ui.greetcount/3 ) )
    elseif ui.greetcount%3 == 0 then
      nextGreet( math.ceil( ui.greetcount / 3 ) )
    end
  elseif ui.greetcount/3 == settings.setup.players then
    nextGreet( math.ceil( ui.greetcount/3 ) )
  else
    gotoScenario()
  end
  ui.greetcount = ui.greetcount + 1

end

local function clearNarrator()

  ui.title:removeSelf()
  ui.title = nil

  for i=1, settings.setup.players do
    ui.roles[i]:removeSelf()
    ui.roles[i] = nil
  end

  display.remove( ui.playersnamefield )
  ui.playersnamefield = nil

  ui.helper:removeSelf()
  ui.helper = nil

  ui.deathmsg :removeSelf()
  ui.deathmsg = nil

  ui.start:removeSelf()
  ui.start = nil
  ui.starttext:removeSelf()
  ui.starttext = nil

  ui.back:removeSelf()
  ui.back = nil
  ui.backtext:removeSelf()
  ui.backtext = nil

end

local function gotoNarrator()
  clearNarrator()
  composer.setVariable( "scenario", settings.setup.id )
  composer.removeScene( "scenes.narrator" )
  composer.gotoScene( "scenes.narrator" )
end

local function shuffleRoles()
  local rolespool = {}
  for i=1, settings.setup.players do
    rolespool[i] = settings.setup.roles[i]
  end
  for i=1, settings.setup.players do
    settings.playerroles[i] = table.remove( rolespool, math.random( 1, table.getn( rolespool ) ) )
  end
end

-- create()
function scene:create( event )

  -- background

  ui.background = display.newImageRect( uiGroup, "images/backgrounds/neutralbackground.png", display.contentWidth, display.contentHeight )
  ui.background.x, ui.background.y = display.contentCenterX, display.contentCenterY

  -- utility counters

  ui.greetcount = -2
  ui.recordcount = 0
  ui.factionscount = -1
  ui.factionroles = {}

  -- frontbox

  ui.frontbox = display.newRect( uiGroup, display.contentWidth * 0.5, display.contentHeight * 0.11, display.contentWidth * 0.94, display.contentHeight * 0.18 )
  ui.frontbox:setFillColor( 20/255, 50/255, 10/255, 1 )
  ui.frontbox.strokeWidth = 2
  ui.frontbox:setStrokeColor( 1, 1, 1, 1 )

  -- title

  ui.title = display.newText( uiGroup, settings.setup.title, display.contentWidth * 0.06, display.contentHeight * 0.06, "GosmickSans.ttf", 28 )
  ui.title:setFillColor( 1, 1, 1, 1 )
  ui.title.anchorX = 0

  -- role icons

  for i=settings.setup.players, 1, -1 do
    ui.roles[i] = display.newImageRect( uiGroup, "images/roles/" .. settings.setup.roles[i] .. ".png", display.contentWidth * 0.12, display.contentWidth * 0.12 )
    ui.roles[i].x, ui.roles[i].y = display.contentWidth * 0.06 + (i-1)*25, display.contentWidth * 0.21
    ui.roles[i].anchorX = 0
  end

  -- player number icon

  ui.playericon = display.newImageRect( uiGroup, "images/numbers/" .. settings.setup.players .. ".png", display.contentWidth * 0.13, display.contentWidth * 0.13 )
  ui.playericon.x, ui.playericon.y = display.contentWidth * 0.88, display.contentWidth * 0.21

  -- description

  local helper = "Non vedo l'ora di iniziare a giocare con voi!\n\nPer organizzare al meglio, adesso dovrei parlare col Narratore."

  local options = {
    text = helper,
    x = display.contentCenterX,
    y = display.contentHeight * 0.54,
    width = display.contentWidth * 0.9,
    height = display.contentHeight * 0.6,
    font = "GosmickSans.ttf",
    fontSize = 20,
    align = "left"
  }

  ui.helper = display.newText( options )
  ui.helper:setFillColor( 1, 1, 1, 1 )

  -- death message

  local options = {
    text = "",
    x = display.contentCenterX,
    y = display.contentHeight * 0.6,
    width = display.contentWidth * 0.9,
    height = display.contentHeight * 0.2,
    font = "GosmickSans.ttf",
    fontSize = 16,
    align = "left"
  }

  ui.deathmsg = display.newText( options )
  ui.deathmsg:setFillColor( 1, 1, 1, 1 )

  -- starttext

  ui.start = display.newRect( uiGroup, display.contentWidth * 0.72, display.contentHeight * 0.9, display.contentWidth * 0.45, display.contentHeight * 0.12 )
  ui.start:setFillColor( 0, 0, 0, 1 )
  ui.start.strokeWidth = 2
  ui.start:setStrokeColor( 1, 1, 1, 1 )

  ui.starttext = display.newText( uiGroup, "Avanti", ui.start.x, ui.start.y, "GosmickSans.ttf", 28 )
  ui.starttext:setFillColor( 1, 1, 1, 1 )

  ui.start:addEventListener( "tap", gotoNextStep )

  -- back

  ui.back = display.newRect( uiGroup, display.contentWidth * 0.24, display.contentHeight * 0.9, display.contentWidth * 0.36, display.contentHeight * 0.08 )
  ui.back:setFillColor( 0, 0, 0, 1 )
  ui.back.strokeWidth = 2
  ui.back:setStrokeColor( 1, 1, 1, 1 )

  ui.backtext = display.newText( uiGroup, "Scenari", ui.back.x, ui.back.y, "GosmickSans.ttf", 18 )
  ui.backtext:setFillColor( 1, 1, 1, 1 )

  ui.back:addEventListener( "tap", gotoNarrator )

  -- shuffle roles

  shuffleRoles()

  -- reveals

  ui.key = display.newImageRect( "images/interface/key.png", display.contentWidth * 0.6, display.contentWidth * 0.6 )
  ui.key.x, ui.key.y = display.contentCenterX, display.contentHeight * 0.69
  ui.key.alpha = 0

  -- revealingtext

  options = {
    text = "",
    x = display.contentWidth * 0.63,
    y = display.contentHeight * 0.32,
    width = display.contentWidth * 0.62,
    height = display.contentHeight * 0.18,
    font = "GosmickSans.ttf",
    fontSize = 22,
    align = "left"
  }

  ui.revealedtext = display.newText( options )
  ui.revealedtext:setFillColor( 1, 1, 1, 1 )
  ui.revealedtext.alpha = 0

  -- rolehandbook

  options = {
    text = "",
    x = display.contentCenterX,
    y = display.contentHeight * 0.74,
    width = display.contentWidth * 0.9,
    height = display.contentHeight * 0.6,
    font = "GosmickSans.ttf",
    fontSize = 13,
    align = "left"
  }

  ui.rolehandbook = display.newText( options )
  ui.rolehandbook:setFillColor( 1, 1, 1, 1 )
  ui.rolehandbook.alpha = 0

end

-- scene event listener
scene:addEventListener( "create", scene )

return scene
