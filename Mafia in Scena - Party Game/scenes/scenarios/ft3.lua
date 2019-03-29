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
local lastvigkill
local lastdocsave
local lastlynched

local lastdeaths = {}

local vigid

local lynchedvotes = {}

local nightsound = audio.loadSound( "audio/howl.wav" )
local sunrisesound = audio.loadSound( "audio/rooster.wav" )

local townwinsound = audio.loadSound( "audio/townwin.wav" )
local mafiawinsound = audio.loadSound( "audio/mafiawin.wav" )
local foolwinsound = audio.loadSound( "audio/foolwin.wav" )

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

  local function jointMafiaFoolWins()
    winchannel = audio.play( foolwinsound )
    winchannel2 = timer.performWithDelay( 1000, function() audio.play( mafiawinsound ); end )
    local congratulations1 = congratulate( 1 )
    local congratulations2 = congratulate( 2 )
    ui.helper.text = "La Mafia ha ottenuto il controllo del Villaggio, ed il Folle è stato linciato come un martire.\n\nLa Mafia ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Folle ha vinto!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function jointTownFoolWins()
    winchannel = audio.play( townwinsound )
    local congratulations1 = congratulate( 0 )
    local congratulations2 = congratulate( 2 )
    ui.helper.text = "Il Villaggio ha eliminato la Mafia, ed il Folle è ancora vivo.\n\nIl Villaggio ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Folle ha vinto con disonore!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function foolWins()
    winchannel = audio.play( foolwinsound )
    local congratulations = congratulate( 2 )
    ui.helper.text = "Il Folle è stato linciato come un martire. Il Folle ha vinto!\n\nComplimenti a " .. congratulations .. "."
    endingScenario()
  end

  local function townWins()
    winchannel = audio.play( townwinsound )
    local congratulations = congratulate( 0 )
    ui.helper.text = "Il Villaggio ha eliminato la Mafia. Il Villaggio ha vinto!\n\nComplimenti a " .. congratulations .. "."
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
    local foolcount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].alive == 1 and playerinfo[i].alignment == 0 then
        towncount = towncount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 1 then
        mafiacount = mafiacount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 2 then
        foolcount = foolcount + 1
      end
    end
    return towncount, mafiacount, foolcount
  end

  local towncount, mafiacount, foolcount = alignmentCount()

  if trigger == "lynch" then
    if lastlynched ~= -1 and playerinfo[lastlynched].role == "Folle" then --fool wins
      if mafiacount >= towncount then
        jointMafiaFoolWins()
      else
        foolWins()
      end
    elseif mafiacount == 0 then
      if foolcount == 0 then
        townWins()
      else
        jointTownFoolWins()
      end
    elseif mafiacount >= towncount+foolcount then
      mafiaWins()
    else
      nightTime()
    end
  elseif trigger == "kill" then
    if mafiacount == 0 then
      townWins()
    elseif mafiacount >= towncount+foolcount then
      mafiaWins()
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
    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0

    display.remove( ui.roleactionicon )
    ui.roleactionicon = nil

    enforceWinCondition( "lynch" )
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
          lynchedname[j] = display.newText( uiGroup, "Lincia " .. settings.playernames[i], display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 18 )
          lynchedname[j].anchorX = 0
          lynchaddvote[j] = display.newImageRect( uiGroup, "images/interface/hang.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          lynchaddvote[j].x, lynchaddvote[j].y = display.contentWidth * 0.85, lynchedname[j].y
          lynchaddvote[j].id = i
          lynchaddvote[j]:addEventListener( "tap", addVote )
          j = j + 1
        end
      end
      if j <= settings.setup.players then
        lynchedname[j] = display.newText( uiGroup, "**NON LINCIARE", display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 18 )
        lynchedname[j].anchorX = 0
        lynchaddvote[j] = display.newImageRect( uiGroup, "images/interface/peace.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
        lynchaddvote[j].x, lynchaddvote[j].y = display.contentWidth * 0.85, lynchedname[j].y
        lynchaddvote[j].id = settings.setup.players + 1
        lynchaddvote[j]:addEventListener( "tap", addVote )
      end

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
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " non ha ancora votato", display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 12 )
          votedicon = "vote"
        elseif lynchedvotes[i] == settings.setup.players+1 then
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " vota **Non Linciare", display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 12 )
          votedicon = "voted"
        else
          lynchvote[j] = display.newText( uiGroup, settings.playernames[i] .. " vota " .. settings.playernames[ lynchedvotes[i] ], display.contentWidth * 0.07, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086, "GosmickSans.ttf", 12 )
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
        discussalivenames[w] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.24, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.06, "GosmickSans.ttf", 17 )
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

  print( "sunriseTime" )

  local function endSunriseTime()
    print( "endSunriseTime" )
    ui.forward:removeEventListener( "tap", endSunriseTime )
    ui.forward.alpha = 0
    ui.forwardtext.alpha = 0

    display.remove( ui.roleactionicon )
    ui.roleactionicon = nil

    enforceWinCondition( "kill" )
  end

  local function checkDeaths()

    print( "checkDeaths" )

    local function announceDeaths()

      print( "announceDeaths" )

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

  local function evaluateNightVisits()

    ui.forward:removeEventListener( "tap", evaluateNightVisits )


    lastdeaths = {}

    local vigkilled = false
    local dochooked = false

    if lasthooked ~= -1 and playerinfo[lasthooked].role == "Dottore" then
      dochooked = true
    end

    if lastmafiakill ~= -1 then --mafiakilled
      if lastdocsave == -1 or dochooked == true or lastdocsave ~= lastmafiakill then --docsave not happens
        table.insert( lastdeaths, lastmafiakill ) --mafiakill happens
        if lastmafiakill == vigid then
          vigkilled = true --mafia killed vig
        end
      end
    end

    if lastvigkill ~= -1 and lasthooked ~= vigid and vigkilled == false then --vigvisit
      if lastmafiakill == lastvigkill then --vig+mafia same target
        if lastdocsave == -1 or dochooked == true or lastdocsave ~= vigid then
          table.insert( lastdeaths, vigid ) --vig dies from visiting mafia target
        end
      else
        if lastdocsave == -1 or dochooked == true or lastdocsave ~= lastvigkill then --novigsave or wrongvigsave
          table.insert( lastdeaths, lastvigkill ) --vigkill happens
        end
      end
    end

    local function shuffle( a )
    	local c = #a
    	for i=1, c*20 do
    		local ndx0 = math.random( 1, c )
    		local ndx1 = math.random( 1, c )
    		local temp = a[ndx0]
    		a[ndx0] = a[ndx1]
    		a[ndx1] = temp
    	end
      return a
    end

    lastdeaths = shuffle( lastdeaths )

    endNightTime()

  end

  local showNightStrat

  local function activateNightStrat( role )
    ui.strat.alpha = 1
    ui.strattext.alpha = 1
    ui.strattext.text = "Strategia"
    ui.strat.role = role
    ui.strat:addEventListener( "tap", showNightStrat )
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
          ui.helper.text = "Il Dottore ha deciso chi soccorrere.\n\n[" .. playerinfo[lastdocsave].name .. "]"
        else --nosave
          ui.helper.text = "Il Dottore ha deciso chi soccorrere.\n\n[Nessuno]"
        end

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearSaveReminder()
          ui.forward:removeEventListener( "tap", clearSaveReminder )
          ui.forward:addEventListener( "tap", evaluateNightVisits )
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
          saveicons[j].x, saveicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086
          saveicons[j].id = i
          saveicons[j]:addEventListener( "tap", clearSave )
          savenames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, saveicons[j].y, "GosmickSans.ttf", 18 )
          savenames[j].anchorX = 0
          j = j + 1
        end
      end
      saveicons[j] = display.newImageRect( uiGroup, "images/interface/save.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      saveicons[j].x, saveicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086
      saveicons[j]:addEventListener( "tap", clearSave )
      saveicons[j].id = -1
      savenames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, saveicons[j].y, "GosmickSans.ttf", 18 )
      savenames[j].anchorX = 0
    end

    local doccount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Dottore" and playerinfo[i].alive == 1 then
        doccount = doccount + 1
      end
    end

    if doccount > 0 then
      ui.helper.text = "Il Dottore apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Dottore" )

      activateNightStrat( "Dottore" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Dottore.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", docSave )
    else
      lastdocsave = -1
      ui.helper.text = "Il Dottore è morto e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", evaluateNightVisits )
    end

  end

  local function visitVigilante()

    local function vigilanteShotgun()

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local shotgunicons = {}
      local shotgunnames = {}

      local function clearShotgun( event )

        for i=1, table.getn( shotgunicons ) do
          shotgunicons[i]:removeSelf()
          shotgunicons[i] = nil
        end
        for i=1, table.getn( shotgunnames ) do
          shotgunnames[i]:removeSelf()
          shotgunnames[i] = nil
        end

        lastvigkill = event.target.id

        if lastvigkill ~= -1 then --shotgun
          ui.helper.text = "Il Vigilante ha deciso chi uccidere.\n\n[" .. playerinfo[lastvigkill].name .. "]\n\nIl Vigilante chiude gli occhi."
        else --noshotgun
          ui.helper.text = "Il Vigilante ha deciso chi uccidere.\n\n[Nessuno]\n\nIl Vigilante chiude gli occhi."
        end

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearShotgunReminder()
          ui.forward:removeEventListener( "tap", clearShotgunReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitDoctor()
        end

        ui.forward:addEventListener( "tap", clearShotgunReminder )

      end

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI VITTIME:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].role ~= "Vigilante" then
          shotgunicons[j] = display.newImageRect( uiGroup, "images/interface/shotgun.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          shotgunicons[j].x, shotgunicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086
          shotgunicons[j].id = i
          shotgunicons[j]:addEventListener( "tap", clearShotgun )
          shotgunnames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, shotgunicons[j].y, "GosmickSans.ttf", 18 )
          shotgunnames[j].anchorX = 0
          j = j + 1
        end
      end
      shotgunicons[j] = display.newImageRect( uiGroup, "images/interface/shotgun.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
      shotgunicons[j].x, shotgunicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.086
      shotgunicons[j]:addEventListener( "tap", clearShotgun )
      shotgunicons[j].id = -1
      shotgunnames[j] = display.newText( uiGroup, "**Nessuno", display.contentWidth * 0.1, shotgunicons[j].y, "GosmickSans.ttf", 18 )
      shotgunnames[j].anchorX = 0
    end

    local vigcount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Vigilante" and playerinfo[i].alive == 1 then
        vigcount = vigcount + 1
      end
    end

    if vigcount > 0 then
      ui.helper.text = "Il Vigilante apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Vigilante" )

      activateNightStrat( "Vigilante" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Vigilante.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", vigilanteShotgun )
    else

      local function clearDeadVigilante()
        ui.forward:removeEventListener( "tap", clearDeadVigilante )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        visitDoctor()
      end
      lastvigkill = -1
      ui.helper.text = "Il Vigilante è morto e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearDeadVigilante )
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

        if playerinfo[investigated].alignment == 0 or playerinfo[investigated].alignment == 2 then
          alignmentreport = "Segno positivo, " .. playerinfo[investigated].name .. " è Innocente"
        elseif playerinfo[investigated].alignment == 1 then
          alignmentreport = "Segno negativo, " .. playerinfo[investigated].name .. " è Colpevole"
        end

        if lasthooked ~= -1 and playerinfo[lasthooked].role == "Detective" then
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
          visitVigilante()
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
        visitVigilante()
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

    local mafiacount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].alignment == 1 and playerinfo[i].alive == 1 then
        mafiacount = mafiacount + 1
      end
    end

    if mafiacount > 0 then
      ui.helper.text = "La Mafia apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Mafia" )

      activateNightStrat( "Mafia" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Mafioso.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", mafiaKill )
    else

      local function clearDeadMafia()
        ui.forward:removeEventListener( "tap", clearDeadMafia )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        visitHooker()
      end

      ui.helper.text = "La Mafia è stata eliminata e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearDeadMafia )
    end

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

    local function backVisitVigilante()
      ui.strat:removeEventListener( "tap", backVisitVigilante )
      visitVigilante()
    end

    local function backVisitDoctor()
      ui.strat:removeEventListener( "tap", backVisitDoctor )
      visitDoctor()
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
    elseif ui.strat.role == "Vigilante" then
        ui.strat:addEventListener( "tap", backVisitVigilante )
    elseif ui.strat.role == "Dottore" then
      ui.strat:addEventListener( "tap", backVisitDoctor )
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

  ui.background:removeSelf()
  ui.background = display.newImageRect( uiGroup, "images/backgrounds/nightbackground.png", display.contentWidth, display.contentHeight )
  ui.background.x, ui.background.y = display.contentCenterX, display.contentCenterY
  ui.background:toBack()

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
      }
    )

    if settings.playerroles[i] == "Paesano" then
      playerinfo[i].alignment = 0
    elseif settings.playerroles[i] == "Mafioso" then
      playerinfo[i].alignment = 1
    elseif settings.playerroles[i] == "Squillo" then
      playerinfo[i].alignment = 1
    elseif settings.playerroles[i] == "Dottore" then
      playerinfo[i].alignment = 0
    elseif settings.playerroles[i] == "Vigilante" then
      playerinfo[i].alignment = 0
      vigid = i
    elseif settings.playerroles[i] == "Detective" then
      playerinfo[i].alignment = 0
    elseif settings.playerroles[i] == "Folle" then
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
