OSM2KM4C
Copyright (C) 2017 DISIT Lab http://www.disit.org - University of Florence

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>. 

README   
------

Il materiale contenuto in questa cartella si inquadra nell'ambito del problema di mappare 
le province, i comuni, i toponimi e gli elementi stradali
del grafo strade della Regione Toscana, sui corrispondenti 
elementi del grafo strade importato da Open Street Map.

In particolare, è stato definito un algoritmo che procede attraverso numerosi
passi, in ognuno dei quali viene eseguita una delle query presenti in questa cartella, 
e ne vengono analizzati i risultati, per decidere come proseguire.

---------------
Building Blocks
---------------

Allo stesso livello di questo file readme sono collocati gli script sparql che contengono
le query che devono essere eseguite ai diversi passi dell'algoritmo, eventualmente da 
personalizzare variando le denominazioni dei grafi. 

---------------------
Sample Windows script
---------------------

Nella sottocartella tool sono contenuti uno script batch di Windows e un jar che consentono
di automatizzare l'esecuzione dell'algoritmo. Devono essere entrambi copiati in una stessa
cartella della macchina su cui si trova l'istanza di Virtuoso con cui dovranno interfacciarsi.
Per una guida all'utilizzo si può fare riferimento ai commenti contenuti nello stesso file 
batch, che deve essere considerato un esempio, da personalizzare secondo le indicazioni in 
esso stesso contenute, ed eventualmente da tradurre in script sh se l'istanza di Virtuoso si
trova su di una macchina Linux. 

Nella sottocartella lib sono contenute le librerie necessarie per la corretta esecuzione del 
jar. Un metodo triviale per garantire la visibilità delle librerie è quello di copiare la 
cartella lib (non soltanto il suo contenuto) nella cartella in cui si trova il jar.

-------------------------------
Ready To Use Scripts Collection
-------------------------------

Nei primi mesi del 2018 è stato predisposto un sistema organico di batch di Windows, che si trovano 
in ReadyToUse.zip. Laddove necessario, tali file contengono una parte iniziale di configurazione
in cui vengono impostate variabili di ambiente che sono poi utilizzate durante l'esecuzione. 
Lanciando uno dei file batch che si trovano al livello più alto, si riconciliano l'instanza della 
provincia, le istanze dei comuni, e le istanze delle strade e frammenti di strada, che si trovano 
nella provincia cui il nome del file batch fa riferimento. Il risultato finale di tali script è 
la produzione delle triple di configurazione su di un'istanza configurabile di Virtuoso, e la 
produzione di files N3 dove sono contenute le triple di riconciliazione pronte per essere 
caricate massivamente su di un qualsiasi graph database. La posizione in cui tali file N3 debbano
essere prodotti è anch'essa configurabile, così come gli URI dei diversi (in generale) grafi in cui
le tripe di riconciliazione devono essere inserite.

L'11 giugno 2018 è stata rilasciata una seconda versione degli script ReadyToUse, in cui sono state
apportate alcune correzioni che hanno permesso di eseguire la riconciliazione di cinque comuni 
aggiuntivi. La rassegna completa delle riconciliazioni che erano fallite nella prima versione, con 
indicazione per ciascuna della motivazione del fallimento, e l'eleventuale log di risoluzione (non 
tutte le cause sono risolvibili), può essere trovato in "ReadyToUse v2.xlsx", anch'esso committato
in questa cartella.

-------------------------
Results of Reconciliation
-------------------------

Gli script di cui al paragrafo precedente sono già stati eseguiti una volta, ed hanno prodotto un 
vasto insieme di triple, verificate a campione con esiti incoraggianti. Un file ZIP che contiene 
tutte le triple risultato della riconciliazione, ed anche tutte le triple che modellano i grafi strade
sorgenti, sia quello della Regione Toscana sia quello di Open Street Map, possono essere scaricate qui:

https://www.dropbox.com/s/uy8rl2fvptspx1r/Riconciliazione.zip?dl=1

Le ho sistemate nel mio dropbox personale perché è oltre un giga di materiale, e non avrebbe potuto 
essere quindi efficacemente sistemato sotto il sistema di versioning in uso.

In data 11 giugno 2018 è stata rilasciata una nuova versione delle triple, il meglio che sia possibile
ottenere con l'algoritmo corrente, pubblicata alla stessa posizione. Ulteriori miglioramenti saranno
possibili andando a sfruttare, quando un giorno decideremo di caricarle, le Administrative Roads.

----------
Future Dev
----------

Al momento in cui si scrive permangono criticità su casi isolati per quanto riguarda la riconciliazione 
delle strade e dei frammenti di strada. Inoltre, l'attuale algoritmo non sfrutta i nomi di vie che 
sono parte di percorsi sovracomunali (es. una strada statale che prende nomi diversi nei vari tratti in 
cui attraversa i diversi centri urbani), questo perché in tali casi ad oggi l'unica denominazione 
importata da Open Street Map è quella della strada sovracomunale, mentre le denominazioni dei segmenti 
vanno perse. E' già pronta una modifica agli script di triplificazione di OSM che, aggiungendo a ciascun
elemento stradale una proprietà con la denominazione della strada in quel tratto, permette di portare in 
KB anche questa informazione, e pertanto di poterla poi utilizzare tra l'altro anche per le riconciliazioni. 
Tuttavia, ad oggi la modifica non è stata integrata negli script di triplificazione committati, e men che meno
tali triple aggiuntive sono pertanto disponibili per alcuna provincia, nell'attesa di un riscontro da parte di 
Piero.

------------
Further Info
------------

Per maggiori informazioni, si può fare riferimento al capitolo "Riconciliazione 
del grafo stradale della RT con quello di OSM" del documento 
"Mappatura OSM KM4C v1.0" e successive, memorizzato nella cartella doc.

MS 26/06/2017
updated 2018-05-25