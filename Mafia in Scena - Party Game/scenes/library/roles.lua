local M = {}

-- factions overview
local overview_factions = {

  "Il Villaggio è una comunità pacifica e serena, un vero angolo di Paradiso. Gli spensierati Paesani adorano il quieto vivere, e non esitano a condannare coloro che minacciano l'ordine pubblico ad un brutale Linciaggio. Ne organizzano uno ogni Giorno. Ma non ci traggono alcun divertimento perverso. Assolutamente no.\nIl Villaggio vince se tutti gli appartenenti alla Mafia vengono eliminati. Per poter vincere, il Villaggio deve impedire alle Fazioni avversarie di vincere a loro volta. A questo scopo, il Villaggio si affida spesso e volentieri al Linciaggio.",

  "La Mafia è una spietata organizzazione criminale che vuole assumere il controllo del Villaggio. Predilige l'omicidio, ma non disdegna inganni e tradimenti.\nLa Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Ogni Notte, la Mafia si ritrova in un Raduno Mafioso per visitare ed uccidere di comune accordo un Giocatore (o Nessuno). I Giocatori appartenenti alla Mafia, dunque, conoscono identità e Ruoli dei propri compagni. La Mafia, durante il Giorno, cerca di ingannare gli altri Giocatori e di evitare atteggiamenti sospetti.",

  "Il Killer è un dannato maniaco sadico che si sente vivo solo nell'atto di uccidere. Forse è colpa di quella suadente voce interiore che lo incita all'omicidio. O forse è stato bullizzato da piccolo.\nIl Killer vince se è vivo quando restano solo due o meno Giocatori (Killer incluso). Ogni Notte, il Killer è sempre obbligato a visitare ed uccidere un Giocatore.",

  "Il Folle, al contrario delle apparenze, ha una mente lucida e calcolatrice. Ha scoperto il significato della vita: è stato un sasso blu a rivelarglielo. Nessuno crede mai alle sue parole di verità. La sua ultima speranza è quella di farsi linciare, così da essere ricordato come un martire. Così finalmente nessuno lo considererà più un Folle. Un piano chiaramente frutto di una mente razionale.\nIl Folle vince se viene linciato (non vince se viene ucciso in altri modi!). Il Folle, inoltre, vince con disonore se è ancora vivo quando il Villaggio vince.",

  "Il Culto è una comunità di fanatici che sono stati completamente soggiogati dalle parole Capocultista, il quale sogna di conquistare il mondo. I Cultisti adorano due cose in particolare: lodare il Culto e sacrificare la propria vita per esso.\nIl Culto vince se rappresenta la maggioranza dei Giocatori vivi. Il Culto nasce sempre dal Capocultista. Ogni Notte, il Capocultista può visitare un Giocatore a sua scelta (o Nessuno) e convertire il suo Ruolo in un Cultista, il quale non ha nessuna informazione sul Capocultista o gli altri Cultisti. Quando il Capocultista muore, i Cultisti si suicidano in massa.",

  "L'Offeso è una personcina incredibilmente frivola e lunatica, che adora far soffrire gli altri. Un Giocatore si è permesso di offenderlo ad inizio partita e l'Offeso non può assolutamente perdonarlo.\nL'Offeso vince se è vivo quando il Giocatore che l'ha offeso viene linciato (non vince se viene ucciso in altri modi!). L'Offeso, inoltre, vince con disonore se è ancora vivo quando il Villaggio vince. Il Giocatore che l'ha offeso è scelto casualmente tra gli appartenenti al Villaggio.",

}

-- role overview, classic
local overview_classic = {

  "Il Paesano fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Paesano non esegue alcuna Visita Notturna e non possiede caratteristiche speciali. Per questo motivo, spesso viene sottovalutato come Ruolo. Il Paesano si dedica principalmente a scovare i comportamenti sospetti degli altri Giocatori, senza timore di esporsi o crearsi nemici. Quando viene Confermato Innocente, il Paesano finisce per guidare il Villaggio. Nei Finali-a-Tre, spesso sono i Paesani a fare la differenza.",

  "Il Mafioso fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Il Mafioso partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, il Mafioso non possiede caratteristiche speciali.",

  "Il Detective fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Detective esegue una Visita Notturna che gli fornisce un Report sul Giocatore scelto (Innocente = Villaggio, Colpevole = Mafia). Per questo motivo, spesso il Detective dovrà dichiararsi pubblicamente e comunicare i Report ottenuti.",

  "Il Dottore fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Dottore esegue una Visita Notturna che impedisce la morte del Giocatore scelto, durante quella Notte. Non può salvare sè stesso ma può salvare lo stesso Giocatore più volte consecutivamente.",

}

-- role overview, gnh
local overview_gnh = {

  "Il Paesano fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Paesano non esegue alcuna Visita Notturna e non possiede caratteristiche speciali. Per questo motivo, spesso viene sottovalutato come Ruolo. Il Paesano si dedica principalmente a scovare i comportamenti sospetti degli altri Giocatori, senza timore di esporsi o crearsi nemici. Quando viene Confermato Innocente, il Paesano finisce per guidare il Villaggio. Nei Finali a Tre, sono i Paesani a fare la differenza.",

  "Il Mafioso fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Il Mafioso partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, il Mafioso non possiede caratteristiche speciali. Per questo motivo, spesso si espone a grandi rischi, allo scopo di supportare gli altri appartenenti alla Mafia.",

  "La Squillo fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. La Squillo partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, la Squillo esegue un'altra Visita Notturna che seduce il Giocatore scelto, bloccando la sua Visita Notturna e eventuali caratteristiche speciali durante quella Notte.",

  "L'Armaiolo fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. L'Armaiolo esegue una Visita Notturna che consegna una Pistola al Giocatore scelto. La Pistola permette al proprietario di sparare, in qualsiasi momento del Giorno, ad un Giocatore a sua scelta, uccidendolo.",

  "Il Detective fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Detective esegue una Visita Notturna che gli fornisce un Report sul Giocatore scelto (Innocente = Villaggio, Colpevole = Mafia). Per questo motivo, spesso il Detective dovrà dichiararsi pubblicamente e comunicare i Report ottenuti.",

}

-- role overview, btb
local overview_btb = {

  "Il Paesano fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Paesano non esegue alcuna Visita Notturna e non possiede caratteristiche speciali. Per questo motivo, spesso viene sottovalutato come Ruolo. Il Paesano si dedica principalmente a scovare i comportamenti sospetti degli altri Giocatori, senza timore di esporsi o crearsi nemici. Quando viene Confermato Innocente, il Paesano finisce per guidare il Villaggio. Nei Finali a Tre, sono i Paesani a fare la differenza.",

  "Il Mafioso fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Il Mafioso partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, il Mafioso non possiede caratteristiche speciali. Per questo motivo, spesso si espone a grandi rischi, allo scopo di supportare gli altri appartenenti alla Mafia.",

  "La Squillo fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. La Squillo partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, la Squillo esegue un'altra Visita Notturna che seduce il Giocatore scelto, bloccando la sua Visita Notturna e eventuali caratteristiche speciali durante quella Notte.",

  "L'Armaiolo fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. L'Armaiolo esegue una Visita Notturna che consegna una Pistola al Giocatore scelto. La Pistola permette al proprietario di sparare, in qualsiasi momento del Giorno, ad un Giocatore a sua scelta, uccidendolo.",

  "La Sposa fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. La Sposa non esegue alcuna Visita Notturna. Il primo Giorno, l'identità della Sposa viene rivelata. Una volta per partita, durante il Giorno, può convolare a nozze con un Giocatore a sua scelta, di cui verrà rivelato pubblicamente il Ruolo.",

}

-- role overview, shrink
local overview_shrink = {

  "Il Dottore fa parte del Villaggio, in opposizione diretta al Killer ed al Culto. Il Villaggio vince linciando eradicando il Culto ed eliminando il Killer. Il Dottore esegue una Visita Notturna che impedisce la morte del Giocatore scelto. Non può salvare sè stesso ma può salvare lo stesso Giocatore più volte consecutivamente.",

  "Lo Strizzacervelli fa parte del Villaggio, in opposizione diretta al Killer ed al Culto. Il Villaggio vince eradicando il Culto ed eliminando il Killer. Lo Strizzacervelli esegue una Visita Notturna che psicanalizza il Giocatore scelto, impedendogli di essere convertito quella Notte. Se visita il Killer, ne cambia completamente il Ruolo in Paesano. Lo Strizzacervelli può psicanalizzare sè stesso. Lo Strizzacervelli può psicanalizzare lo stesso Giocatore più volte consecutivamente.",

  "Il Capocultista agisce per conto del Culto, con la possibilità di allearsi con il Killer. Il Culto vince se rappresenta la maggioranza dei Giocatori vivi. Il Capocultista esegue una Visita Notturna che converte il Giocatore scelto in un Cultista, appartenente al Culto. Solo una Visita Notturna dello Strizzacervelli a quel Giocatore può impedirne la conversione. Se il Capocultista muore, tutti i Cultisti muoiono.",

  "Il Killer agisce per proprio conto. Il Killer vince se è vivo quando restano solo due o meno Giocatori (Killer incluso). Il Killer esegue una Visita Notturna che uccide il Giocatore scelto; a differenza della Mafia, non può scegliere di non visitare nessuno, ma è sempre obbligato ad uccidere. Il Killer è segretamente pentito per i suoi crimini. Infatti, quando uno Strizzacervelli esegue una Visita Notturna sul Killer, quest'ultimo cambia Ruolo in Paesano, perdendo ogni istinto omicida. Il Paesano non esegue alcuna Visita Notturna e non possiede caratteristiche speciali. Il Paesano fa parte del Villaggio e vince eradicando il Culto.",

}

-- role overview, kvsm
local overview_kvsm = {

  "Il Mafioso fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Il Mafioso partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, il Mafioso non possiede caratteristiche speciali.",

  "Il Dottore fa parte del Villaggio, in opposizione diretta alla Mafia ed al Killer. Il Villaggio vince linciando la Mafia ed il Killer. Il Dottore esegue una Visita Notturna che impedisce la morte del Giocatore scelto, durante quella Notte. Non può salvare sè stesso ma può salvare lo stesso Giocatore più volte consecutivamente.",

  "L'Antiproiettile fa parte del Villaggio, in opposizione diretta alla Mafia ed al Killer. Il Villaggio vince linciando la Mafia ed il Killer. L'Antiproiettile non esegue alcuna Visita Notturna. L'Antiproiettile può sopravvivere ad un singolo colpo mortale, una volta per partita. Non sopravvive al Linciaggio. Quando sopravvive ad un colpo mortale, solo l'Antiproiettile viene avvertito.",

  "Il Killer agisce per proprio conto, con la possibilità di allearsi con la Mafia. Il Killer vince se è vivo quando restano solo due o meno Giocatori (Killer incluso). Il Killer esegue una Visita Notturna che uccide il Giocatore scelto; a differenza della Mafia, non può scegliere di non visitare nessuno, ma è sempre obbligato ad uccidere.",

}

-- role overview, ft3
local overview_ft3 = {

  "Il Paesano fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Paesano non esegue alcuna Visita Notturna e non possiede caratteristiche speciali. Per questo motivo, spesso viene sottovalutato come Ruolo. Il Paesano si dedica principalmente a scovare i comportamenti sospetti degli altri Giocatori, senza timore di esporsi o crearsi nemici. Quando viene Confermato Innocente, il Paesano finisce per guidare il Villaggio. Nei Finali a Tre, sono i Paesani a fare la differenza.",

  "Il Mafioso fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Il Mafioso partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, il Mafioso non possiede caratteristiche speciali. Per questo motivo, spesso si espone a grandi rischi, allo scopo di supportare gli altri appartenenti alla Mafia.",

  "La Squillo fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. La Squillo partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, la Squillo esegue un'altra Visita Notturna che seduce il Giocatore scelto, bloccando la sua Visita Notturna e eventuali caratteristiche speciali durante quella Notte.",

  "Il Dottore fa parte del Villaggio, in opposizione diretta alla Mafia ed al Killer. Il Villaggio vince linciando la Mafia ed il Killer. Il Dottore esegue una Visita Notturna che impedisce la morte del Giocatore scelto, durante quella Notte. Non può salvare sè stesso ma può salvare lo stesso Giocatore più volte consecutivamente.",

  "Il Vigilante fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Vigilante esegue una Visita Notturna che uccide il Giocatore scelto. Se il Vigilante viene ucciso, la sua Visita Notturna fallisce. Se visita lo stesso Giocatore scelto come vittima dal Raduno Mafioso, il Vigilante muore.",

  "Il Detective fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Detective esegue una Visita Notturna che gli fornisce un Report sul Giocatore scelto (Innocente = Villaggio+Folle, Colpevole = Mafia). Per questo motivo, spesso il Detective dovrà dichiararsi pubblicamente e comunicare i Report ottenuti.",

  "Il Folle agisce per proprio conto. Il Folle vince se viene linciato (non vince se viene ucciso in altri modi!). Il Folle vince con disonore se è ancora vivo nel momento in cui il Villaggio vince. Il Folle non esegue alcuna Visita Notturna. Nel cercare di farsi linciare, il Folle può effettivamente dichiararsi qualsiasi Ruolo. Il Folle deve guardarsi le spalle dal Vigilante ma può contare sull'aiuto della Mafia, che vorrebbe allearsi volentieri con lui.",

}

-- role overview, gallows
local overview_gallows = {

  "Il Paesano fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Paesano non esegue alcuna Visita Notturna e non possiede caratteristiche speciali. Per questo motivo, spesso viene sottovalutato come Ruolo. Il Paesano si dedica principalmente a scovare i comportamenti sospetti degli altri Giocatori, senza timore di esporsi o crearsi nemici. Quando viene Confermato Innocente, il Paesano finisce per guidare il Villaggio. Nei Finali-a-Tre, spesso sono i Paesani a fare la differenza.",

  "Il Mafioso fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Il Mafioso partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, il Mafioso non possiede caratteristiche speciali.",

  "Il Detective fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Detective esegue una Visita Notturna che gli fornisce un Report sul Giocatore scelto (Innocente = Villaggio+Folle+Offeso, Colpevole = Mafia). Per questo motivo, spesso il Detective dovrà dichiararsi pubblicamente e comunicare i Report ottenuti.",

  "Il Dottore fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Dottore esegue una Visita Notturna che impedisce la morte del Giocatore scelto, durante quella Notte. Non può salvare sè stesso ma può salvare lo stesso Giocatore più volte consecutivamente.",

  "Il Folle agisce per proprio conto. Il Folle vince se viene linciato (non vince se viene ucciso in altri modi!). Il Folle vince con disonore se è ancora vivo nel momento in cui il Villaggio vince. Il Folle non esegue alcuna Visita Notturna. Nel cercare di farsi linciare, il Folle preferisce dichiararsi Detective ed agire in modo sospetto, ma senza esagerare. Il Folle adora allearsi con la Mafia, ed in casi fortunati può allearsi anche con l'Offeso.",

  "L'Offeso agisce per proprio conto. Un Giocatore l'ha offeso ad inizio partita. L'Offeso vince se è vivo quando il Giocatore che l'ha offeso viene linciato (non vince se viene ucciso in altri modi!). L'Offeso, inoltre, vince con disonore se è ancora vivo quando il Villaggio vince. Il Giocatore che l'ha offeso è scelto casualmente tra gli appartenenti al Villaggio ed il Folle. L'Offeso non esegue alcuna Visita Notturna. L'Offeso può allearsi con chiunque, in base alla situazione.",

}

-- role overview, everyman
local overview_everyman = {

  "Lo Yakuza fa parte della Mafia, in opposizione al Villaggio. La Mafia vince se rappresenta la maggioranza dei Giocatori vivi. Lo Yakuza partecipa ai Raduni Mafiosi ed esegue una Visita Notturna al Giocatore scelto come vittima. Oltre a questo, lo Yakuza deve eseguire un'altra Visita Notturna che introduce un Giocatore alla Mafia, convertendo il suo Ruolo in quello di Mafioso. In cambio, lo Yakuza paga con la propria vita. Non può essere salvato dal Dottore.",

  "Il Dottore fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Il Dottore esegue una Visita Notturna che impedisce la morte del Giocatore scelto, durante quella Notte. Non può salvare sè stesso ma può salvare lo stesso Giocatore più volte consecutivamente. Non può salvare lo Yakuza.",

  "Lo Strizzacervelli fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. Lo Strizzacervelli esegue una Visita Notturna che psicanalizza il Giocatore scelto, impedendogli di essere convertito quella Notte. Lo Strizzacervelli può psicanalizzare sè stesso. Lo Strizzacervelli può psicanalizzare lo stesso Giocatore più volte consecutivamente. Può rendere vano il sacrificio dello Yakuza, impedendo la conversione del Giocatore psicanalizzato in un Mafioso.",

  "La Nonnina fa parte del Villaggio, in opposizione alla Mafia. Il Villaggio vince linciando la Mafia. La Nonnina non esegue Visite Notturne, ma uccide indiscriminatamente chiunque esegue una Visita Notturna su di lei. La Nonnina, inoltre, non può essere uccisa durante la Notte. La Nonnina può comunque morire se linciata.",

  "Il Folle agisce per proprio conto. Il Folle vince se viene linciato (non vince se viene ucciso in altri modi!). Il Folle vince con disonore se è ancora vivo nel momento in cui il Villaggio vince. Il Folle non esegue alcuna Visita Notturna. Nel cercare di farsi linciare, il Folle si comporta come un appartenente alla Mafia, ma senza esagerare. Il Folle adora allearsi con la Mafia, ed in casi fortunati può allearsi anche con l'Offeso.",

  "L'Offeso agisce per proprio conto. Un Giocatore l'ha offeso ad inizio partita. L'Offeso vince se è vivo quando il Giocatore che l'ha offeso viene linciato (non vince se viene ucciso in altri modi!). L'Offeso, inoltre, vince con disonore se è ancora vivo quando il Villaggio vince. Ad inizio partita, il Giocatore che l'ha offeso è scelto casualmente tra gli appartenenti al Villaggio ed il Folle. L'Offeso non esegue alcuna Visita Notturna. L'Offeso può allearsi con chiunque, in base alla situazione.",

}

-- visit description, classic
local visit_classic = {

  "La Mafia può indicare di comune accordo un Giocatore da uccidere.",

  "Il Detective può indicare un Giocatore su cui indagare. Indicherò con un segno se questo sia Innocente o Colpevole.",

  "Il Dottore può indicare un Giocatore ed impedirne la morte durante questa Notte. Non può indicare sè stesso. Può salvare lo stesso Giocatore per più turni consecutivamente.",

}

-- visit description, gnh
local visit_gnh = {

  "La Mafia può indicare di comune accordo un Giocatore da uccidere.",

  "La Squillo può indicare un Giocatore da sedurre.",

  "Il Detective può indicare un Giocatore su cui indagare. Indicherò con un segno se questo sia Innocente o Colpevole, oppure se il Detective è stato sedotto dalla Squillo.",

  "L'Armaiolo può indicare un Giocatore a cui consegnare una Pistola.",

}

-- visit description, btb
local visit_btb = {

  "La Mafia può indicare di comune accordo un Giocatore da uccidere.",

  "La Squillo può indicare un Giocatore da sedurre.",

  "L'Armaiolo può indicare un Giocatore a cui consegnare una Pistola.",

}

-- visit description, shrink
local visit_shrink = {

  "[Il Dottore può indicare un Giocatore ed impedirne la morte durante questa Notte. Non può indicare sè stesso. Può salvare lo stesso Giocatore per più turni consecutivi.]",

  "[Lo Strizzacervelli può indicare un Giocatore da psicanalizzare. Può indicare sè stesso. Può psicanalizzare lo stesso Giocatore più volte consecutivamente.]",

  "[Il Capocultista può indicare un Giocatore da convertire al Culto.]",

  "[Il Killer deve indicare un Giocatore da uccidere.]",

  "[Il Cultista non esegue Visite Notturne.]",

}

-- visit description, kvsm
local visit_kvsm = {

  "La Mafia può indicare un Giocatore da uccidere.",

  "Il Dottore può indicare un Giocatore ed impedirne la morte durante questa Notte. Non può indicare sè stesso. Può salvare lo stesso Giocatore per più turni consecutivi.",

  "Il Killer deve indicare un Giocatore da uccidere.",

}

-- visit description, ft3
local visit_ft3 = {

  "La Mafia può indicare di comune accordo un Giocatore da uccidere.",

  "La Squillo può indicare un Giocatore da sedurre.",

  "Il Dottore può indicare un Giocatore ed impedirne la morte durante questa Notte. Non può indicare sè stesso. Può salvare lo stesso Giocatore per più turni consecutivi.",

  "Il Vigilante può indicare un Giocatore da uccidere.",

  "Il Detective può indicare un Giocatore su cui indagare. Indicherò con un segno se questo sia Innocente o Colpevole, oppure se il Detective è stato sedotto dalla Squillo.",

}

-- visit description, gallows
local visit_gallows = {

  "La Mafia può indicare di comune accordo un Giocatore da uccidere.",

  "Il Detective può indicare un Giocatore su cui indagare. Indicherò con un segno se questo sia Innocente o Colpevole.",

  "Il Dottore può indicare un Giocatore ed impedirne la morte durante questa Notte. Non può indicare sè stesso. Può salvare lo stesso Giocatore per più turni consecutivamente.",

}

-- visit description, everyman
local visit_everyman = {

  "La Mafia può indicare di comune accordo un Giocatore da uccidere.",

  "Lo Yakuza deve indicare un Giocatore da introdurre alla Mafia, dando in cambio la propria vita. Non può essere salvato dal Dottore.",

  "Il Dottore può indicare un Giocatore ed impedirne la morte durante questa Notte (tranne lo Yakuza). Non può indicare sè stesso. Può salvare lo stesso Giocatore per più turni consecutivamente.",

  "Lo Strizzacervelli può indicare un Giocatore da psicanalizzare. Può indicare sè stesso. Può psicanalizzare lo stesso Giocatore più volte consecutivamente.",

}

-- night strat description, classic
local nightstrat_classic = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. I Mafiosi decidono chi dei due domani si fingerà Detective. Il Detective fasullo presenterà un Report inventato, a sua discrezione. Le possibilità di vittoria per la Mafia, senza scegliere un falso Detective, sono scarse. A meno di aver ucciso Detective o Dottore.",
  "Durante la prima Notte, il Detective indaga chi preferisce. Deve, inoltre, riflettere su come e quando dichiarare il proprio Report.",
  "Durante la prima Notte, il Dottore salva chi preferisce. Deve, inoltre, ricordare chi ha salvato stanotte.",

  --n2
  "Durante la seconda Notte, la Mafia sceglie con attenzione la propria vittima, date le possibili implicazioni nascoste che potrebbero derivarne. Eliminare il Dottore è quasi sempre l'opzione migliore. Uccidere il Detective è altamente sconsigliato. Non uccidere nessuno, cercando di ingannare il Dottore, è altamente sconsigliato.",
  "Durante la seconda Notte, il Detective sceglie con attenzione il proprio indagato, date le possibili implicazioni nascoste che potrebbero derivarne. Non deve mai indagare sul falso Detective, senz'altro un Mafioso. Se l'Innocente dichiarato dal falso Detective è vivo, indagarlo lo renderebbe Confermato Innocente, permettergli di guidare il Villaggio.",
  "Durante la seconda Notte, il Dottore sceglie con attenzione il proprio salvato. Salvare un Detective, uno dei loro Innocenti oppure un Giocatore di grande aiuto al Villaggio, sono solide opzioni. Deve, inoltre, ricordare chi ha salvato stanotte.",

  --n3
  "Durante la terza Notte, la Mafia uccide chiunque possa guidare il Villaggio. Privato del proprio compagno, il Mafioso potrà vincere solo sopravvivendo al Finale-a-Tre.",
  "Durante la terza Notte, il Detective indaga chi preferisce. Non dovrebbe comunque sopravvivere alla Notte.",
  "Durante la terza Notte, il Dottore salva chi preferisce. Non dovrebbe comunque sopravvivere alla Notte.",

  --n4
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- night strat description, gnh
local nightstrat_gnh = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. Il Mafioso deve pensare se dichiararsi Detective domani. Riguardo alla Pistola, il Mafioso deve sempre tenerla nascosta, usandola solo se linciato, altrimenti conservandola per il secondo Giorno.",
  "Durante la prima Notte, la Squillo seduce chi preferisce, evitando la vittima appena scelta al Raduno Mafioso. La Squillo deve concentrarsi nell'apparire Innocente, ignorando completamente il comportamento del compagno Mafioso, senza obbligo di difenderlo o timore di accusarlo. Riguardo alla Pistola, la Squillo può scegliere se nasconderla o meno. Nasconderla è sconsigliato.",
  "Durante la prima Notte, il Detective indaga chi preferisce. Deve, inoltre, riflettere su come e quando dichiarare il proprio Report.",
  "Durante la prima Notte, l'Armaiolo consegna la Pistola a chi preferisce. Non consegnarla penalizza il Villaggio. Deve assolutamente ricordare a chi ha consegnato la Pistola. Quel Giocatore potrà usare la Pistola per uccidere un Giocatore a sua scelta, in qualsiasi momento del Giorno. La Pistola ha un singolo colpo. Può essere conservata per più Giorni.",

  --n2
  "Durante la seconda Notte, la Mafia riflette attentamente su chi uccidere. Spesso dovrà fare fuori il Detective oppure l'Armaiolo, altrimenti dovrà uccidere il Giocatore più utile al Villaggio, puntando a massimizzare le possibilità di vittoria della Squillo.",
  "Durante la seconda Notte, la Squillo riflette attentamente su chi sedurre il Detective o l'Armaiolo. Deve, inoltre, riflettere sulla tattica da adottare per apparire Innocente.",
  "Durante la seconda Notte, il Detective riflette attentamente su chi indagare, concentrandosi unicamente sul procurare un Report utile.",
  "Durante la seconda Notte, l'Armaiolo riflette attentamente se ed a chi consegnare la Pistola. Un errore condurrebbe alla sconfitta del Villaggio. Nel dubbio, meglio semplicemente evitare.",

  --n3
  "Durante la terza Notte, la Mafia dovrebbe essere ridotta ad un solo membro. Deve, inoltre, formulare una strategia per sopravvivere domani nel Finale-a-Tre, e scegliere l'uccisione in base ad essa.",
  "Durante la terza Notte, la Squillo dovrebbe essere rimasta sola. Deve sedurre il Detective o l'Armaiolo, se ancora vivi.",
  "Durante la terza Notte, il Detective riflette attentamente su chi indagare, concentrandosi unicamente sul procurare un Report utile. Qualora sopravvivesse, domani dovrà guidare il Villaggio.",
  "Durante la terza Notte, l'Armaiolo riflette attentamente se ed a chi consegnare la Pistola. Un errore condurrebbe alla sconfitta del Villaggio. Nel dubbio, meglio semplicemente evitare.",

  --n4
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- night strat description, btb
local nightstrat_btb = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. Riguardo alla Pistola, sia il Mafioso che la Squillo devono sempre tenerla nascosta. La Mafia deve concentrarsi nell'apparire Innocente.",
  "Durante la prima Notte, la Squillo seduce chi preferisce, evitando la vittima appena scelta al Raduno Mafioso.",
  "Durante la prima Notte, l'Armaiolo consegna la Pistola a chi preferisce. Non consegnarla penalizza il Villaggio. Deve assolutamente ricordare a chi ha consegnato la Pistola. Quel Giocatore potrà usare la Pistola per uccidere un Giocatore a sua scelta, in qualsiasi momento del Giorno. La Pistola ha un singolo colpo. Può essere conservata per più Giorni.",

  --n2
  "Durante la seconda Notte, la Mafia uccide la Sposa, se viva. Altrimenti, uccide chi preferisce.",
  "Durante la seconda Notte, la Squillo seduce l'Armaiolo, se vivo ed è presente un Confermato Innocente cui la consegnerebbe. Altrimenti, seduce chi preferisce, o nessuno.",
  "Durante la seconda Notte, l'Armaiolo consegna la Pistola ad un Confermato Innocente, se presente. Altrimenti deve riflettere attentamente sulla scelta. Nel dubbio, meglio semplicemente evitare.",

  --n3
  "Durante la terza Notte, la Mafia dovrebbe essere ridotta ad un solo membro. Deve formulare una strategia per sopravvivere domani nel Finale-a-Tre, e scegliere l'uccisione in base ad essa.",
  "Durante la terza Notte, la Squillo dovrebbe essere rimasta sola. Deve riflettere se e chi sedurre.",
  "Durante la terza Notte, l'Armaiolo riflette attentamente se ed a chi consegnare la Pistola. Un errore condurrebbe alla sconfitta del Villaggio. Nel dubbio, meglio semplicemente evitare.",

  --n4
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- night strat description, shrink
local nightstrat_shrink = {

  --n1
  "Durante la prima Notte, il Dottore non salva nessuno perchè potrebbe salvare il Capocultista. Lo Strizzacervelli può psicanalizzare chi vuole. Psicanalizzare un Giocatore non lo rende Confermato Innocente. Il Killer uccide chi preferisce. Il Capocultista converte chi preferisce.\n\nLode al Culto!",

  --n2
  "Durante il resto delle Notti, il Dottore salva solo se il Killer si allea con il Culto. Lo Strizzacervelli ed il Paesano agiscono autonomamente. Il Killer, se c'è, uccide chi preferisce. Il Capocultista converte chi preferisce. I Cultisti cercano di identificare gli altri appartenenti al Culto, così da poter collaborare. La loro missione è evitare il Linciaggio del Capocultista, anche a costo di sacrificarsi.\n\nLode al Culto!"

}

-- night strat description, kvsm
local nightstrat_kvsm = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. Non uccidere nessuno per poi chiamarsi colpito è altamente sconsigliato, ma possibile.",
  "Durante la prima Notte, il Killer uccide chi preferisce.",
  "Durante la prima Notte, il Dottore non salva nessuno. La sua Visita Notturna impedisce la morte ma non il danneggiamento dell'Antiproiettile, quindi rischierebbe perlopiù di salvare il Mafioso oppure il Killer.",

  --n2
  "Durante la seconda Notte, la Mafia uccide chi preferisce. Se desidera, può non uccidere per poi chiamarsi colpito.",
  "Durante la seconda Notte, il Killer uccide chi preferisce.",
  "Durante la seconda Notte, il Dottore sceglie chi salvare tra i Giocatori dichiaratisi colpiti. Deve, inoltre, ricordare chi ha salvato stanotte.",

  --n3
  "Durante la terza Notte, la Mafia uccide chi preferisce. Se desidera, può non uccidere per poi chiamarsi colpito.",
  "Durante la terza Notte, il Killer uccide chi preferisce.",
  "Durante la terza Notte, il Dottore sceglie chi salvare tra i Giocatori dichiaratisi colpiti. Non dovrebbe comunque sopravvivere alla Notte.",

  --n4
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- night strat description, ft3
local nightstrat_ft3 = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. Il Mafioso deve fingersi Detective domani e decidere che il proprio Report fasullo.",
  "Durante la prima Notte, la Squillo seduce chi preferisce, evitando la vittima appena scelta al Raduno Mafioso.",
  "Durante la prima Notte, il Detective indaga chi preferisce. Il Detective domani deve sempre dichiarare il proprio Report. Deve ricordarsi che solo la Mafia appare Colpevole nei Report.",
  "Durante la prima Notte, il Vigilante non deve sparare. Rischia di colpire il Villaggio e di morire se sceglie la stessa vittima del Raduno Mafioso.",
  "Durante la prima Notte, il Dottore salva chi preferisce. Deve, inoltre, ricordare chi ha salvato stanotte.",

  --n2
  "Durante la seconda Notte, la Mafia uccide chi preferisce.",
  "Durante la seconda Notte, la Squillo seduce chi preferisce, evitando la vittima appena scelta al Raduno Mafioso.",
  "Durante la seconda Notte, il Detective indaga chi preferisce. Deve ricordarsi che solo la Mafia appare Colpevole nei Report.",
  "Durante la seconda Notte, il Vigilante uccide chi preferisce. Dovrebbe sparare tra i Giocatori dichiaratisi Detective. In alcuni casi, dare la priorità all'uccidere il Folle può essere vantaggioso.",
  "Durante la seconda Notte, il Dottore riflette attentamente se salvare e chi. Dovrebbe salvare solo i Giocatori Confermati Innocenti, altrimenti rischierebbe di salvare il Folle. Nel dubbio, meglio semplicemente evitare.",

  --n3
  "Durante la terza Notte, la Mafia uccide chi preferisce.",
  "Durante la terza Notte, la Squillo seduce chi preferisce, evitando la vittima appena scelta al Raduno Mafioso.",
  "Durante la terza Notte, il Detective indaga chi preferisce. Non dovrebbe comunque sopravvivere alla Notte.",
  "Durante la terza Notte, il Vigilante riflette attentamente se uccidere e chi. A questo punto sia la Mafia che il Folle sono ottime vittime. Probabilmente il Vigilante morirà o verrà sedotto.",
  "Durante la terza Notte, il Dottore riflette attentamente se salvare e chi. Dovrebbe salvare solo i Giocatori Confermati Innocenti, altrimenti rischierebbe di salvare il Folle. Nel dubbio, meglio semplicemente evitare.",

  --n4
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- night strat description, gallows
local nightstrat_gallows = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. Decidere chi si fingerà Detective domani è opzionale, in quanto già il Folle e l'Offeso lo faranno.",
  "Durante la prima Notte, il Detective indaga chi preferisce. Deve prepararsi a difendere il proprio Report da altri due o tre Detective fasulli. Deve, inoltre, ricordarsi che solo la Mafia appare Colpevole nei Report",
  "Durante la prima Notte, il Dottore salva chi preferisce. Deve, inoltre, ricordare chi ha salvato stanotte.",

  --n2
  "Durante la seconda Notte, la Mafia uccide chi preferisce. Le identità del Detective, del Folle e dell'Offeso (e di chi l'abbia offeso) dovrebbero essere chiare. La Mafia deve usare tali informazioni per vincere tramite un'alleanza domani.",
  "Durante la seconda Notte, il Detective indaga chi preferisce. Il suo obbiettivo principale è distinguere il Ruolo dei vari Detective fasulli. Deve, inoltre, ricordarsi che solo la Mafia appare Colpevole nei Report.",
  "Durante la seconda Notte, il Dottore salva chi preferisce. Tuttavia, deve tener conto che la morte di un Giocatore potrebbe essere estremamente vantaggiosa per il Villaggio.",

  --n3
  "Durante la terza Notte, la Mafia uccide chi preferisce. Deve puntare ad una vittoria in un Finale-a-Tre oppure un Finale-a-Quattro ottenuta alleandosi con il Folle oppure l'Offeso.",
  "Durante la terza Notte, il Detective indaga chi preferisce. Continua il suo lavoro puntando ad evitare la vittoria della Mafia, del Folle o dell'Offeso. Deve, inoltre, ricordarsi che solo la Mafia appare Colpevole nei Report.",
  "Durante la terza Notte, il Dottore salva chi preferisce. Tuttavia, deve tener conto che la morte di un Giocatore potrebbe essere estremamente vantaggiosa per il Villaggio.",

  --n4
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- night strat description, everyman
local nightstrat_everyman = {

  --n1
  "Durante la prima Notte, la Mafia uccide chi preferisce. Visitare la Nonnina non è un problema, dato lo Yakuza già paga con la propria vita la conversione di un Giocatore al Ruolo di Mafioso.",
  "Durante la prima Notte, lo Yakuza deve convertire un Giocatore in un Mafioso, evitando la vittima appena scelta al Raduno Mafioso. Lo Yakuza paga con la propria vita questa Visita Notturna, e non può essere salvato dal Dottore.",
  "Durante la prima Notte, il Dottore salva chi preferisce. Se ha paura di visitare la Nonnina, può non salvare nessuno. Non può salvare lo Yakuza.",
  "Durante la prima Notte, lo Strizzacervelli psicanalizza chi preferisce. Se ha paura di visitare la Nonnina, può non psicanalizzare nessuno, ma è altamente sconsigliato.",

  --n2
  "Durante la seconda Notte, la Mafia riflette attentamente su chi uccidere. Il Mafioso ha la possibilità di allearsi con il Folle oppure con l'Offeso, ed agisce di conseguenza.",
  "Durante la seconda Notte, lo Yakuza è morto.",
  "Durante la seconda Notte, il Dottore salva un Giocatore solo se ne conosce il Ruolo e lo ritiene necessario alla vittoria del Villaggio.",
  "Durante la seconda Notte, lo Strizzacervelli non psicanalizza nessuno. Non guadagna alcuna informazione nell'eseguire questa Visita Notturna potenzialmente mortale.",

  --n3
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, classic
local daystrat_classic = {

  --d1
  "Durante il primo Giorno, solitamente due Giocatori si dichiarano Detective e comunichano i propri Report. In tal caso, non si deve linciare nessuno oggi: il Villaggio perde se sbaglia il Linciaggio. Il Dottore deve confondersi tra la folla, nascondendosi alla Mafia. I Paesani si concentrano nell'individuare comportamenti sospetti. La Mafia cerca di apparire Innocente.",
  --d2
  "Durante il secondo Giorno, solitamente i due Detective esternano i nuovi Report ed è obbligatorio linciare, altrimenti il Villaggio stanotte perderà. Il Dottore, oppure un Giocatore Confermato Innocente, devono guidare la discussione ed il Linciaggio. Aspettatevi un dibattito incandescente.",
  --d3
  "Durante il terzo Giorno, solitamente il Villaggio è coinvolto in un Finale-a-Tre. Cioè tre Giocatori vivi, tra cui un Mafioso. Se è vivo un Confermato Innocente, deve guidare il Villaggio ed avere l'ultima parola sul Linciaggio. Il Mafioso deve sopravvivere, cercando di non cambiare spesso idea oppure essere troppo accomodante. Aspettatevi un dibattito ancora più incandescente.",
  --d4
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, gnh
local daystrat_gnh = {

  --d1
  "Durante il primo Giorno, tutti dichiarano subito se possiedono la Pistola. Qualora nessuno l'abbia dichiarata, l'Armaiolo interviene, a meno di averla consegnata al morto. Il Detective può dichiararsi quando preferisce, generalmente dopo l'Armaiolo. Se possibile, l'Armaiolo guida lo sparo, ed il successivo Linciaggio. I Paesani si concentrano nell'individuare comportamenti sospetti.",
  --d2
  "Durante il secondo Giorno, tutti dichiarano subito se possiedono la Pistola. Se presenti due Detective, si lincia uno di loro. Altrimenti, l'Armaiolo e/o il Detective guidano il Linciaggio tra i restanti giocatori sospetti.",
  --d3
  "Durante il terzo Giorno, tutti dichiarano subito se possiedono la Pistola. L'Armaiolo e/o il Detective, se ancora vivi, devono guidare il Villaggio ed avere l'ultima parola sul Linciaggio. Qualora fossero morti, il Villaggio dovrà destreggiarsi in un Finale-a-Tre.",
  --d4
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, btb
local daystrat_btb = {

  --d1
  "Durante il primo Giorno, l'Armaiolo indica a chi ha consegnato la Pistola. Se l'Armaiolo è morto, tutti dichiarano subito se possiedono la Pistola. La Sposa convola a nozze con chi ha la Pistola. I Paesani si concentrano nell'individuare comportamenti sospetti. L'Armaiolo e/o la Sposa guidano il Villaggio.",
  --d2
  "Durante il secondo Giorno, il Villaggio continua la caccia alla Mafia, guidato dall'Armaiolo e/o dalla Sposa, se vivi.",
  --d3
  "Durante il terzo Giorno, l'Armaiolo e/o la Sposa, se ancora vivi, devono guidare il Villaggio ed avere l'ultima parola sul Linciaggio. Qualora fossero morti, il Villaggio dovrà destreggiarsi in un Finale-a-Tre.",
  --d4
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, shrink
local daystrat_shrink = {

  --d1
  "Durante il primo Giorno, il Killer si dichiara e guida il Villaggio cercando di linciare il Capocultista. Il Capocultista cerca di sopravvivere. L'eventuale Cultista, cerca di individuare il Capocultista ed evitarne il Linciaggio. Ricordate che chiunque potrebbe venire convertito al Culto, e quindi tradire il Villaggio pur di vincere.\n\nLode al Culto!",
  --d2
  "Durante il secondo Giorno, il Killer dovrebbe essere ora un semplice Paesano. Il Villaggio continua a cercare di linciare il Capocultista. Il Killer dovrebbe guidare, in quanto unico Confermato Innocente.\n\nLode al Culto!",
  --d3
  "Durante il resto dei Giorni, il Culto incombe minaccioso, vicino alla vittoria. Tutti dovrebbero agire autonomamente, decidendo con chi schierarsi. Tenete in considerazione che gli Strizzacervelli possono impedire vostra conversione al Culto.\n\nLode al Culto!",

}

-- day strat description, kvsm
local daystrat_kvsm = {

  --d1
  "Durante il primo Giorno, tutti i Giocatori colpiti lo dichiarano. Non sono automaticamente Confermati Innocenti, in quanto la Mafia poteva non uccidere e dichiararsi colpito. Se il Dottore è morto, il VIllaggio deve linciare.",
  --d2
  "Durante il secondo Giorno, tutti i Giocatori colpiti lo dichiarano. Nel probabile caso in cui sia necessario linciare, il Dottore deve dichiararsi e guidare il Villaggio.",
  --d3
  "Durante il terzo Giorno, il Villaggio è coinvolto in un Finale-a-Tre. Se la Mafia ed il Killer sono vivi, possono vincere insieme. Altrimenti, se possibile, un Giocatore Confermato Innocente guida il Villaggio.",
  --d4
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, ft3
local daystrat_ft3 = {

  --d1
  "Durante il primo Giorno, solitamente due o tre Giocatori si dichiarano Detective (il vero Detective, il Mafioso, opzionalmente il Folle) ed esternano i propri Report. Il Villaggio decide il Linciaggio oppure si affida al colpo del Vigilante stanotte. Se il Detective è morto, il Dottore dovrebbe guidare il Villaggio. Attenzione, il Folle può dichiararsi qualunque Ruolo allo scopo di farsi linciare.",
  --d2
  "Durante il secondo Giorno, se il Villaggio ha fallito allora la Mafia ed il Folle possono vincere insieme. Altrimenti, il Dottore (o se necessario il Vigilante) si dichiara e guida il Villaggio, prestando attenzione a non linciare il Folle.",
  --d3
  "Durante il terzo Giorno, solitamente il Villaggio è coinvolto in un Finale-a-Tre. Se la Mafia ed il Folle sono vivi, possono vincere insieme. Altrimenti, se possibile, un Giocatore Confermato Innocente guida il Villaggio.",
  --d4
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, gallows
local daystrat_gallows = {

  --d1
  "Durante il primo Giorno, solitamente tre o quattro Giocatori si dichiareranno Detective. L'Offeso dichiarerà Colpevole il Giocatore che l'ha offeso. Il Folle vorrà farsi linciare, esternando un Report qualsiasi. Tutti i Giocatori cercano di assegnare i veri Ruoli ai Detective, ciascuno per far vincere la propria Fazione. In base alla situazione ed ai Ruoli ancora vivi, il Villaggio può agire come meglio crede ma è sconsigliato linciare i Colpevoli.",
  --d2
  "Durante il secondo Giorno, il Villaggio continua nella sua ricerca della verità e nell'evitare le trappole delle altre Fazioni. La Mafia cerca di allearsi con il Folle e l'Offeso, e viceversa. In base alla situazione ed ai Ruoli ancora vivi, ogni Fazione ha ampia libertà di manovra e può agire come meglio crede.",
  --d3
  "Durante il terzo Giorno, solitamente il Villaggio è coinvolto in un Finale-a-Tre oppure in un Finale-a-Quattro. In base alla situazione ed ai Ruoli ancora vivi, ogni Fazione ha ampia libertà di manovra e può agire come meglio crede.",
  --d4
  "Non sono disponibili ulteriori strategie.",

}

-- day strat description, everyman
local daystrat_everyman = {

  --d1
  "Durante il primo Giorno, ogni Giocatore cerca di scoprire i Ruoli degli altri così da far vincere la propria Fazione. Il Mafioso, introdotto alla Mafia dallo Yakuza, dichiarerà il suo Ruolo precedente e quindi sarà difficile da scovare, ma per vincere dovrà allearsi con il Folle oppure con l'Offeso.",
  --d2
  "Durante il secondo Giorno, dovrebbe essere abbastanza chiara la situazione e spesso verranno formate alleanze vincenti. Se vi trovate in difficoltà, cercate di confondere gli altri Giocatori, così da impedirne la vittoria e successivamente strappargliela dalle mani.",
  --d3
  "Non sono disponibili ulteriori strategie.",

}

function M.getFactionsOverview( faction )

  if faction == "Villaggio" then
    return overview_factions[1]
  elseif faction == "Mafia" then
    return overview_factions[2]
  elseif faction == "Killer" then
    return overview_factions[3]
  elseif faction == "Folle" then
    return overview_factions[4]
  elseif faction == "Culto" then
    return overview_factions[5]
  elseif faction == "Offeso" then
    return overview_factions[6]
  end

end

function M.getRole( setup, role )

  if setup == "Mafia Classica" then
    if role == "Paesano" then
      return overview_classic[1]
    elseif role == "Mafioso" then
      return overview_classic[2]
    elseif role == "Detective" then
      return overview_classic[3]
    elseif role == "Dottore" then
      return overview_classic[4]
    end

  elseif setup == "Pistole & Prostitute" then
    if role == "Paesano" then
      return overview_gnh[1]
    elseif role == "Mafioso" then
      return overview_gnh[2]
    elseif role == "Squillo" then
      return overview_gnh[3]
    elseif role == "Armaiolo" then
      return overview_gnh[4]
    elseif role == "Detective" then
      return overview_gnh[5]
    end

  elseif setup == "Amore a Prima Vista" then
    if role == "Paesano" then
      return overview_btb[1]
    elseif role == "Mafioso" then
      return overview_btb[2]
    elseif role == "Squillo" then
      return overview_btb[3]
    elseif role == "Armaiolo" then
      return overview_btb[4]
    elseif role == "Sposa" then
      return overview_btb[5]
    end

  elseif setup == "Lode al Culto" then
    if role == "Dottore" then
      return overview_shrink[1]
    elseif role == "Strizzacervelli" then
      return overview_shrink[2]
    elseif role == "Capocultista" then
      return overview_shrink[3]
    elseif role == "Killer" then
      return overview_shrink[4]
    end

  elseif setup == "Il Villaggio Selvaggio" then
    if role == "Mafioso" then
      return overview_kvsm[1]
    elseif role == "Dottore" then
      return overview_kvsm[2]
    elseif role == "Antiproiettile" then
      return overview_kvsm[3]
    elseif role == "Killer" then
      return overview_kvsm[4]
    end

  elseif setup == "Giustizia o Follia?" then
    if role == "Paesano" then
      return overview_ft3[1]
    elseif role == "Mafioso" then
      return overview_ft3[2]
    elseif role == "Squillo" then
      return overview_ft3[3]
    elseif role == "Dottore" then
      return overview_ft3[4]
    elseif role == "Vigilante" then
      return overview_ft3[5]
    elseif role == "Detective" then
      return overview_ft3[6]
    elseif role == "Folle" then
      return overview_ft3[7]
    end

  elseif setup == "Io adoro i Linciaggi!" then
    if role == "Paesano" then
      return overview_gallows[1]
    elseif role == "Mafioso" then
      return overview_gallows[2]
    elseif role == "Dottore" then
      return overview_gallows[3]
    elseif role == "Detective" then
      return overview_gallows[4]
    elseif role == "Folle" then
      return overview_gallows[5]
    elseif role == "Offeso" then
      return overview_gallows[6]
    end

  elseif setup == "Dottori, Pazienti e Pazzi" then
    if role == "Yakuza" then
      return overview_everyman[1]
    elseif role == "Dottore" then
      return overview_everyman[2]
    elseif role == "Strizzacervelli" then
      return overview_everyman[3]
    elseif role == "Nonnina" then
      return overview_everyman[4]
    elseif role == "Folle" then
      return overview_everyman[5]
    elseif role == "Offeso" then
      return overview_everyman[6]
    end

  end

end

function M.getVisit( setup, visit )

  if setup == "Mafia Classica" then
    if visit == "Mafia" then
      return visit_classic[1]
    elseif visit == "Detective" then
      return visit_classic[2]
    elseif visit == "Dottore" then
      return visit_classic[3]
    end

  elseif setup == "Pistole & Prostitute" then
    if visit == "Mafia" then
      return visit_gnh[1]
    elseif visit == "Squillo" then
      return visit_gnh[2]
    elseif visit == "Detective" then
      return visit_gnh[3]
    elseif visit == "Armaiolo" then
      return visit_gnh[4]
    end

  elseif setup == "Amore a Prima Vista" then
    if visit == "Mafia" then
      return visit_btb[1]
    elseif visit == "Squillo" then
      return visit_btb[2]
    elseif visit == "Armaiolo" then
      return visit_btb[3]
    end

  elseif setup == "Lode al Culto" then
    if visit == "Dottore" then
      return visit_shrink[1]
    elseif visit == "Strizzacervelli" then
      return visit_shrink[2]
    elseif visit == "Capocultista" then
      return visit_shrink[3]
    elseif visit == "Killer" then
      return visit_shrink[4]
    elseif visit == "Cultista" then
      return visit_shrink[5]
    end

  elseif setup == "Il Villaggio Selvaggio" then
    if visit == "Mafia" then
      return visit_kvsm[1]
    elseif visit == "Dottore" then
      return visit_kvsm[2]
    elseif visit == "Killer" then
      return visit_kvsm[3]
    end

  elseif setup == "Giustizia o Follia?" then
    if visit == "Mafia" then
      return visit_ft3[1]
    elseif visit == "Squillo" then
      return visit_ft3[2]
    elseif visit == "Dottore" then
      return visit_ft3[3]
    elseif visit == "Vigilante" then
      return visit_ft3[4]
    elseif visit == "Detective" then
      return visit_ft3[5]
    end

  elseif setup == "Io adoro i Linciaggi!" then
    if visit == "Mafia" then
      return visit_gallows[1]
    elseif visit == "Detective" then
      return visit_gallows[2]
    elseif visit == "Dottore" then
      return visit_gallows[3]
    end

  elseif setup == "Dottori, Pazienti e Pazzi" then
    if visit == "Mafia" then
      return visit_everyman[1]
    elseif visit == "Yakuza" then
      return visit_everyman[2]
    elseif visit == "Dottore" then
      return visit_everyman[3]
    elseif visit == "Strizzacervelli" then
      return visit_everyman[4]
    end

  end

end

function M.getNightStrat( setup, visit, nightcount )

  if setup == "Mafia Classica" then
    if nightcount > 4 then
      nightcount = 4
    end
    if visit == "Mafia" then
      return nightstrat_classic[1+nightcount*3]
    elseif visit == "Detective" then
      return nightstrat_classic[2+nightcount*3]
    elseif visit == "Dottore" then
      return nightstrat_classic[3+nightcount*3]
    end

  elseif setup == "Pistole & Prostitute" then
    if nightcount > 4 then
      nightcount = 4
    end
    if visit == "Mafia" then
      return nightstrat_gnh[1+nightcount*4]
    elseif visit == "Squillo" then
      return nightstrat_gnh[2+nightcount*4]
    elseif visit == "Detective" then
      return nightstrat_gnh[3+nightcount*4]
    elseif visit == "Armaiolo" then
      return nightstrat_gnh[4+nightcount*4]
    end

  elseif setup == "Amore a Prima Vista" then
    if nightcount > 4 then
      nightcount = 4
    end
    if visit == "Mafia" then
      return nightstrat_btb[1+nightcount*3]
    elseif visit == "Squillo" then
      return nightstrat_btb[2+nightcount*3]
    elseif visit == "Armaiolo" then
      return nightstrat_btb[3+nightcount*3]
    end

  elseif setup == "Lode al Culto" then
    if nightcount > 1 then
      nightcount = 1
    end
    if visit == "Lode al Culto" then
      return nightstrat_shrink[1+nightcount]
    end

  elseif setup == "Il Villaggio Selvaggio" then
    if nightcount > 4 then
      nightcount = 4
    end
    if visit == "Mafia" then
      return nightstrat_kvsm[1+nightcount*3]
    elseif visit == "Dottore" then
      return nightstrat_kvsm[2+nightcount*3]
    elseif visit == "Killer" then
      return nightstrat_kvsm[3+nightcount*3]
    end

  elseif setup == "Giustizia o Follia?" then
    if nightcount > 4 then
      nightcount = 4
    end
    if visit == "Mafia" then
      return nightstrat_ft3[1+nightcount*5]
    elseif visit == "Squillo" then
      return nightstrat_ft3[2+nightcount*5]
    elseif visit == "Dottore" then
      return nightstrat_ft3[3+nightcount*5]
    elseif visit == "Vigilante" then
      return nightstrat_ft3[4+nightcount*5]
    elseif visit == "Detective" then
      return nightstrat_ft3[5+nightcount*5]
    end

  elseif setup == "Io adoro i Linciaggi!" then
    if nightcount > 4 then
      nightcount = 4
    end
    if visit == "Mafia" then
      return nightstrat_gallows[1+nightcount*3]
    elseif visit == "Detective" then
      return nightstrat_gallows[2+nightcount*3]
    elseif visit == "Dottore" then
      return nightstrat_gallows[3+nightcount*3]
    end

  elseif setup == "Dottori, Pazienti e Pazzi" then
    if nightcount > 3 then
      nightcount = 3
    end
    if visit == "Mafia" then
      return nightstrat_everyman[1+nightcount*4]
    elseif visit == "Yakuza" then
        return nightstrat_everyman[2+nightcount*4]
    elseif visit == "Dottore" then
      return nightstrat_everyman[3+nightcount*4]
    elseif visit == "Strizzacervelli" then
      return nightstrat_everyman[4+nightcount*4]
    end

  end

end

function M.getDayStrat( setup, nightcount )

  if setup == "Mafia Classica" then
    if nightcount > 4 then
      nightcount = 4
    end
    return daystrat_classic[nightcount]

  elseif setup == "Pistole & Prostitute" then
    if nightcount > 4 then
      nightcount = 4
    end
    return daystrat_gnh[nightcount]

  elseif setup == "Amore a Prima Vista" then
    if nightcount > 4 then
      nightcount = 4
    end
    return daystrat_btb[nightcount]

  elseif setup == "Lode al Culto" then
    if nightcount > 2 then
      nightcount = 2
    end
    return daystrat_shrink[nightcount]

  elseif setup == "Il Villaggio Selvaggio" then
    if nightcount > 4 then
      nightcount = 4
    end
    return daystrat_kvsm[nightcount]

  elseif setup == "Giustizia o Follia?" then
    if nightcount > 4 then
      nightcount = 4
    end
    return daystrat_ft3[nightcount]

  elseif setup == "Io adoro i Linciaggi!" then
    if nightcount > 4 then
      nightcount = 4
    end
    return daystrat_gallows[nightcount]

  elseif setup == "Dottori, Pazienti e Pazzi" then
    if nightcount > 3 then
      nightcount = 3
    end
    return daystrat_everyman[nightcount]

  end

end

return M
