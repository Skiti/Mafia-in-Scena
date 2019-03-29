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
local lastkillerkill
local lastdocsave
local lastculted

local currentvisit

local lastdeaths = {}
local lastshrunk = {}

local lynchedvotes = {}
local lastlynched

local nightsound = audio.loadSound( "audio/howl.wav" )
local sunrisesound = audio.loadSound( "audio/rooster.wav" )

local townwinsound = audio.loadSound( "audio/townwin.wav" )
local killerwinsound = audio.loadSound( "audio/killerwin.wav" )
local cultwinsound = audio.loadSound( "audio/cultwin.wav" )

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
    deathsound = audio.loadSound( settings.playerdeaths[dead], system.DocumentsDirectory )
    audio.play( deathsound )
  end
end

local function enforceWinCondition( trigger )

  local winchannel
  local winchannel2
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
    audio.stop( winchannel2 )

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

  local function jointKillerCultWins()
    winchannel = audio.play( killerwinsound )
    winchannel2 = timer.performWithDelay( 1000, function() audio.play( cultwinsound ); end )
    local congratulations1 = congratulate( 2 )
    local congratulations2 = congratulate( 3 )
    ui.helper.text = "Il Killer ha portato a termine una strage ed il Culto ha convertito il Villaggio.\n\nIl Killer ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Culto ha vinto!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function cultWins()
    winchannel = audio.play( cultwinsound )
    local congratulations = congratulate( 3 )
    ui.helper.text = "Il Culto ha convertito il Villaggio. Il Culto ha vinto!\n\nComplimenti a " .. congratulations .. "."
    endingScenario()
  end

  local function killerWins()
    winchannel = audio.play( killerwinsound )
    local congratulations = congratulate( 2 )
    ui.helper.text = "Il Killer ha portato a termine una strage. Il Killer ha vinto!\n\nComplimenti a " .. congratulations .. "."
    endingScenario()
  end

  local function townWins()
    winchannel = audio.play( townwinsound )
    local congratulations = congratulate( 0 )
    ui.helper.text = "Il Villaggio ha eradicato il Culto ed eliminato il Killer. Il Villaggio ha vinto!\n\nComplimenti a " .. congratulations .. "."
    endingScenario()
  end

  local function alignmentCount()
    local towncount = 0
    local killercount = 0
    local cultcount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].alive == 1 and playerinfo[i].alignment == 0 then
        towncount = towncount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 2 then
        killercount = killercount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 3 then
        cultcount = cultcount + 1
      end
    end
    return towncount, killercount, cultcount
  end

  local towncount, killercount, cultcount = alignmentCount()

  if trigger == "lynch" then
    if killercount+cultcount == 0 then
      townWins()
    elseif killercount == 1 and towncount+killercount+cultcount <= 2 then
      killerWins()
    elseif cultcount > towncount+killercount then
      cultWins()
    else
      nightTime()
    end
  elseif trigger == "kill" then
    if killercount+cultcount == 0 then
      townWins()
    elseif killercount == 1 and towncount+killercount+cultcount <= 2 then
      killerWins()
    elseif cultcount > towncount+killercount then
      cultWins()
    else
      seconds = 0
      minutes = 0
      dayTime()
    end
  end

end

sunsetTime = function()

  local function endSunsetTime()

    ui.forward:removeEventListener( "tap", endSunsetTime )

    display.remove( ui.roleactionicon )
    ui.roleactionicon = nil

    if lastlynched ~= -1 and playerinfo[lastlynched].role == "Capocultista" then

      local count = 0

      local function suicideCultist()
        count = count + 1
        ui.helper.text = ""
        display.remove( ui.roleactionicon )
        if count > settings.setup.players then
          ui.forward:removeEventListener( "tap", suicideCultist )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          enforceWinCondition( "lynch" )
        elseif playerinfo[count].alive == 0 or playerinfo[count].role ~= "Cultista" then
          suicideCultist()
        elseif playerinfo[count].alive == 1 and playerinfo[count].role == "Cultista" then
          ui.helper.text = playerinfo[count].name .. " beve da un calice avvelenato ed esala il suo ultimo respiro."
          playDeathAudio( count )
          playerinfo[count].alive = 0
          ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[count].role .. ".png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
          ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
        end
      end

      ui.helper.text = "Il Capocultista è morto.\n\nIl Culto è stato eradicato. I Cultisti, presi dalla disperazione, si stanno suicidando in massa."
      ui.forward:addEventListener( "tap", suicideCultist )

    else

      ui.forward.alpha = 0
      ui.forwardtext.alpha = 0
      enforceWinCondition( "lynch" )

    end

  end

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
            lastlynched = mostvoted
            playerinfo[mostvoted].alive = 0
            ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[mostvoted].role .. ".png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
            ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
          else
            lastlynched = -1
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
          lynchedname[j] = display.newText( uiGroup, "Lincia " .. settings.playernames[i], display.contentWidth * 0.07, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 18 )
          lynchedname[j].anchorX = 0
          lynchaddvote[j] = display.newImageRect( uiGroup, "images/interface/hang.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          lynchaddvote[j].x, lynchaddvote[j].y = display.contentWidth * 0.85, lynchedname[j].y
          lynchaddvote[j].id = i
          lynchaddvote[j]:addEventListener( "tap", addVote )
          j = j + 1
        end
      end
      lynchedname[j] = display.newText( uiGroup, "**NON LINCIARE", display.contentWidth * 0.07, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 18 )
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
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " non ha ancora votato", display.contentWidth * 0.07, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 12 )
          votedicon = "vote"
        elseif lynchedvotes[i] == settings.setup.players+1 then
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " vota **Non Linciare", display.contentWidth * 0.07, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 12 )
          votedicon = "voted"
        else
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " vota " .. settings.playernames[ lynchedvotes[i] ], display.contentWidth * 0.07, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 12 )
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
    ui.strat.alpha = 0
    ui.strattext.alpha = 0

    sunsetTime()
  end

  local showDayStrat

  discussLynch = function()

    local discussalivenames = {}
    local discussdeadnames = {}

    local discussdeaths = {}
    local discussroles = {}

    stoppedtime = false

    ui.dayalert.text = ""

    local function clearDiscussLynch()

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

    end

    local clearShowDayStrat

    local function clearVoteLynch()
      timer.cancel( discussionTimer )
      clearDiscussLynch()
      ui.forward:removeEventListener( "tap", clearVoteLynch )
      ui.forward.alpha = 0
      ui.forwardtext.alpha = 0
      ui.strat:removeEventListener( "tap", clearShowDayStrat )
      endDayTime()
    end

    clearShowDayStrat = function()
      clearDiscussLynch()
      ui.forward:removeEventListener( "tap", clearVoteLynch )
      ui.forward.alpha = 0
      ui.forwardtext.alpha = 0
      ui.strat:removeEventListener( "tap", clearShowDayStrat )
      showDayStrat()
    end

    display.remove( ui.daytime )
    ui.daytime = nil

    local alive
    local role

    local j = 1
    local w = 1
    for i=1, settings.setup.players do
      if playerinfo[i].alive == 1 then
        discussalivenames[w] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.24, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.06, "GosmickSans.ttf", 17 )
        discussalivenames[w].anchorX = 0

        if playerinfo[i].revealed == 1 then
          discussroles[j] = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[i].role .. ".png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
        else
          discussroles[j] = display.newImageRect( uiGroup, "images/interface/unknown.png", display.contentWidth * 0.075, display.contentWidth * 0.075 )
        end
        discussroles[j].x, discussroles[j].y = display.contentWidth * 0.13, discussalivenames[w].y

        j = j + 1
        w = w + 1
      end
    end

    w = 1
    for i=1, settings.setup.players do
      if playerinfo[i].alive == 0 then
        discussdeadnames[w] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.24, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.06, "GosmickSans.ttf", 17 )
        discussdeadnames[w].anchorX = 0
        discussdeadnames[w]:setFillColor( 250/255, 30/255, 30/255, 1 )

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

        if playerinfo[dead].role == "Capocultista" then

          local count = 0

          local function suicideCultist()
            count = count + 1
            ui.helper.text = ""
            display.remove( ui.roleactionicon )
            if count > settings.setup.players then
              ui.forward:removeEventListener( "tap", suicideCultist )
              announceDeaths()
            elseif playerinfo[count].alive == 1 and playerinfo[count].role == "Cultista" then
              ui.helper.text = playerinfo[count].name .. " beve da un calice avvelenato ed esala il suo ultimo respiro."
              playDeathAudio( count )
              playerinfo[count].alive = 0
              ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/" .. playerinfo[count].role .. ".png", display.contentWidth * 0.3, display.contentWidth * 0.3 )
              ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
            else
              suicideCultist()
            end
          end

          ui.helper.text = "Il Capocultista è morto.\n\nIl Culto è stato eradicato. I Cultisti, presi dalla disperazione, si stanno suicidando in massa."
          ui.forward:removeEventListener( "tap", announceDeaths )
          ui.forward:addEventListener( "tap", suicideCultist )

        end

      elseif table.getn( lastdeaths ) == 0 then

        ui.forward:removeEventListener( "tap", announceDeaths )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
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

  local function cultistConversionCheck()

    local count = 0

    local function cultistConversion()
      count = count + 1
      ui.helper.text = ""
      ui.rolehandbook.text = ""
      if count > settings.setup.players then
        ui.forward:removeEventListener( "tap", cultistConversion )
        endNightTime()
      elseif playerinfo[count].alive == 0 then
        cultistConversion()
      elseif playerinfo[count].alive == 1 then
        if playerinfo[count].role == "Cultista" then
          ui.helper.text = playerinfo[count].name .. " apre gli occhi."
          ui.rolehandbook.text = "\nIl Giocatore loda il Culto, oppure lo condanna.\n\n[Segno positivo, è un Cultista]\n\nPoi chiude gli occhi."
        elseif playerinfo[count].role == "Capocultista" then
          ui.helper.text = playerinfo[count].name .. " apre gli occhi."
          ui.rolehandbook.text = "\nIl Giocatore loda il Culto, oppure lo condanna.\n\n[Segno positivo, è il Capocultista]\n\nPoi chiude gli occhi."
        elseif count <= settings.setup.players then
          ui.helper.text = playerinfo[count].name .. " apre gli occhi."
          ui.rolehandbook.text = "\nIl Giocatore loda il Culto, oppure lo condanna.\n\n[Segno negativo, si oppone al Culto]\n\nPoi chiude gli occhi."
        end
      end
    end

    local cultleadercount = 0
    for i=1, settings.setup.players do
      if playerinfo[i].role == "Capocultista" and playerinfo[i].alive == 1 then
        cultleadercount = cultleadercount + 1
      end
    end

    if cultleadercount > 0 then
      ui.helper.text = "Tenete ancora chiusi gli occhi."
      ui.rolehandbook.text = "A turno, farò aprire gli occhi a ciascun Giocatore. Gli appartenenti al Culto riceveranno un segno positivo, tutti gli altri invece un segno negativo."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", cultistConversion )
    else
      endNightTime()
    end

  end

  local function evaluateNightVisits()

    ui.forward:removeEventListener( "tap", evaluateNightVisits )

    lastdeaths = {}

    for i=1, table.getn( lastshrunk ) do
      if playerinfo[ lastshrunk[i] ].role == "Killer" then --killerredeemed
        playerinfo[ lastshrunk[i] ].role = "Paesano"
        playerinfo[ lastshrunk[i] ].alignment = 0
      end
      if lastshrunk[i] == lastculted then
        lastculted = -1 --conversionaverted
      end
    end

    if lastculted ~= -1 then --convertedtocult
      playerinfo[lastculted].role = "Cultista"
      playerinfo[lastculted].alignment = 3
    end

    if lastkillerkill ~= -1 then --killeraliveandactive
      if lastdocsave == -1 or lastdocsave ~= lastkillerkill then --nokillersave or wrongkillersave
        table.insert( lastdeaths, lastkillerkill ) --killerkill happens
      end
    end

    cultistConversionCheck()

  end

  local showNightStrat
  local visitSomeone

  local function activateNightStrat( role )
    ui.strat.alpha = 1
    ui.strattext.alpha = 1
    ui.strattext.text = "Strategia"
    ui.strat.role = role
    ui.strat:addEventListener( "tap", showNightStrat )
  end

  local function visitVillager()

    local function villagerLoafs()

      local function clearVillager( event )

        ui.forward:removeEventListener( "tap", clearVillager )

        ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Paesano, non ha visitato nessuno]\n\nIl Giocatore chiude gli occhi."
        ui.rolehandbook.text = ""
        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearVillagerReminder()
          ui.forward:removeEventListener( "tap", clearVillagerReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitSomeone()
        end

        ui.forward:addEventListener( "tap", clearVillagerReminder )

      end

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "[Il Paesano non esegue alcuna Visita Notturna quindi non dovrà indicare nessuno]"
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearVillager )

    end

    ui.helper.text = playerinfo[currentvisit].name .. " apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Paesano" )

    activateNightStrat( "Paesano" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Paesano.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", villagerLoafs )

  end

  local function visitCultist()

    local function cultistPraise()

      local function clearCultist( event )

        ui.forward:removeEventListener( "tap", clearCultist )

        ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Cultista, ha lodato il Culto senza aver visitato nessuno]\n\nIl Giocatore chiude gli occhi."
        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearCultistReminder()
          ui.forward:removeEventListener( "tap", clearCultistReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitSomeone()
        end

        ui.forward:addEventListener( "tap", clearCultistReminder )

      end

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "[Il Cultista non esegue alcuna Visita Notturna quindi non dovrà indicare nessuno]"
      ui.rolehandbook.text = ""
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearCultist )

    end

    ui.helper.text = playerinfo[currentvisit].name .. " apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Cultista" )

    activateNightStrat( "Cultista" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Cultista.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", cultistPraise )

  end

  local function visitCultleader()

    local function leaderCulted()

      local cultedicons = {}
      local cultednames = {}

      local function clearCulted( event )

        for i=1, table.getn( cultedicons ) do
          cultedicons[i]:removeSelf()
          cultedicons[i] = nil
        end
        for i=1, table.getn( cultednames ) do
          cultednames[i]:removeSelf()
          cultednames[i] = nil
        end

        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        ui.forward:removeEventListener( "tap", clearCulted )

        lastculted = event.target.id

        if lastculted ~= -1 then --save
          ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Capocultista, ha visitato " .. playerinfo[lastculted].name .. "]\n\nIl Giocatore chiude gli occhi."
        else --nosave
          ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Capocultista, non ha visitato Nessuno]\n\nIl Giocatore chiude gli occhi."
        end

        ui.rolehandbook.text = ""
        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearCultedReminder()
          ui.forward:removeEventListener( "tap", clearCultedReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitSomeone()
        end

        ui.forward:addEventListener( "tap", clearCultedReminder )

      end

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI CONVERSIONI:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].role ~= "Capocultista" then
          cultedicons[j] = display.newImageRect( uiGroup, "images/interface/culted.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          cultedicons[j].x, cultedicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
          cultedicons[j].id = i
          cultedicons[j]:addEventListener( "tap", clearCulted )
          cultednames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, cultedicons[j].y, "GosmickSans.ttf", 18 )
          cultednames[j].anchorX = 0
          j = j + 1
        end
      end
      cultedicons[j] = display.newImageRect( uiGroup, "images/interface/culted.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      cultedicons[j].x, cultedicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
      cultedicons[j]:addEventListener( "tap", clearCulted )
      cultedicons[j].id = -1
      cultednames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, cultedicons[j].y, "GosmickSans.ttf", 18 )
      cultednames[j].anchorX = 0

    end

    ui.helper.text = playerinfo[currentvisit].name .. " apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Capocultista" )

    activateNightStrat( "Capocultista" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Capocultista.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", leaderCulted )

  end

  local function visitDoctor()

    local function docSave()

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local saveicons = {}
      local savenames = {}

      local function clearSave( event )

        for i=1, table.getn( saveicons ) do
          saveicons[i]:removeSelf()
          saveicons[i] = nil
        end
        for i=1, table.getn( savenames ) do
          savenames[i]:removeSelf()
          savenames[i] = nil
        end

        lastdocsave = event.target.id

        if lastdocsave ~= -1 then --save
          ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Dottore, ha visitato " .. playerinfo[event.target.id].name .. "]\n\nIl Giocatore chiude gli occhi."
        else --nosave
          ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Dottore, non ha visitato Nessuno]\n\nIl Giocatore chiude gli occhi."
        end

        ui.rolehandbook.text = ""
        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearSaveReminder()
          ui.forward:removeEventListener( "tap", clearSaveReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitSomeone()
        end

        ui.forward:addEventListener( "tap", clearSaveReminder )

      end

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI SALVATAGGI:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].role ~= "Dottore" then
          saveicons[j] = display.newImageRect( uiGroup, "images/interface/save.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          saveicons[j].x, saveicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
          saveicons[j].id = i
          saveicons[j]:addEventListener( "tap", clearSave )
          savenames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, saveicons[j].y, "GosmickSans.ttf", 18 )
          savenames[j].anchorX = 0
          j = j + 1
        end
      end
      saveicons[j] = display.newImageRect( uiGroup, "images/interface/save.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      saveicons[j].x, saveicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
      saveicons[j]:addEventListener( "tap", clearSave )
      saveicons[j].id = -1
      savenames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, saveicons[j].y, "GosmickSans.ttf", 18 )
      savenames[j].anchorX = 0
    end

    ui.helper.text = playerinfo[currentvisit].name .. " apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Dottore" )

    activateNightStrat( "Dottore" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Dottore.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", docSave )

  end

  local function visitKiller()

    local function killerKill()

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

        lastkillerkill = event.target.id

        ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Killer, ha visitato " .. playerinfo[lastkillerkill].name .. "]\n\nIl Giocatore chiude gli occhi."

        ui.rolehandbook.text = ""
        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearKillReminder()
          ui.forward:removeEventListener( "tap", clearKillReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitSomeone()
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
        if playerinfo[i].alive == 1 and playerinfo[i].alignment ~= 2 then
          killicons[j] = display.newImageRect( uiGroup, "images/interface/stab.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          killicons[j].x, killicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
          killicons[j].id = i
          killicons[j]:addEventListener( "tap", clearKill )
          killnames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, killicons[j].y, "GosmickSans.ttf", 18 )
          killnames[j].anchorX = 0
          j = j + 1
        end
      end
    end

    ui.helper.text = playerinfo[currentvisit].name .. " apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Killer" )

    activateNightStrat( "Killer" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Killer.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", killerKill )

  end

  local function visitShrink()

    local function shrinkShrunk()

      local shrunkicons = {}
      local shrunknames = {}

      local function clearShrunk( event )

        for i=1, table.getn( shrunkicons ) do
          shrunkicons[i]:removeSelf()
          shrunkicons[i] = nil
        end
        for i=1, table.getn( shrunknames ) do
          shrunknames[i]:removeSelf()
          shrunknames[i] = nil
        end

        ui.forward:removeEventListener( "tap", clearShrunk )

        local shrunktarget = event.target.id

        if shrunktarget ~= -1 then --shrunk
          table.insert( lastshrunk, shrunktarget )
          ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Strizzacervelli, ha visitato " .. playerinfo[shrunktarget].name .. "]\n\nIl Giocatore chiude gli occhi."
        else --noshrunk
          ui.helper.text = playerinfo[currentvisit].name .. " ha eseguito la sua Visita Notturna.\n\n[Come Strizzacervelli, non ha visitato Nessuno]\n\nIl Giocatore chiude gli occhi."
        end

        ui.rolehandbook.text = ""
        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearShrunkReminder()
          ui.forward:removeEventListener( "tap", clearShrunkReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitSomeone()
        end

        ui.forward:addEventListener( "tap", clearShrunkReminder )

      end

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI PSICANALISI:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 then
          shrunkicons[j] = display.newImageRect( uiGroup, "images/interface/shrunk.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          shrunkicons[j].x, shrunkicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
          shrunkicons[j].id = i
          shrunkicons[j]:addEventListener( "tap", clearShrunk )
          shrunknames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, shrunkicons[j].y, "GosmickSans.ttf", 18 )
          shrunknames[j].anchorX = 0
          j = j + 1
        end
      end
      shrunkicons[j] = display.newImageRect( uiGroup, "images/interface/shrunk.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      shrunkicons[j].x, shrunkicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.36 + (j-1) * display.contentHeight * 0.09
      shrunkicons[j]:addEventListener( "tap", clearShrunk )
      shrunkicons[j].id = -1
      shrunknames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, shrunkicons[j].y, "GosmickSans.ttf", 18 )
      shrunknames[j].anchorX = 0

    end

    ui.helper.text = playerinfo[currentvisit].name .. " apre gli occhi."
    ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Strizzacervelli" )

    activateNightStrat( "Strizzacervelli" )

    ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Strizzacervelli.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
    ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
    ui.roleactionicon:addEventListener( "tap", shrinkShrunk )

  end

  visitSomeone = function()
    currentvisit = currentvisit + 1
    if currentvisit <= settings.setup.players then
      if playerinfo[currentvisit].alive == 1 then
        if playerinfo[currentvisit].role == "Strizzacervelli" then
          visitShrink()
        elseif playerinfo[currentvisit].role == "Killer" then
          visitKiller()
        elseif playerinfo[currentvisit].role == "Capocultista" then
          visitCultleader()
        elseif playerinfo[currentvisit].role == "Dottore" then
          visitDoctor()
        elseif playerinfo[currentvisit].role == "Cultista" then
          visitCultist()
        elseif playerinfo[currentvisit].role == "Paesano" then
          visitVillager()
        end
      else
        visitSomeone()
      end
    else
      evaluateNightVisits()
    end
  end

  showNightStrat = function()

    local function backVisitShrink()
      ui.strat:removeEventListener( "tap", backVisitShrink )
      visitShrink()
    end

    local function backVisitKiller()
      ui.strat:removeEventListener( "tap", backVisitKiller )
      visitKiller()
    end

    local function backVisitCultleader()
      ui.strat:removeEventListener( "tap", backVisitCultleader )
      visitCultleader()
    end

    local function backVisitDoctor()
      ui.strat:removeEventListener( "tap", backVisitDoctor )
      visitDoctor()
    end

    local function backVisitCultist()
      ui.strat:removeEventListener( "tap", backVisitCultist )
      visitCultist()
    end

    local function backVisitVillager()
      ui.strat:removeEventListener( "tap", backVisitVillager )
      visitVillager()
    end

    ui.roleactionicon:removeSelf()
    ui.roleactionicon = nil
    ui.helper.text = "STRATEGIA GENERALE (NOTTE)"
    ui.rolehandbook.text = roleslib.getNightStrat( settings.setup.title, "Lode al Culto", nightcount-1 )
    ui.strat:removeEventListener( "tap", showNightStrat )
    ui.strattext.text = "Indietro"
    if ui.strat.role == "Strizzacervelli" then
      ui.strat:addEventListener( "tap", backVisitShrink )
    elseif ui.strat.role == "Killer" then
      ui.strat:addEventListener( "tap", backVisitKiller )
    elseif ui.strat.role == "Capocultista" then
      ui.strat:addEventListener( "tap", backVisitCultleader )
    elseif ui.strat.role == "Dottore" then
      ui.strat:addEventListener( "tap", backVisitDoctor )
    elseif ui.strat.role == "Cultista" then
      ui.strat:addEventListener( "tap", backVisitCultist )
    elseif ui.strat.role == "Cultista" then
      ui.strat:addEventListener( "tap", backVisitCultist )
    elseif ui.strat.role == "Paesano" then
      ui.strat:addEventListener( "tap", backVisitVillager )
    end

  end

  local function visitHandler()
    ui.dayalert.text = ""
    ui.daytime:removeSelf()
    ui.daytime = nil
    currentvisit = 0
    lastshrunk = {}
    lastkillerkill = -1
    lastdocsave = -1
    lastculted = -1
    visitSomeone()
  end

  audio.play( nightsound )

  changeBackground( "night" )

  nightcount = nightcount + 1

  ui.dayalert.text = "CALA LA NOTTE.."
  ui.dayalert.alpha = 1

  ui.helper.text = "\n\nDurante la Notte, tutti i Giocatori tengono gli occhi chiusi. A turno, chiamerò i Giocatori e li guiderò. Se il loro Ruolo non prevede Visite Notturne, non dovranno fare nulla."
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
      }
    )

    if settings.playerroles[i] == "Dottore" then
      playerinfo[i].alignment = 0
    elseif settings.playerroles[i] == "Strizzacervelli" then
      playerinfo[i].alignment = 0
    elseif settings.playerroles[i] == "Capocultista" then
      playerinfo[i].alignment = 3
    elseif settings.playerroles[i] == "Killer" then
      playerinfo[i].alignment = 2
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
