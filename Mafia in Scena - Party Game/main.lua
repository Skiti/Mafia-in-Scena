local composer = require( "composer" )
local loadsave = require( "loadsave" )

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )
native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )

-- random seed
math.randomseed( os.time() )

-- called few times to prevent a bug where first calls are not random
math.random( 1, 3 )
math.random( 1, 3 )

--first time loadsave
local settings = loadsave.loadTable( "settings.json" )

settings = {}

settings.playernames = {}
settings.playernames[1] = "Banana Bellicosa"
settings.playernames[2] = "Cocomero Canoro"
settings.playernames[3] = "Durian Depravato"
settings.playernames[4] = "Limone Lascivo"
settings.playernames[5] = "Mango Maniacale"
settings.playernames[6] = "Pesca Prepotente"
settings.playernames[7] = "Uva Urlante"
settings.playernames[8] = "Fragola Frivola"
settings.playernames[9] = "Arancia Ambigua"
settings.playernames[10] = "Ribes Ribelle" --narrator


settings.playerdeaths = {}
for i=1, 9 do
  settings.playerdeaths[i] = "audio/deaths/death" .. i .. ".wav"
end

settings.playerroles = {}

loadsave.saveTable( settings, "settings.json" )

-- load title screen
composer.removeScene( "scenes.welcome" )
composer.gotoScene( "scenes.welcome" )
