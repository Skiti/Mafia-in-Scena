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
local lastyak
local lastshrunk
local lastdocsave
local lastlynched

local lastdeaths = {}

local yakid
local docid
local shrinkid
local lyncherid
local lynchertarget

local lynchedvotes = {}

local nightsound = audio.loadSound( "audio/howl.wav" )
local sunrisesound = audio.loadSound( "audio/rooster.wav" )

local townwinsound = audio.loadSound( "audio/townwin.wav" )
local mafiawinsound = audio.loadSound( "audio/mafiawin.wav" )
local foolwinsound = audio.loadSound( "audio/foolwin.wav" )
local lyncherwinsound = audio.loadSound( "audio/lyncherwin.wav" )

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
  local winchannel3
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
    audio.stop( winchannel3 )

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

  local function jointMafiaFoolLyncherWins()
    winchannel = audio.play( foolwinsound )
    winchannel2 = timer.performWithDelay( 500, function() audio.play( lyncherwinsound ); end )
    winchannel3 = timer.performWithDelay( 1000, function() audio.play( mafiawinsound ); end )
    local congratulations1 = congratulate( 1 )
    local congratulations2 = congratulate( 2 )
    local congratulations3 = congratulate( 3 )
    ui.helper.text = "La Mafia ha ottenuto il controllo del Villaggio, il Folle è stato linciato come un martire e l'Offeso si è vendicato dell'offesa subita.\nLa Mafia ha vinto! Complimenti a " .. congratulations1 .. ".\nIl Folle ha vinto! Complimenti a " .. congratulations2 .. ".\nL'Offeso ha vinto! Complimenti a " .. congratulations3 .. "."
    endingScenario()
  end

  local function jointMafiaLyncherWins()
    winchannel = audio.play( lyncherwinsound )
    winchannel2 = timer.performWithDelay( 1000, function() audio.play( mafiawinsound ); end )
    local congratulations1 = congratulate( 1 )
    local congratulations2 = congratulate( 3 )
    ui.helper.text = "La Mafia ha ottenuto il controllo del Villaggio, e l'Offeso si è vendicato dell'offesa subita.\n\nLa Mafia ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nL'Offeso ha vinto!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function jointMafiaFoolWins()
    winchannel = audio.play( foolwinsound )
    winchannel2 = timer.performWithDelay( 1000, function() audio.play( mafiawinsound ); end )
    local congratulations1 = congratulate( 1 )
    local congratulations2 = congratulate( 2 )
    ui.helper.text = "La Mafia ha ottenuto il controllo del Villaggio, ed il Folle è stato linciato come un martire.\n\nLa Mafia ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Folle ha vinto!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function jointTownFoolLyncherWins()
    winchannel = audio.play( townwinsound )
    local congratulations1 = congratulate( 0 )
    local congratulations2 = congratulate( 2 )
    local congratulations3 = congratulate( 3 )
    ui.helper.text = "Il Villaggio ha eliminato la Mafia, e sia il Folle che l'Offeso sono ancora vivi.\n\nIl Villaggio ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Folle e l'Offeso hanno vinto con disonore!\nComplimenti a " .. congratulations2 .. " e " .. congratulations3 .. "."
    endingScenario()
  end

  local function jointTownLyncherWins()
    winchannel = audio.play( townwinsound )
    local congratulations1 = congratulate( 0 )
    local congratulations2 = congratulate( 3 )
    ui.helper.text = "Il Villaggio ha eliminato la Mafia, ed il Folle è ancora vivo.\n\nIl Villaggio ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Folle ha vinto con disonore!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function jointTownFoolWins()
    winchannel = audio.play( townwinsound )
    local congratulations1 = congratulate( 0 )
    local congratulations2 = congratulate( 2 )
    ui.helper.text = "Il Villaggio ha eliminato la Mafia, ed il Folle è ancora vivo.\n\nIl Villaggio ha vinto!\nComplimenti a " .. congratulations1 .. ".\n\nIl Folle ha vinto con disonore!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function jointFoolLyncherWins()
    winchannel = audio.play( foolwinsound )
    winchannel2 = timer.performWithDelay( 500, function() audio.play( lyncherwinsound ); end )
    local congratulations1 = congratulate( 2 )
    local congratulations2 = congratulate( 3 )
    ui.helper.text = "Il Folle è stato linciato come un martire e l'Offeso si è vendicato dell'offesa subita.\n\nIl Folle ha vinto!\nComplimenti a " .. congratulations1 .. ".\nL'Offeso ha vinto!\nComplimenti a " .. congratulations2 .. "."
    endingScenario()
  end

  local function lyncherWins()
    winchannel = audio.play( lyncherwinsound )
    local congratulations = congratulate( 3 )
    ui.helper.text = "L'Offeso si è vendicato dell'offesa subita. L'Offeso ha vinto!\n\nComplimenti a " .. congratulations .. "."
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

  local function jointMafiaLynchWins()
    if playerinfo[lastlynched].role == "Folle" and ( lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" ) then
      jointMafiaFoolLyncherWins()
    elseif playerinfo[lastlynched].role == "Folle" then
      jointMafiaFoolWins()
    elseif lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" then
      jointMafiaLyncherWins()
    else
      mafiaWins()
    end
  end

  local function jointTownLynchWins()
    if playerinfo[lastlynched].role == "Folle" and ( lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" ) then
      jointTownFoolLyncherWins()
    elseif playerinfo[lastlynched].role == "Folle" then
      jointTownFoolWins()
    elseif lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" then
      jointTownLyncherWins()
    else
      townWins()
    end
  end

  local function jointLynchWins()
    if playerinfo[lastlynched].role == "Folle" and ( lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" ) then
      jointFoolLyncherWins()
    elseif playerinfo[lastlynched].role == "Folle" then
      foolWins()
    elseif lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" then
      lyncherWins()
    end
  end

  local function alignmentCount()
    local towncount = 0
    local mafiacount = 0
    local foolcount = 0
    local lynchercount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].alive == 1 and playerinfo[i].alignment == 0 then
        towncount = towncount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 1 then
        mafiacount = mafiacount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 2 then
        foolcount = foolcount + 1
      elseif playerinfo[i].alive == 1 and playerinfo[i].alignment == 3 then
        lynchercount = lynchercount + 1
      end
    end
    return towncount, mafiacount, foolcount, lynchercount
  end

  local towncount, mafiacount, foolcount, lynchercount = alignmentCount()

  if trigger == "lynch" then
    if lastlynched ~= -1 and ( playerinfo[lastlynched].role == "Folle" or ( lastlynched == lynchertarget and playerinfo[lyncherid].alive == 1 and playerinfo[lyncherid].role == "Offeso" ) ) then --fool/lyncher wins
      if mafiacount >= towncount+foolcount+lynchercount then
        jointMafiaLynchWins()
      elseif mafiacount == 0 then
        jointTownLynchWins()
      else
        jointLynchWins()
      end
    elseif mafiacount == 0 then
      if foolcount == 0 and lynchercount == 0 then
        townWins()
      else
        jointTownLynchWins()
      end
    elseif mafiacount >= towncount+foolcount+lynchercount then
      mafiaWins()
    else
      nightTime()
    end
  elseif trigger == "kill" then
    if mafiacount == 0 then
      townWins()
    elseif mafiacount >= towncount+foolcount+lynchercount then
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

  local function yakuzaConversionCheck()

    local count = 0

    local function yakuzaConversion()
      count = count + 1
      ui.helper.text = ""
      ui.rolehandbook.text = ""
      if count > settings.setup.players then
        ui.forward:removeEventListener( "tap", yakuzaConversion )
        endNightTime()
      elseif playerinfo[count].alive == 0 then
        yakuzaConversion()
      elseif playerinfo[count].alive == 1 then
        if playerinfo[count].role == "Mafioso" then
          ui.helper.text = playerinfo[count].name .. " apre gli occhi."
          ui.rolehandbook.text = "\nIl Giocatore scopre se è stato convertito al Ruolo di Mafioso.\n\n[Segno positivo, è un Mafioso]\n\nPoi chiude gli occhi."
        elseif count <= settings.setup.players then
          ui.helper.text = playerinfo[count].name .. " apre gli occhi."
          ui.rolehandbook.text = "\nIl Giocatore scopre se è stato convertito al Ruolo di Mafioso.\n\n[Segno negativo, non è un Mafioso]\n\nPoi chiude gli occhi."
        end
      end
    end

    local yakuzacount = 0
    for i=1, settings.setup.players do
      if playerinfo[i].role == "Yakuza" and playerinfo[i].alive == 1 then
        yakuzacount = yakuzacount + 1
      end
    end

    if yakuzacount > 0 then
      ui.helper.text = "Tenete ancora chiusi gli occhi."
      ui.rolehandbook.text = "A turno, farò aprire gli occhi a ciascun Giocatore. Se Giocatore riceverà un segno positivo, significa che ha perso il proprio Ruolo precedente ed è stato convertito al Ruolo di Mafioso, sotto ogni aspetto. Tutti gli altri invece riceveranno un segno negativo."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", yakuzaConversion )
    else
      endNightTime()
    end

  end

  local function lyncherAngerCheck()

    local count = 0

    local lynchercount = 0
    for i=1, settings.setup.players do
      if playerinfo[i].role == "Offeso" and playerinfo[i].alive == 1 then
        lynchercount = lynchercount + 1
      end
    end

    if lynchercount > 0 then

      local function clearLyncherAnger()
        ui.helper.text = ""
        ui.rolehandbook.text = ""
        ui.forward:removeEventListener( "tap", clearLyncherAnger )
        yakuzaConversionCheck()
      end

      ui.helper.text = "L'Offeso apre gli occhi."
      ui.rolehandbook.text = "[" .. playerinfo[lyncherid].name .. " ha il ruolo di Offeso]\n\nL'Offeso vede il Giocatore che l'ha offeso dormire sonni tranquilli.\n\n[Indicare " .. playerinfo[lynchertarget].name .. "]\n\nFuribondo, giura che presto lo farà linciare. Poi chiude gli occhi."

      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearLyncherAnger )

    else

      yakuzaConversionCheck()

    end

  end

  local function evaluateNightVisits()

    ui.forward:removeEventListener( "tap", evaluateNightVisits )

    local mafiaid

    for i=1, settings.setup.players do
      if playerinfo[i].alignment == 1 and playerinfo[i].alive == 1 then
        mafiaid = i
      end
    end

    lastdeaths = {}

    if lastmafiakill ~= -1 then --mafiakilled
      if ( lastdocsave == -1 or lastdocsave ~= lastmafiakill ) and playerinfo[lastmafiakill].role ~= "Nonnina" then --nosave or wrongsave
        table.insert( lastdeaths, lastmafiakill ) --kill happens
      end
    end

    if lastyak ~= -1 then --yakked
      table.insert( lastdeaths, yakid ) --yakuzadies
      if lastshrunk == -1 or lastshrunk ~= lastyak then
        playerinfo[lastyak].role = "Mafioso"
        playerinfo[lastyak].alignment = 1
      end
    end

    if lastmafiakill ~= -1 and playerinfo[lastmafiakill].role == "Nonnina" and yakid ~= mafiaid then --mafia visits granny
      if lastdocsave == -1 or lastdocsave ~= mafiaid then --nosave or wrongsave
        table.insert( lastdeaths, mafiaid ) --grannyrevenge
      end
    end

    if lastdocsave ~= -1 and playerinfo[lastdocsave].role == "Nonnina" and docid ~= lastmafiakill then --doc visits granny
      table.insert( lastdeaths, docid ) --grannyrevenge
    end

    if lastshrunk ~= -1 and playerinfo[lastshrunk].role == "Nonnina" and shrinkid ~= lastmafiakill then --shrink visits granny
      if lastdocsave == -1 or lastdocsave ~= shrinkid then --nosave or wrongsave
        table.insert( lastdeaths, shrinkid ) --grannyrevenge
      end
    end

    lyncherAngerCheck()

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

  local function visitShrink()

      local function shrinkShrunk()

        ui.roleactionicon:removeSelf()
        ui.roleactionicon = nil

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

          lastshrunk = event.target.id

          if lastshrunk ~= -1 then --save
            ui.helper.text = "Lo Strizzacervelli ha deciso chi psicanalizzare.\n\n[" .. playerinfo[lastshrunk].name .. "]"
          else --nosave
            ui.helper.text = "Lo Strizzacervelli ha deciso chi psicanalizzare.\n\n[Nessuno]"
          end

          ui.forward.alpha = 1
          ui.forwardtext.alpha = 1

          local function clearShrunkReminder()
            ui.forward:removeEventListener( "tap", clearShrunkReminder )
            ui.forward.alpha = 0
            ui.forwardtext.alpha = 0
            visitDoctor()
          end

          ui.forward:addEventListener( "tap", clearShrunkReminder )

        end

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

    local shrinkcount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Strizzacervelli" and playerinfo[i].alive == 1 then
        shrinkcount = shrinkcount + 1
      end
    end

    if shrinkcount > 0 then
      ui.helper.text = "Lo Strizzacervelli apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Strizzacervelli" )

      activateNightStrat( "Strizzacervelli" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Strizzacervelli.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", shrinkShrunk )
    else

      local function clearDeadShrink()
        ui.forward:removeEventListener( "tap", clearDeadShrink )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        visitDoctor()
      end

      lastshrunk = -1
      ui.helper.text = "Lo Strizzacervelli è morto e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearDeadShrink )

    end

  end

  local function visitYakuza()

    local function yakuzaYak()

      ui.roleactionicon:removeSelf()
      ui.roleactionicon = nil

      local yakicons = {}
      local yaknames = {}

      local function clearYak( event )

        for i=1, table.getn( yakicons ) do
          yakicons[i]:removeSelf()
          yakicons[i] = nil
        end
        for i=1, table.getn( yaknames ) do
          yaknames[i]:removeSelf()
          yaknames[i] = nil
        end

        lastyak = event.target.id

        ui.helper.text = "Lo Yakuza ha deciso chi introdurre alla Mafia, dando in cambio la propria vita.\n\n[" .. playerinfo[lastyak].name .. "]\n\nLo Yakuza chiude gli occhi."

        ui.forward.alpha = 1
        ui.forwardtext.alpha = 1

        local function clearYakReminder()
          ui.forward:removeEventListener( "tap", clearYakReminder )
          ui.forward.alpha = 0
          ui.forwardtext.alpha = 0
          visitShrink()
        end

        ui.forward:addEventListener( "tap", clearYakReminder )

      end

      ui.strat:removeEventListener( "tap", showNightStrat )
      ui.strat.alpha = 0
      ui.strattext.alpha = 0

      ui.helper.text = "POSSIBILI INIZIATI:"
      ui.rolehandbook.text = ""
      local j = 1
      for i=1, settings.setup.players do
        if playerinfo[i].alive == 1 and playerinfo[i].role ~= "Yakuza" then
          yakicons[j] = display.newImageRect( uiGroup, "images/interface/yak.png", display.contentWidth * 0.1, display.contentWidth * 0.1 )
          yakicons[j].x, yakicons[j].y = display.contentWidth * 0.74, display.contentHeight * 0.34 + (j-1) * display.contentHeight * 0.09
          yakicons[j].id = i
          yakicons[j]:addEventListener( "tap", clearYak )
          yaknames[j] = display.newText( uiGroup, settings.playernames[i], display.contentWidth * 0.1, yakicons[j].y, "GosmickSans.ttf", 18 )
          yaknames[j].anchorX = 0
          j = j + 1
        end
      end

    end

    local yakuzacount = 0
    for i=1, table.getn( playerinfo ) do
      if playerinfo[i].role == "Yakuza" and playerinfo[i].alive == 1 then
        yakuzacount = yakuzacount + 1
      end
    end

    if yakuzacount > 0 then
      ui.helper.text = "Lo Yakuza apre gli occhi."
      ui.rolehandbook.text = roleslib.getVisit( settings.setup.title, "Yakuza" )

      activateNightStrat( "Yakuza" )

      ui.roleactionicon = display.newImageRect( uiGroup, "images/roles/Yakuza.png", display.contentWidth * 0.4, display.contentWidth * 0.4 )
      ui.roleactionicon.x, ui.roleactionicon.y = display.contentWidth * 0.5, display.contentHeight * 0.68
      ui.roleactionicon:addEventListener( "tap", yakuzaYak )
    else

      local function clearDeadYakuza()
        ui.forward:removeEventListener( "tap", clearDeadYakuza )
        ui.forward.alpha = 0
        ui.forwardtext.alpha = 0
        visitShrink()
      end

      lastyak = -1
      ui.helper.text = "Lo Yakuza è stato eliminato e non può fare più nulla ormai."
      ui.forward.alpha = 1
      ui.forwardtext.alpha = 1
      ui.forward:addEventListener( "tap", clearDeadYakuza )

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
          visitYakuza()
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
        visitYakuza()
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

    local function backVisitYakuza()
      ui.strat:removeEventListener( "tap", backVisitYakuza )
      visitYakuza()
    end

    local function backVisitDoctor()
      ui.strat:removeEventListener( "tap", backVisitDoctor )
      visitDoctor()
    end

    local function backVisitShrink()
      ui.strat:removeEventListener( "tap", backVisitShrink )
      visitShrink()
    end

    ui.roleactionicon:removeSelf()
    ui.roleactionicon = nil
    ui.helper.text = "STRATEGIA GENERALE (NOTTE)"
    ui.rolehandbook.text = roleslib.getNightStrat( settings.setup.title, ui.strat.role, nightcount-1 )
    ui.strat:removeEventListener( "tap", showNightStrat )
    ui.strattext.text = "Indietro"
    if ui.strat.role == "Mafia" then
      ui.strat:addEventListener( "tap", backVisitMafia )
    elseif ui.strat.role == "Yakuza" then
      ui.strat:addEventListener( "tap", backVisitYakuza )
    elseif ui.strat.role == "Dottore" then
      ui.strat:addEventListener( "tap", backVisitDoctor )
    elseif ui.strat.role == "Strizzacervelli" then
      ui.strat:addEventListener( "tap", backVisitShrink )
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

  local lyncherpossibletargets = {}

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

    if settings.playerroles[i] == "Yakuza" then
      playerinfo[i].alignment = 1
      yakid = i
    elseif settings.playerroles[i] == "Dottore" then
      playerinfo[i].alignment = 0
      docid = i
      table.insert( lyncherpossibletargets, i )
    elseif settings.playerroles[i] == "Strizzacervelli" then
      playerinfo[i].alignment = 0
      shrinkid = i
      table.insert( lyncherpossibletargets, i )
    elseif settings.playerroles[i] == "Nonnina" then
      playerinfo[i].alignment = 0
      table.insert( lyncherpossibletargets, i )
    elseif settings.playerroles[i] == "Folle" then
      playerinfo[i].alignment = 2
      table.insert( lyncherpossibletargets, i )
    elseif settings.playerroles[i] == "Offeso" then
      playerinfo[i].alignment = 3
      lyncherid = i
    end

    print( "Giocatore " .. i .. ": " .. settings.playerroles[i] )

  end

  lynchertarget = lyncherpossibletargets[ math.random( 1, table.getn( lyncherpossibletargets ) ) ]

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
