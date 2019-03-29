local composer = require( "composer" )
local loadsave = require( "loadsave" )
local roleslib = require( "scenes.library.roles" )

local scene = composer.newScene()

local uiGroup = display.newGroup()

local settings = loadsave.loadTable( "settings.json" )

local ui = {
  background,
  frontbox, title, roles = {}, playericon,
  helper, daytime, dayalert,
  forward, forwardtext,
  strat, strattext,
  roleactionicon
}

local playerinfo = {}

local nightcount = 0
local lastmafiakill
local lasthooked
local lastgunned

local lastdeaths = {}

local copid
local gunsmithid

local gunowner = -1

local lynchedvotes = {}

local nightsound = audio.loadSound( "audio/howl.wav" )
local sunrisesound = audio.loadSound( "audio/rooster.wav" )

local handgunsound = audio.loadSound( "audio/handgun.wav" )

local townwinsound = audio.loadSound( "audio/townwin.wav" )
local mafiawinsound = audio.loadSound( "audio/mafiawin.wav" )

local seconds = 0
local minutes = 0

local stoppedtime = false

local discussLynch

local nightTime
local sunriseTime
local dayTime
local sunsetTime

local function changeBackground( daytime )
  ui.background:removeSelf()
  ui.background = display.newImageRect( uiGroup, "images/backgrounds/" .. daytime .. "background.png", display.contentWidth, display.contentHeight )
  ui.background.x, ui.background.y = display.contentCenterX, display.contentCenterY
  ui.background:toBack()
end

local function playDeathAudio( dead )
  local deathsound
  if settings.playerdeaths[dead] == "audio/deaths/death" .. dead .. ".wav" then
    deathsound = audio.loadSound( settings.playerdeaths[dead] )
    audio.play( deathsound )
  else
    audio.play( mafiawinsound )
    deathsound = audio.loadSound( settings.playerdeaths[dead], system.DocumentsDirectory )
    audio.play( deathsound )
  end
end

local function enforceWinCondition( trigger )

  local winchannel
  stoppedtime = true

  local function gotoNarrator()
    ui.background:removeSelf()
    ui.background = nil

    ui.strat:removeSelf()
    ui.strat = nil
    ui.strattext:removeSelf()
    ui.strattext = nil

    ui.forward:removeEventListener( "tap", gotoNarrator )
    ui.forward:removeSelf()
    ui.forward = nil
    ui.forwardtext:removeSelf()
    ui.forwardtext = nil

    transition.cancel( ui.forward )
    transition.cancel( ui.forwardtext )

    ui.title:removeSelf()
    ui.title= nil

    for i=1, settings.setup.players do
      ui.roles[i]:removeSelf()
      ui.roles[i] = nil
    end

    ui.helper:removeSelf()
    ui.helper = nil

    ui.rolehandbook:removeSelf()
    ui.rolehandbook = nil

    audio.stop( winchannel )

    composer.setVariable( "scenario", settings.setup.id )

    composer.removeScene( "scenes.narrator" )
    composer.gotoScene( "scenes.narrator" )
  end

  local function congratulate( alignment )
    local congratulations = ""
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].alignment == alignment then
        congratulations = congratulations .. playerinfo[i].name .. ", "
      end
    end
    congratulations = congratulations:sub( 1, -3 )
    return congratulations
  end

  local function endingScenario()
    changeBackground( "win" )
    ui.forward.alpha = 1
    ui.forwardtext.alpha = 1
    ui.forwardtext.text = "Scenari"
    ui.forward:addEventListener( "tap", gotoNarrator )
  end

  local function townWins()
    winchannel = audio.play( townwinsound )
    local congratulations = congratulate( 0 )
    ui.helper.text = "Il Villaggio ha linciato la Mafia. Il Villaggio ha vinto!\n\nComplimenti a " .. congratulations .. "."
    endingScenario()
  end

  local function mafiaWins()
    winchannel = audio.play( mafiawinsound )
    local congratulations = congratulate( 1 )
    ui.helper.text = "La Mafia ha ottenuto il controllo del Villaggio. La Mafia ha vinto!\n\nComplimenti a " .. congratulations .. "."
    endingScenario()
  end

  local function alignmentCount()
    local towncount = 0
    local mafiacount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].alive == 1 and playerinfo[i].alignment == 0 then
        towncount = towncount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 1 then
        mafiacount = mafiacount + 1
      end
    end
    return towncount, mafiacount
  end

  local towncount, mafiacount = alignmentCount()

  if mafiacount == 0 then
    townWins()
  elseif mafiacount >= towncount then
    mafiaWins()
  else
    if trigger == "lynch" then
      nightTime()
    elseif trigger == "kill" then
      seconds = 0
      minutes = 0
      dayTime()
    elseif trigger == "gunshot" then
      gunowner = -1
      discussLynch()
    end
  end

end

sunsetTime = function()

  local function endSunsetTime()
    ui.forward:removeEventListener( "tap", endSunsetTime )
    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0

    display.remove( ui.roleactionicon )
    ui.roleactionicon = nil

    enforceWinCondition( "lynch" )
  end

  local gunshotSignal

  local function voteLynch()

    local lynchvote = {}
    local lynchvotationicon = {}

    local function calculateAliveVoters()
      local alivevoters = 0
      local voteindicator = ""
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and lynchedvotes[i] == 0 then
          alivevoters = alivevoters + 1
        end
      end
      return alivevoters
    end

    local function calculateVoteIndicator()
      local alivevoters = calculateAliveVoters()
      if alivevoters == 1 then
        voteindicator = "ANCORA " .. alivevoters .. " VOTO"
      else
        voteindicator = "ANCORA " .. alivevoters .. " VOTI"
      end
      return voteindicator
    end

    local function chooseVote( event )

      local lynchedname = {}
      local lynchaddvote = {}

      local lyncher = event.target.id

      local function addVote( event )

        for i=1, table.getn( lynchedname ) do
          lynchedname[i]:removeSelf()
          lynchedname[i] = nil
        end
        for i=1, table.getn( lynchaddvote ) do
          lynchaddvote[i]:removeSelf()
          lynchaddvote[i] = nil
        end

        local voted = event.target.id

        lynchedvotes[lyncher] = voted

        if calculateAliveVoters() > 0 then
          voteLynch()
        else
          local majority = {}
          for i=1, table.getn( lynchedvotes ) do
            majority[i] = 0
          end
          local mostvotes = 0
          local mostvoted = 0
          for i=1, table.getn( lynchedvotes ) - 1 do
            if lynchedvotes[i] ~= 0 then
              majority[ lynchedvotes[i] ] = majority[ lynchedvotes[i] ] + 1
              if mostvotes < majority[ lynchedvotes[i] ] then
                mostvotes = majority[ lynchedvotes[i] ]
                mostvoted = lynchedvotes[i]
              end
            end
          end
          local absolutemajority = true
          for i=1, table.getn( majority ) do
            if mostvotes <= majority[i] and i ~= mostvoted then
              absolutemajority = false
            end
          end
          if absolutemajority == true and mostvoted ~= settings.setup.players+1 then
            ui.helper.text = "Oggi il Villaggio ha decretato il Linciaggio di " .. playerinfo[mostvoted].name .. ".\n\nChe fine orrenda.\n\nAveva il Ruolo di " .. playerinfo[mostvoted].role .. "."
            playDeathAudio( mostvoted )
            playerinfo[mostvoted].alive = 0
            ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[mostvoted].role .. ".png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
            ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
          else
            if mostvoted == settings.setup.players+1 then
              ui.helper.text = "Oggi il Villaggio ha optato per evitare il Linciaggio."
            else
              ui.helper.text = "Oggi il Villaggio non ha trovato un accordo e nessun Linciaggio è avvenuto."
            end
          end
          ui.forward.alpha = 1
          ui.forwardtext.alpha = 1
          ui.forwardtext.text = "Avanti"
          ui.forward:addEventListener( "tap", endSunsetTime )
        end

      end

      for i=1, table.getn( lynchvote ) do
        lynchvote[i]:removeSelf()
        lynchvote[i] = nil
      end
      for i=1, table.getn( lynchvotationicon ) do
        lynchvotationicon[i]:removeSelf()
        lynchvotationicon[i] = nil
      end

      ui.helper.text = "VOTO DI " .. string.upper( playerinfo[lyncher].name .. ":" )
      ui.rolehandbook.text = ""

      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 then
          lynchedname[j] = display.newText( uiGroup, "Lincia " .. settings.playernames[i], display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 18 )
          lynchedname[j].anchorX = 0
          lynchaddvote[j] = display.newImageRect( uiGroup, "images/interface/hang.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          lynchaddvote[j].x, lynchaddvote[j].y = display.contentWidth * 0.85, lynchedname[j].y
          lynchaddvote[j].id = i
          lynchaddvote[j]:addEventListener( "tap", addVote )
          j = j + 1
        end
      end
      lynchedname[j] = display.newText( uiGroup, "**NON LINCIARE", display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 18 )
      lynchedname[j].anchorX = 0
      lynchaddvote[j] = display.newImageRect( uiGroup, "images/interface/peace.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      lynchaddvote[j].x, lynchaddvote[j].y = display.contentWidth * 0.85, lynchedname[j].y
      lynchaddvote[j].id = settings.setup.players + 1
      lynchaddvote[j]:addEventListener( "tap", addVote )

    end

    ui.strat.alpha = 0
    ui.strattext.alpha = 0

    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0
    ui.forward:removeEventListener( "tap", voteLynch )

    local voteindicator = calculateVoteIndicator()

    ui.helper.text = voteindicator.. " AL LINCIAGGIO.."
    ui.rolehandbook.text = ""
    local j = 1
    local votedicon
    for i=1, settings.setup.players do
      if playerinfo[i].alive == 1 then
        if lynchedvotes[i] == 0 then
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " non ha ancora votato", display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09, "GosmickSans.ttf", 12 )
          votedicon = "vote"
        elseif lynchedvotes[i] == settings.setup.players+1 then
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " vota **Non Linciare", display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09, "GosmickSans.ttf", 12 )
          votedicon = "voted"
        else
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " vota " .. settings.playernames[ lynchedvotes[i] ], display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09, "GosmickSans.ttf", 12 )
          votedicon = "voted"
        end
        lynchvote[j].anchorX = 0
        lynchvotationicon[j] = display.newImageRect( uiGroup, "images/interface/" .. votedicon .. ".png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
        lynchvotationicon[j].x, lynchvotationicon[j].y = display.contentWidth * 0.85, lynchvote[j].y
        lynchvotationicon[j].id = i
        lynchvotationicon[j]:addEventListener( "tap", chooseVote )
        j = j + 1
      end
    end

  end

  local function clearBeforeVoteLynch()
    ui.daytime:removeSelf()
    ui.daytime = nil
    ui.dayalert.text = ""
    voteLynch()
  end

  changeBackground( "sunset" )

  ui.dayalert.text = "GIUNGE IL TRAMONTO.."
  ui.dayalert.alpha = 1

  ui.helper.text = "\n\nDurante il Tramonto, i Giocatori vivi votano nel Linciaggio. Al termine della votazione, il più votato muore. In caso di pareggio, nessuno muore. Si può votare di evitare il Linciaggio."
  ui.helper.alpha = 1

  ui.daytime = display.newImageRect( uiGroup, "images/interface/sunset.png", display.contentWidth * 0.35, display.contentWidth * 0.35 )
  ui.daytime.x, ui.daytime.y = display.contentWidth * 0.75, display.contentHeight * 0.84
  ui.daytime:addEventListener( "tap", clearBeforeVoteLynch )
end

dayTime = function()

  print( "dayTime" )

  local function updateTime()
    seconds = seconds + 1
    if seconds > 59 then
      seconds = 0
      minutes = minutes + 1
    end
    if stoppedtime == false then
      ui.helper.text = "Durata della Discussione: " .. minutes .. "m " .. seconds .. "s"
    end
  end

  local discussionTimer = timer.performWithDelay( 1000, updateTime, 0 )
  stoppedtime = true

  local function endDayTime()
    print( "endDayTime" )
    ui.strat.alpha = 0
    ui.strattext.alpha = 0

    sunsetTime()
  end

  local showDayStrat

  discussLynch = function()

    print( "discussLynch" )

    local discussalivenames = {}
    local discussdeadnames = {}

    local discussdeaths = {}
    local discussroles = {}

    local gunnednames = {}

    stoppedtime = false

    ui.dayalert.text = ""

    local function clearDiscussLynch()

      print( "clearDiscussLynch" )

      for i=1, table.getn( discussalivenames ) do
        discussalivenames[i]:removeSelf()
        discussalivenames[i] = nil
      end
      for i=1, table.getn( discussdeadnames ) do
        discussdeadnames[i]:removeSelf()
        discussdeadnames[i] = nil
      end

      for i=1, table.getn( discussdeaths ) do
        discussdeaths[i]:removeSelf()
        discussdeaths[i] = nil
      end
      for i=1, table.getn( discussroles ) do
        discussroles[i]:removeSelf()
        discussroles[i] = nil
      end
      for i=1, table.getn( gunnednames ) do
        gunnednames[i]:removeSelf()
        gunnednames[i] = nil
      end

    end

    local clearShowDayStrat
    local clearGunshotSignal

    local function clearVoteLynch()
      print( "clearVoteLynch" )
      timer.cancel( discussionTimer )
      clearDiscussLynch()
      ui.forward:removeEventListener( "tap", clearVoteLynch )
      ui.forward.alpha = 0
      ui.forwardtext.alpha = 0
      ui.strat:removeEventListener( "tap", clearShowDayStrat )
      endDayTime()
    end

    clearShowDayStrat = function()
      print( "clearShowDayStrat" )
      clearDiscussLynch()
      ui.forward:removeEventListener( "tap", clearVoteLynch )
      ui.forward.alpha = 0
      ui.forwardtext.alpha = 0
      ui.strat:removeEventListener( "tap", clearShowDayStrat )
      showDayStrat()
    end

    clearGunshotSignal = function( event )
      print( "clearGunshotSignal" )
      gunowner = event.target.id
      playerinfo[gunowner].gun = playerinfo[gunowner].gun - 1
      clearDiscussLynch()
      ui.forward:removeEventListener( "tap", clearVoteLynch )
      ui.forward.alpha = 0
      ui.forwardtext.alpha = 0
      ui.strat:removeEventListener( "tap", clearShowDayStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0
      gunshotSignal()
    end

    display.remove( ui.daytime )
    ui.daytime = nil

    local alive
    local role

    local j = 1
    local w = 1
    local u = 1
    for i=1, settings.setup.players do
      if playerinfo[i].alive == 1 then
        discussalivenames[w] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.24, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.06, "GosmickSans.ttf", 17 )
        discussalivenames[w].anchorX = 0

        if playerinfo[i].revealed == 1 then
          discussroles[j] = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[i].role .. ".png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
        else
          discussroles[j] = display.newImageRect( uiGroup, "images/interface/unknown.png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
        end
        discussroles[j].x, discussroles[j].y = display.contentWidth * 0.13, discussalivenames[w].y

        if playerinfo[i].gun > 0 then
          gunnednames[u] = display.newImageRect( uiGroup, "images/interface/gunshot.png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
          gunnednames[u].x, gunnednames[u].y = display.contentWidth * 0.8, discussalivenames[w].y
          gunnednames[u].id = i
          gunnednames[u]:addEventListener( "tap", clearGunshotSignal )
          u = u + 1
        end

        j = j + 1
        w = w + 1
      end
    end

    w = 1
    for i=1, settings.setup.players do
      if playerinfo[i].alive == 0 then
        discussdeadnames[w] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.24, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.06, "GosmickSans.ttf", 17 )
        discussdeadnames[w].anchorX = 0
        discussdeadnames[w]:setFillColor( 200/255, 20/255, 25/255, 1 )

        discussdeaths[w] = display.newImageRect( uiGroup, "images/interface/dead.png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
        discussdeaths[w].x, discussdeaths[w].y = display.contentWidth * 0.1, discussdeadnames[w].y
        discussroles[j] = display.newImageRect( uiGroup, "images/roles/" ..  playerinfo[i].role .. ".png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
        discussroles[j].x, discussroles[j].y = display.contentWidth * 0.16, discussdeadnames[w].y

        j = j + 1
        w = w + 1
      end
    end

    ui.helper.text = "Durata della Discussione: " .. minutes .. "m " .. seconds .. "s"

    for i=1, settings.setup.players + 1 do
      lynchedvotes[i] = 0
    end

    ui.forward.alpha = 1
    ui.forwardtext.alpha = 1
    ui.forwardtext.text = "Linciaggio"
    ui.forward:addEventListener( "tap", clearVoteLynch )

    ui.strat.alpha = 1
    ui.strattext.alpha = 1
    ui.strat:addEventListener( "tap", clearShowDayStrat )

  end

  changeBackground( "day" )

  ui.dayalert.text = "SOPRAVANZA IL GIORNO.."
  ui.dayalert.alpha = 1

  ui.helper.text = "\n\nDurante il Giorno, i Giocatori vivi possono discutere tra di loro su Ruoli, avvenimenti, accuse, comportamenti e quant'altro. Lo scopo della Discussione è decidere SE linciare al Tramonto, e CHI."
  ui.helper.alpha = 1

  ui.daytime = display.newImageRect( uiGroup, "images/interface/sun.png", display.contentWidth * 0.35, display.contentWidth * 0.35 )
  ui.daytime.x, ui.daytime.y = display.contentWidth * 0.75, display.contentHeight * 0.84
  ui.daytime:addEventListener( "tap", discussLynch )

  gunshotSignal = function()

    local function backGunshotDiscussLynch()
      print( "backGunshotDiscussLynch" )
      ui.forward:removeEventListener( "tap", backGunshotDiscussLynch )
      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil
      stoppedtime = false
      enforceWinCondition( "gunshot" )
    end

    local function gunshotKill()

      print( "gunshotKill" )

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local gunshoticons = {}
      local gunshotnames = {}

      local function clearGunshot( event )
        print( "clearGunshot" )

        for i=1, table.getn( gunshoticons ) do
          gunshoticons[i]:removeSelf()
          gunshoticons[i] = nil
        end
        for i=1, table.getn( gunshotnames ) do
          gunshotnames[i]:removeSelf()
          gunshotnames[i] = nil
        end

        local gunkilled = event.target.id

        ui.helper.text = "Tutti i Giocatori riaprono gli occhi.\n\n" .. playerinfo[gunkilled].name .. " ha una pallottola piantata in testa. Aveva il Ruolo di " .. playerinfo[gunkilled].role .. "."
        playerinfo[gunkilled].alive = 0

        local function playGunDeathAudio()
          print( "playGunDeathAudio" )
          playDeathAudio( gunkilled )
        end

        audio.play( handgunsound, { onComplete=playGunDeathAudio } )
        ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[gunkilled].role .. ".png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
        ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1
        ui.forwardtext.text = "Discussione"

        ui.forward:addEventListener( "tap", backGunshotDiscussLynch )

      end

      ui.helper.text = "POSSIBILI VITTIME:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and gunowner ~= i then
          gunshoticons[j] = display.newImageRect( uiGroup, "images/interface/gunshot.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          gunshoticons[j].x, gunshoticons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
          gunshoticons[j].id = i
          gunshoticons[j]:addEventListener( "tap", clearGunshot )
          gunshotnames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, gunshoticons[j].y, "GosmickSans.ttf", 18 )
          gunshotnames[j].anchorX = 0
          j = j + 1
        end
      end
    end

    stoppedtime = true

    ui.helper.text = "Qualcuno ha sparato. Tutti i Giocatori chiudono gli occhi.\n\nIl Giocatore che ha sparato apre gli occhi ed indica la sua vittima."

    ui.roleactionicon = display.newImageRect( uiGroup, "images/interface/gunshooting.png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", gunshotKill )

  end

  showDayStrat = function()

    local function backDiscussLynch()
      ui.strattext.text = "Strategia"
      ui.strat:removeEventListener( "tap", backDiscussLynch )
      ui.rolehandbook.text = ""
      stoppedtime = false
      discussLynch()
    end

    stoppedtime = true

    ui.helper.text = "STRATEGIA GENERALE (GIORNO)"
    ui.rolehandbook.text = roleslib.getDayStrat( settings.setup.title, nightcount )
    ui.rolehandbook.alpha = 1
    ui.strattext.text = "Indietro"
    ui.strat:addEventListener( "tap", backDiscussLynch )

  end

end

sunriseTime = function()

  local function endSunriseTime()
    ui.forward:removeEventListener( "tap", endSunriseTime )
    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0

    display.remove( ui.roleactionicon )
    ui.roleactionicon = nil

    enforceWinCondition( "kill" )
  end

  local function checkDeaths()

    local function announceDeaths()

      display.remove( ui.roleactionicon )
      ui.forward:removeEventListener( "tap", announceDeaths )

      if table.getn( lastdeaths ) > 0 then

        local dead = table.remove( lastdeaths )

        playDeathAudio( dead )
        playerinfo[dead].alive = 0
        ui.helper.text = "Il cadavere di " .. playerinfo[dead].name .. " è stato rinvenuto. Era stato abbandonato in un cassonetto dell'immondizia.\n\nAveva il Ruolo di " .. playerinfo[dead].role .. "."

        ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[dead].role .. ".png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
        ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1
        ui.forward:addEventListener( "tap", announceDeaths )

      elseif table.getn( lastdeaths ) == 0 then

        endSunriseTime()

      end

    end

    ui.dayalert.text = ""
    ui.daytime:removeEventListener( "tap", checkDeaths )
    ui.daytime:removeSelf()
    ui.daytime = nil

    if table.getn( lastdeaths ) > 0 then
      announceDeaths()
    else
      ui.helper.text = "Nessun Giocatore è morto stanotte."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", endSunriseTime )
    end

  end

  audio.play( sunrisesound )

  changeBackground( "sunrise" )

  ui.dayalert.text = "SORGE L'ALBA.."
  ui.dayalert.alpha = 1

  ui.helper.text = "\n\nDurante l'Alba, i Giocatori riaprono gli occhi e vengono rivelate le vittime della Notte appena passata."
  ui.helper.alpha = 1

  ui.daytime = display.newImageRect( uiGroup, "images/interface/sunrise.png", display.contentWidth * 0.35, display.contentWidth * 0.35 )
  ui.daytime.x, ui.daytime.y = display.contentWidth * 0.75, display.contentHeight * 0.84
  ui.daytime:addEventListener( "tap", checkDeaths )

end

nightTime = function()

  local function endNightTime()
    ui.forward:removeEventListener( "tap", endNightTime )
    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0

    sunriseTime()
  end

  local function gunsmithCheck()

    local gunsmithcount = 0
    for i=1, settings.setup.players do
      if playerinfo[i].role == "Armaiolo" and playerinfo[i].alive == 1 then
        gunsmithcount = gunsmithcount + 1
      end
    end

    if gunsmithcount > 0 then

      local count = 0

      local function obtainedGun()
        count = count + 1
        ui.helper.text = ""
        ui.rolehandbook.text = ""
        if count > settings.setup.players then
          ui.forward:removeEventListener( "tap", obtainedGun )
          endNightTime()
        elseif playerinfo[count].alive == 0 then
          obtainedGun()
        elseif playerinfo[count].alive == 1 then
          if count == lastgunned and lasthooked ~= gunsmithid then
            ui.helper.text = playerinfo[count].name .. " apre gli occhi."
            ui.rolehandbook.text = "\nScopre se ha ricevuto la Pistola.\n\n[Segno positivo, ha ricevuto la Pistola]\n\nIn tal caso, mi mostra il segnale per sparare.\n\n[Memorizza il segnale!]\n\nPoi chiude gli occhi."
          elseif count <= settings.setup.players then
            ui.helper.text = playerinfo[count].name .. " apre gli occhi."
            ui.rolehandbook.text = "\nScopre se ha ricevuto la Pistola.\n\n[Segno negativo, nessuna Pistola]\n\nIn tal caso, mi mostra il segnale per sparare.\n\n[Niente segnale]\n\nPoi chiude gli occhi."
          end
        end
      end

      ui.forward:removeEventListener( "tap", gunsmithCheck )

      ui.helper.text = "Tenete ancora chiusi gli occhi."
      ui.rolehandbook.text = "A turno, farò aprire gli occhi a ciascun Giocatore, per indicargli l'eventuale consegna della Pistola con un segno positivo o negativo. Qualora il Giocatore ricevesse la Pistola, questo dovrà mostrarmi un segnale a sua discrezione. Se durante il Giorno eseguirà quel segnale, io fermerò il gioco e gli permetterò di sparare anonimamente."
      ui.forward:addEventListener( "tap", obtainedGun )

    else

      endNightTime()

    end

  end

  local function evaluateNightVisits()

    ui.forward:removeEventListener( "tap", evaluateNightVisits )

    lastdeaths = {}

    if lastmafiakill ~= -1 then --mafiakilled
      table.insert( lastdeaths, lastmafiakill ) --kill happens
    end

    if lastgunned ~= -1 then --gunsmithgunned
      if lasthooked == -1 or lasthooked ~= gunsmithid then --nohook or wronghook
        playerinfo[lastgunned].gun = playerinfo[lastgunned].gun + 1 --gunned happens
      end
    end

    gunsmithCheck()

  end

  local showNightStrat

  local function activateNightStrat( role )
    ui.strat.alpha = 1
    ui.strattext.alpha = 1
    ui.strattext.text = "Strategia"
    ui.strat.role = role
    ui.strat:addEventListener( "tap", showNightStrat )
  end

  local function visitGunsmith()

    local function gunsmithGun()

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local gunnedicons = {}
      local gunnednames = {}

      local function clearGunned( event )

        for i=1, table.getn( gunnedicons ) do
          gunnedicons[i]:removeSelf()
          gunnedicons[i] = nil
        end
        for i=1, table.getn( gunnednames ) do
          gunnednames[i]:removeSelf()
          gunnednames[i] = nil
        end

        lastgunned = event.target.id

        if lastgunned ~= -1 then --gunned
          ui.helper.text = "L'Armaiolo ha deciso a chi consegnare la Pistola.\n\n[" .. playerinfo[lastgunned].name .. "]"
        else --nogunned
          ui.helper.text = "L'Armaiolo ha deciso a chi consegnare la Pistola.\n\n[Nessuno]"
        end

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearGunReminder()
          ui.forward:removeEventListener( "tap", clearGunReminder )
          ui.forward:addEventListener( "tap", evaluateNightVisits )
        end

        ui.forward:addEventListener( "tap", clearGunReminder )

      end

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI CONSEGNE:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and gunsmithid ~= i then
          gunnedicons[j] = display.newImageRect( uiGroup, "images/interface/gunned.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          gunnedicons[j].x, gunnedicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
          gunnedicons[j].id = i
          gunnedicons[j]:addEventListener( "tap", clearGunned )
          gunnednames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, gunnedicons[j].y, "GosmickSans.ttf", 18 )
          gunnednames[j].anchorX = 0
          j = j + 1
        end
      end
      gunnedicons[j] = display.newImageRect( uiGroup, "images/interface/gunned.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      gunnedicons[j].x, gunnedicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
      gunnedicons[j]:addEventListener( "tap", clearGunned )
      gunnedicons[j].id = -1
      gunnednames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, gunnedicons[j].y, "GosmickSans.ttf", 18 )
      gunnednames[j].anchorX = 0
    end

    local gscount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Armaiolo" and playerinfo[i].alive == 1 then
        gscount = gscount + 1
      end
    end

    if gscount > 0 then
      ui.helper.text = "L'Armaiolo apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Armaiolo" )

      activateNightStrat( "Armaiolo" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Armaiolo.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", gunsmithGun )
    else
      lastgunned = -1
      ui.helper.text = "L'Armaiolo è morto e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", evaluateNightVisits )
    end

  end

  local function visitCop()

    local function copInvestigate()

      local investigateicons = {}
      local investigatenames = {}

      local function clearInvestigate( event )

        for i=1, table.getn( investigateicons ) do
          investigateicons[i]:removeSelf()
          investigateicons[i] = nil
        end
        for i=1, table.getn( investigatenames ) do
          investigatenames[i]:removeSelf()
          investigatenames[i] = nil
        end

        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        ui.forward:removeEventListener( "tap", clearInvestigate )

        local investigated = event.target.id
        local alignmentreport

        if playerinfo[investigated].alignment == 0 then
          alignmentreport = "Segno positivo, " .. playerinfo[investigated].name .. " è Innocente"
        elseif playerinfo[investigated].alignment == 1 then
          alignmentreport = "Segno negativo, " .. playerinfo[investigated].name .. " è Colpevole"
        end

        if lasthooked == copid then
          ui.helper.text = "Il Detective ha deciso chi indagare ed ha ottenuto un report su di esso.\n\n[Segno speciale, sedotto dalla Squillo]"
        else
          ui.helper.text = "Il Detective ha deciso chi indagare ed ha ottenuto un report su di esso.\n\n[" .. alignmentreport .. "]"
        end

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearInvestigateReminder()
          ui.forward:removeEventListener( "tap", clearInvestigateReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitGunsmith()
        end

        ui.forward:addEventListener( "tap", clearInvestigateReminder )

      end

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI INVESTIGAZIONI:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].role ~= "Detective" then
          investigateicons[j] = display.newImageRect( uiGroup, "images/interface/investigate.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          investigateicons[j].x, investigateicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
          investigateicons[j].id = i
          investigateicons[j]:addEventListener( "tap", clearInvestigate )
          investigatenames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, investigateicons[j].y, "GosmickSans.ttf", 18 )
          investigatenames[j].anchorX = 0
          j = j + 1
        end
      end

    end

    local copcount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Detective" and playerinfo[i].alive == 1 then
        copcount = copcount + 1
      end
    end

    if copcount > 0 then
      ui.helper.text = "Il Detective apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Detective" )

      activateNightStrat( "Detective" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Detective.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", copInvestigate )
    else

      local function clearDeadCop()
        ui.forward:removeEventListener( "tap", clearDeadCop )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        visitGunsmith()
      end

      ui.helper.text = "Il Detective è morto e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearDeadCop )

    end

  end

  local function visitHooker()

    local function hookerHook()

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local hookicons = {}
      local hooknames = {}

      local function clearHook( event )

        for i=1, table.getn( hookicons ) do
          hookicons[i]:removeSelf()
          hookicons[i] = nil
        end
        for i=1, table.getn( hooknames ) do
          hooknames[i]:removeSelf()
          hooknames[i] = nil
        end

        lasthooked = event.target.id

        if lasthooked ~= -1 then --hook
          ui.helper.text = "La Squillo ha deciso chi sedurre.\n\n[" .. playerinfo[lasthooked].name .. "]"
        else --nohook
          ui.helper.text = "La Squillo ha deciso chi sedurre.\n\n[Nessuno]"
        end

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearHookReminder()
          ui.forward:removeEventListener( "tap", clearHookReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitCop()
        end

        ui.forward:addEventListener( "tap", clearHookReminder )

      end

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI CLIENTI:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].alignment ~= 1 then
          hookicons[j] = display.newImageRect( uiGroup, "images/interface/hook.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          hookicons[j].x, hookicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
          hookicons[j].id = i
          hookicons[j]:addEventListener( "tap", clearHook )
          hooknames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, hookicons[j].y, "GosmickSans.ttf", 18 )
          hooknames[j].anchorX = 0
          j = j + 1
        end
      end
      hookicons[j] = display.newImageRect( uiGroup, "images/interface/hook.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      hookicons[j].x, hookicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
      hookicons[j]:addEventListener( "tap", clearHook )
      hookicons[j].id = -1
      hooknames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, hookicons[j].y, "GosmickSans.ttf", 18 )
      hooknames[j].anchorX = 0
    end

    local hookercount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Squillo" and playerinfo[i].alive == 1 then
        hookercount = hookercount + 1
      end
    end

    if hookercount > 0 then
      ui.helper.text = "Tocca ancora alla Mafia."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Squillo" )
      activateNightStrat( "Squillo" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Squillo.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", hookerHook )
    else

      local function clearDeadHooker()
        ui.forward:removeEventListener( "tap", clearDeadHooker )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        visitCop()
      end

      lasthooked = -1
      ui.helper.text = "La Squillo è morta e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearDeadHooker )

    end

  end

  local function visitMafia()

    local function mafiaKill()

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local killicons = {}
      local killnames = {}

      local function clearKill( event )

        for i=1, table.getn( killicons ) do
          killicons[i]:removeSelf()
          killicons[i] = nil
        end
        for i=1, table.getn( killnames ) do
          killnames[i]:removeSelf()
          killnames[i] = nil
        end

        lastmafiakill = event.target.id

        if lastmafiakill ~= -1 then --kill
          ui.helper.text = "La Mafia ha deciso chi uccidere.\n\n[" .. playerinfo[lastmafiakill].name .. "]\n\nLa Mafia chiude gli occhi."
        else --nokill
          ui.helper.text = "La Mafia ha deciso chi uccidere.\n\n[Nessuno]\n\nLa Mafia chiude gli occhi."
        end

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearKillReminder()
          ui.forward:removeEventListener( "tap", clearKillReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitHooker()
        end

        ui.forward:addEventListener( "tap", clearKillReminder )

      end

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI VITTIME:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].alignment ~= 1 then
          killicons[j] = display.newImageRect( uiGroup, "images/interface/stab.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          killicons[j].x, killicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
          killicons[j].id = i
          killicons[j]:addEventListener( "tap", clearKill )
          killnames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, killicons[j].y, "GosmickSans.ttf", 18 )
          killnames[j].anchorX = 0
          j = j + 1
        end
      end
      killicons[j] = display.newImageRect( uiGroup, "images/interface/stab.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      killicons[j].x, killicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
      killicons[j]:addEventListener( "tap", clearKill )
      killicons[j].id = -1
      killnames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, killicons[j].y, "GosmickSans.ttf", 18 )
      killnames[j].anchorX = 0
    end

    ui.helper.text = "La Mafia apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Mafia" )
    activateNightStrat( "Mafia" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Mafioso.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", mafiaKill )

  end

  showNightStrat = function()

    local function backVisitMafia()
      ui.strat:removeEventListener( "tap", backVisitMafia )
      visitMafia()
    end

    local function backVisitHooker()
      ui.strat:removeEventListener( "tap", backVisitHooker )
      visitHooker()
    end

    local function backVisitCop()
      ui.strat:removeEventListener( "tap", backVisitCop )
      visitCop()
    end

    local function backVisitGunsmith()
      ui.strat:removeEventListener( "tap", backVisitGunsmith )
      visitGunsmith()
    end

    ui.roleactionicon:removeSelf()
    ui.roleactionicon = nil
    ui.helper.text = "STRATEGIA GENERALE (NOTTE)"
    ui.rolehandbook.text = roleslib.getNightStrat( settings.setup.title, ui.strat.role, nightcount-1 )
    ui.strat:removeEventListener( "tap", showNightStrat )
    ui.strattext.text = "Indietro"
    if ui.strat.role == "Mafia" then
      ui.strat:addEventListener( "tap", backVisitMafia )
    elseif ui.strat.role == "Squillo" then
      ui.strat:addEventListener( "tap", backVisitHooker )
    elseif ui.strat.role == "Detective" then
      ui.strat:addEventListener( "tap", backVisitCop )
    elseif ui.strat.role == "Armaiolo" then
      ui.strat:addEventListener( "tap", backVisitGunsmith )
    end

  end

  local function visitHandler()
    ui.dayalert.text = ""
    ui.daytime:removeSelf()
    ui.daytime = nil
    visitMafia()
  end

  audio.play( nightsound )

  nightcount = nightcount + 1

  changeBackground( "night" )

  ui.dayalert.text = "CALA LA NOTTE.."
  ui.dayalert.alpha = 1

  ui.helper.text = "\n\nDurante la Notte, tutti i Giocatori tengono gli occhi chiusi. A turno, chiamerò i Ruoli che eseguono Visite Notturne e li guiderò."
  ui.helper.alpha = 1

  ui.daytime = display.newImageRect( uiGroup, "images/interface/moon.png", display.contentWidth * 0.35, display.contentWidth * 0.35 )
  ui.daytime.x, ui.daytime.y = display.contentWidth * 0.75, display.contentHeight * 0.84
  ui.daytime:addEventListener( "tap", visitHandler )

end

local function narratorHints()

  local function stepForward()
    ui.forward:removeEventListener( "tap", stepForward )
    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0
    nightTime()
  end

  ui.forward.alpha = 1
  ui.forwardtext.alpha = 1
  ui.forward:addEventListener( "tap", stepForward )

  ui.helper.text = settings.playernames[10] .. ", finalmente siamo tornati a noi due.\n\nConto su di te per moderare le Discussioni ed esporre le Strategie, così da condurre correttamente lo Scenario.\n\n[E ricordati di non leggere ad alta voce le frasi tra parentesi quadrate!]"
  ui.helper.alpha = 1

end

local function computePlayerinfo()

  for i=1, settings.setup.players do

    table.insert( playerinfo,
      {
        id = i,
        name = settings.playernames[i],
        role = settings.playerroles[i],
        alignment = -1,
        alive = 1, --alive
        gun = 0,
        married = 0,
        revealed = 0,
      }
    )

    if settings.playerroles[i] == "Paesano" then
      playerinfo[i].alignment = 0
    elseif settings.playerroles[i] == "Mafioso" then
      playerinfo[i].alignment = 1
    elseif settings.playerroles[i] == "Squillo" then
      playerinfo[i].alignment = 1
    elseif settings.playerroles[i] == "Armaiolo" then
      playerinfo[i].alignment = 0
      gunsmithid = i
    elseif settings.playerroles[i] == "Detective" then
      playerinfo[i].alignment = 0
      copid = i
    end

    print( "Giocatore " .. i .. ": " .. settings.playerroles[i] )

  end

end

-- create()
function scene:create( event )

  -- background

  ui.background = display.newImageRect( uiGroup, "images/backgrounds/neutralbackground.png", display.contentWidth, display.contentHeight )
  ui.background.x, ui.background.y = display.contentCenterX, display.contentCenterY

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

  local helper = ""

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
  ui.helper.alpha = 0

  -- rolehandbook

  options = {
    text = "",
    x = display.contentCenterX,
    y = display.contentHeight * 0.61,
    width = display.contentWidth * 0.9,
    height = display.contentHeight * 0.6,
    font = "GosmickSans.ttf",
    fontSize = 16,
    align = "left"
  }

  ui.rolehandbook = display.newText( options )
  ui.rolehandbook:setFillColor( 1, 1, 1, 1 )

  -- forwardtext

  ui.forward = display.newRect( uiGroup, display.contentWidth * 0.72, display.contentHeight * 0.9, display.contentWidth * 0.45, display.contentHeight * 0.12 )
  ui.forward:setFillColor( 0, 0, 0, 1 )
  ui.forward.strokeWidth = 2
  ui.forward:setStrokeColor( 1, 1, 1, 1 )
  ui.forward.alpha = 0

  ui.forwardtext = display.newText( uiGroup, "Avanti", ui.forward.x, ui.forward.y, "GosmickSans.ttf", 28 )
  ui.forwardtext:setFillColor( 1, 1, 1, 1 )
  ui.forwardtext.alpha = 0

  -- strat

  ui.strat = display.newRect( uiGroup, display.contentWidth * 0.24, display.contentHeight * 0.9, display.contentWidth * 0.36, display.contentHeight * 0.08 )
  ui.strat:setFillColor( 0, 0, 0, 1 )
  ui.strat.strokeWidth = 2
  ui.strat:setStrokeColor( 1, 1, 1, 1 )
  ui.strat.alpha = 0

  ui.strattext = display.newText( uiGroup, "Strategia", ui.strat.x, ui.strat.y, "GosmickSans.ttf", 18 )
  ui.strattext:setFillColor( 1, 1, 1, 1 )
  ui.strattext.alpha = 0

  -- dayalert
  ui.dayalert = display.newText( uiGroup, "", display.contentWidth * 0.055, display.contentHeight * 0.28, "GosmickSans.ttf", 25 )
  ui.dayalert:setFillColor( 1, 1, 1, 1 )
  ui.dayalert.anchorX = 0
  ui.dayalert.alpha = 0

  -- compute players info

  computePlayerinfo()

  -- narrator hints

  narratorHints()

end

-- scene event listener
scene:addEventListener( "create", scene )

return scene
