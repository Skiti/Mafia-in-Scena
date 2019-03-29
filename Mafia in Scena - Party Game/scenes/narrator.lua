local composer = require( "composer" )
local loadsave = require( "loadsave" )

local scene = composer.newScene()

local uiGroup = display.newGroup()

local settings = loadsave.loadTable( "settings.json" )

settings.setup = {}

local ui = {
  background,
  frontbox, title, roles = {}, playericon,
  description,
  start, starttext, backwelcome, backwelcometext, left, lefttext, right, righttext
}

local scenarios = {
  {
    id = 1,
    title = "Mafia Classica",
    players = 7,
    roles = {
      "Paesano", "Paesano", "Paesano",
      "Mafioso", "Mafioso",
      "Dottore",
      "Detective"
    },
    factions = {
      "Villaggio",
      "Mafia"
    },
    descr = "Ruoli: Paesano, Mafioso, Dottore, Detective.\n\nDescrizione: Uno scenario lineare ed equilibrato. Appellatevi al vostro istinto ed al vostro carisma. Ne avrete bisogno.",
  },

  {
    id = 2,
    title = "Pistole & Prostitute",
    players = 7,
    roles = {
      "Paesano", "Paesano", "Paesano",
      "Mafioso",
      "Squillo",
      "Armaiolo",
      "Detective"
    },
    factions = {
      "Villaggio",
      "Mafia"
    },
    descr = "Ruoli: Paesano, Mafioso, Squillo, Armaiolo, Detective.\n\nDescrizione: Uno scenario che inizia col botto e spinge a sospettare di chiunque. Chi sarà il prossimo ad impugnare la pistola?",
  },

  {
    id = 3,
    title = "Amore a Prima Vista",
    players = 7,
    roles = {
      "Paesano", "Paesano", "Paesano",
      "Mafioso",
      "Squillo",
      "Armaiolo",
      "Sposa"
    },
    factions = {
      "Villaggio",
      "Mafia"
    },
    descr = "Ruoli: Paesano, Mafioso, Squillo, Armaiolo, Sposa.\n\nDescrizione: Uno scenario simile a Pistole & Prostitute, più semplice per il Villaggio. Nessuna garanzia di vivere felici e contenti alla fine.",
  },

  {
    id = 4,
    title = "Il Villaggio Selvaggio",
    players = 7,
    roles = {
      "Mafioso",
      "Dottore",
      "Antiproiettile", "Antiproiettile", "Antiproiettile", "Antiproiettile",
      "Killer"
    },
    factions = {
      "Villaggio",
      "Mafia",
      "Killer"
    },
    descr = "Ruoli: Mafioso, Dottore, Antiproiettile, Killer.\n\nDescrizione: Uno scenario a tre Fazioni molto bilanciato. I criminali suonano sempre due volte, alle case degli Antiproiettili.",
  },

  {
    id = 5,
    title = "Giustizia o Follia?",
    players = 8,
    roles = {
      "Paesano", "Paesano",
      "Mafioso",
      "Squillo",
      "Dottore",
      "Vigilante",
      "Detective",
      "Folle"
    },
    factions = {
      "Villaggio",
      "Mafia",
      "Folle"
    },
    descr = "Ruoli: Paesano, Mafioso, Squillo, Dottore, Vigilante, Detective, Folle.\n\nDescrizione: Uno scenario imprevedibile che lascia ampio margine per l'improvvisazione. Riuscirà il Folle a farsi linciare?",
  },

  {
    id = 6,
    title = "Io adoro i Linciaggi!",
    players = 8,
    roles = {
      "Paesano", "Paesano",
      "Mafioso", "Mafioso",
      "Dottore",
      "Detective",
      "Folle",
      "Offeso"
    },
    factions = {
      "Villaggio",
      "Mafia",
      "Folle",
      "Offeso"
    },
    descr = "Ruoli: Paesano, Mafioso, Dottore, Detective, Folle, Offeso.\n\nDescrizione: Uno Scenario dove regna il caos ed ogni Linciaggio potrebbe essere l'ultimo. Saranno guai per chi ha provocato l'Offeso.",
  },

  {
    id = 7,
    title = "Lode al Culto",
    players = 6,
    roles = {
      "Dottore",
      "Strizzacervelli", "Strizzacervelli", "Strizzacervelli",
      "Capocultista",
      "Killer"
    },
    factions = {
      "Villaggio",
      "Culto",
      "Killer"
    },
    descr = "Ruoli: Dottore, Strizzacervelli, Capocultista, Killer.\n\nDescrizione: Uno scenario che promuove complotti e cospirazioni. Il Culto darà un nuovo senso alla tua vita. Anche se sei un Killer.",
  },

  {
    id = 8,
    title = "Dottori, Pazienti e Pazzi",
    players = 6,
    roles = {
      "Yakuza",
      "Dottore",
      "Strizzacervelli",
      "Nonnina",
      "Folle",
      "Offeso"
    },
    factions = {
      "Villaggio",
      "Mafia",
      "Folle",
      "Offeso"
    },
    descr = "Ruoli: Dottore, Strizzacervelli, Nonnina, Folle, Offeso, Yakuza.\n\nDescrizione: Uno scenario rapido e denso d'azione. Non disturbate il sonno della Nonnina, o ve ne pentirete amaramente.",
  },

}

settings.setup = scenarios[ composer.getVariable( "scenario" ) ]

local function clearAll()

  ui.background:removeSelf()
  ui.background = nil

  ui.title:removeSelf()
  ui.title = nil

  for i=1, settings.setup.players do
    ui.roles[i]:removeSelf()
    ui.roles[i] = nil
  end

  ui.playericon:removeSelf()
  ui.playericon = nil

  ui.frontbox:removeSelf()
  ui.frontbox = nil

  ui.description:removeSelf()
  ui.description = nil

  ui.start:removeSelf()
  ui.start = nil
  ui.starttext:removeSelf()
  ui.starttext = nil

  ui.backwelcome:removeSelf()
  ui.backwelcome = nil
  ui.backwelcometext:removeSelf()
  ui.backwelcometext = nil

  ui.left:removeSelf()
  ui.left = nil
  ui.lefttext:removeSelf()
  ui.lefttext = nil

  ui.right:removeSelf()
  ui.right = nil
  ui.righttext:removeSelf()
  ui.righttext = nil

end

local function gotoPregame()
  clearAll()
  loadsave.saveTable( settings, "settings.json" )
  composer.removeScene( "scenes.pregame" )
  composer.gotoScene( "scenes.pregame" )
end

local function gotoWelcome()
  clearAll()
  settings.setup = {}
  loadsave.saveTable( settings, "settings.json" )
  composer.removeScene( "scenes.welcome" )
  composer.gotoScene( "scenes.welcome" )
end

local function changeScenario()
  ui.title.text = settings.setup.title
  for i=1, table.getn( ui.roles ) do
    ui.roles[i]:removeSelf()
    ui.roles[i] = nil
  end
  for i=settings.setup.players, 1, -1 do
    ui.roles[i] = display.newImageRect( uiGroup, "images/roles/" .. settings.setup.roles[i] .. ".png", display.contentWidth * 0.12, display.contentWidth * 0.12 )
    ui.roles[i].x, ui.roles[i].y = display.contentWidth * 0.06 + (i-1)*25, display.contentWidth * 0.21
    ui.roles[i].anchorX = 0
  end
  ui.playericon :removeSelf()
  ui.playericon = display.newImageRect( uiGroup, "images/numbers/" .. settings.setup.players .. ".png", display.contentWidth * 0.13, display.contentWidth * 0.13 )
  ui.playericon.x, ui.playericon.y = display.contentWidth * 0.88, display.contentWidth * 0.21
  ui.description.text = settings.setup.descr
end

local function gotoLeft()
  if settings.setup.id == 1 then
    settings.setup = scenarios[ table.getn( scenarios ) ]
  else
    settings.setup = scenarios[ settings.setup.id-1 ]
  end
  changeScenario()
end

local function gotoRight()
  if settings.setup.id == scenarios[ table.getn( scenarios ) ].id then
    settings.setup = scenarios[ 1 ]
  else
    settings.setup = scenarios[ settings.setup.id+1 ]
  end
  changeScenario()
end

-- create()
function scene:create( event )

  --background

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

  -- setup description

  local description = settings.setup.descr

  local options = {
    text = description,
    x = display.contentCenterX,
    y = display.contentHeight * 0.54,
    width = display.contentWidth * 0.9,
    height = display.contentHeight * 0.6,
    font = "GosmickSans.ttf",
    fontSize = 20,
    align = "left"
  }

  ui.description = display.newText( options )
  ui.description:setFillColor( 1, 1, 1, 1 )

  -- start scenario

  ui.start = display.newRect( uiGroup, display.contentWidth * 0.5, display.contentHeight * 0.73, display.contentWidth * 0.56, display.contentHeight * 0.15 )
  ui.start:setFillColor( 0, 0, 0, 1 )
  ui.start.strokeWidth = 2
  ui.start:setStrokeColor( 1, 1, 1, 1 )
  ui.start:addEventListener( "tap", gotoPregame )

  ui.starttext = display.newText( uiGroup, "Scelgo questo", ui.start.x, ui.start.y, "GosmickSans.ttf", 26 )
  ui.starttext:setFillColor( 1, 1, 1, 1 )

  -- back to welcome

  ui.backwelcome = display.newRect( uiGroup, display.contentWidth * 0.5, display.contentHeight * 0.9, display.contentWidth * 0.2, display.contentHeight * 0.08 )
  ui.backwelcome:setFillColor( 0, 0, 0, 1 )
  ui.backwelcome.strokeWidth = 2
  ui.backwelcome:setStrokeColor( 1, 1, 1, 1 )
  ui.backwelcome:addEventListener( "tap", gotoWelcome )

  ui.backwelcometext = display.newText( uiGroup, "Menù", display.contentWidth * 0.5, ui.backwelcome.y, "GosmickSans.ttf", 18 )
  ui.backwelcometext:setFillColor( 1, 1, 1, 1 )

  -- setup navigation

  ui.left = display.newRect( uiGroup, display.contentWidth * 0.2, display.contentHeight * 0.9, display.contentWidth * 0.26, display.contentHeight * 0.1 )
  ui.left:setFillColor( 0, 0, 0, 1 )
  ui.left.strokeWidth = 2
  ui.left:setStrokeColor( 1, 1, 1, 1 )
  ui.left:addEventListener( "tap", gotoLeft )

  ui.lefttext = display.newText( uiGroup, "<<<", ui.left.x, ui.left.y, "GosmickSans.ttf", 40 )
  ui.lefttext:setFillColor( 1, 1, 1, 1 )

  ui.right = display.newRect( uiGroup, display.contentWidth * 0.8, display.contentHeight * 0.9, display.contentWidth * 0.26, display.contentHeight * 0.1 )
  ui.right:setFillColor( 0, 0, 0, 1 )
  ui.right.strokeWidth = 2
  ui.right:setStrokeColor( 1, 1, 1, 1 )
  ui.right:addEventListener( "tap", gotoRight )

  ui.righttext = display.newText( uiGroup, ">>>", ui.right.x, ui.right.y, "GosmickSans.ttf", 40 )
  ui.righttext:setFillColor( 1, 1, 1, 1 )

end

-- scene event listener
scene:addEventListener( "create", scene )

return scene
