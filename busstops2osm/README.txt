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
along with this program.  If not, see <http://www.gnu.org/licenses/>. */

README 
------

Il materiale contenuto in questa cartella si riferisce al problema di rappresentare la mappatura delle paline delle fermate degli autobus (ciascuna dotata di coordinate geospaziali) sui nodi (elementi Node) delle mappe stradali di Open Street Map, che appartengano ad un percorso stradale, scegliendo in particolare il nodo più vicino alla palina, sotto la condizione che lo stesso possa essere raggiunto da un pedone. La ricerca è quindi ristretta ai soli nodi che appartengano a ways (elementi Way di OSM) che siano strade (taggate direttamente come highway) o che siano membri di Relation di OSM che rappresentano strade, e non siano taggati in modo tale da indicare l'impossibilità per i pedoni di raggiungerli. Maggiori dettagli sul documento "Mappatura OSM KM4C" nella cartella "doc" di questo stesso repository (osm_ingestion).

Attenzione: RAPPRESENTARE LA MAPPATURA, non mappare. Infatti, il problema di individuare il nodo più vicino secondo i criteri sopra descritti, è risolto attraverso l'implementazione di una servlet a cui si inviano le coordinate geospaziali, e da cui si ottiene l'ID OSM dell'elemento Node che rappresenta il nodo più vicino alla palina che possegga le necessarie caratteristiche. Il file war che implementa questa servlet ed altro materiale eventualmente collegato fanno parte di un task separato da questo, e si trovano nella cartella latlon2osnode di questo stesso repository.

Invece, questo task consiste nel rappresentare questo legame, ed in particolare consiste nell'implementazione di parti di ETL che, sfruttando i servizi offerti dalla servlet di cui sopra, vanno a generare:
> un file CSV, in cui per ciascuna riga si trovano due soli valori, che sono l'identificativo univoco della palina, e l'ID OSM del nodo su cui è mappata;
> un set di triple RDF, in cui per ciascuna palina, si va a valorizzare la proprietà http://xmlns.com/foaf/0.1/based_near con la URI del nodo a cui la palina è associata.

La riconciliazione è stata progettata per essere eseguita in due fasi:
1. una fase di inizializzazione, in cui si riconciliano tutte le paline note al mese di dicembre 2017 per tutte le diverse compagnie di trasporti, senza integrare i job responsabili della riconciliazione all'interno del flusso complessivo di ingestion delle paline, questo perché siccome la riconciliazione di migliaia di paline richiede tempi molto lunghi, integrare fin da subito la funzionalità all'interno dell'ETL complessivo avrebbe portato a tempi di esecuzione lunghissimi per l'ETL complessivo, che è invece pensato per eseguire un rapido aggiornamento a regime di dati che sono stati già importati;
2. una gase di funzionamento a regime, in cui le funzionalità di riconciliazione sono integrate nell'ETL complessivo ed eseguono la riconciliazione delle nuove paline che dovessero di man a mano emergere.

La fase di inizializzazione è stata completata nel mese di dicembre 2017, ed i job e trasformazioni di ETL utilizzati si trovano nelle sottocartelle Init_Ingestion e Init_Triplification. 

La fase di funzionamento a regime è per il momento soltanto abbozzata, ed è descritta in una mail inviata a Piero e alla Michela, che riporto qui di seguito nelle parti maggiormente significative. 

INGESTION DELLA RICONCILIAZIONE DELLE PALINE TPLBUS CON I NODI OSM: INTEGRAZIONE NELL'ETL COMPLETO 

In /media/Trasformazioni/Trasformazioni SVILUPPO, ho creato la cartella TrasformazioneTPLBus_new_model, dove ho avviato lo sviluppo dell'integrazione della riconciliazione delle paline del TPL con i nodi OSM. Ho modificato, in sviluppo, un solo job tra quelli pre-esistenti: il job Download_Bus.kjb, nella parte di Ingestion, in cui subito dopo lo stage HBase_Stops_Insert ho inserito lo stage Stops2OSM. Gli altri elementi necessari per la riconciliazione sono tutti di nuova creazione, e sono il job Stops2OSM.kjb e le due trasformazioni che vi si trovano all'interno, la CSVH.ktr e la Stops2OSM.ktr, anch'essi tutti contenuti in /media/Trasformazioni/Trasformazioni SVILUPPO/TrasformazioneTPLBus_new_model/Ingestion. Non ho lanciato niente.

Per il momento, nella trasformazione Stops2OSM.ktr ho assunto che fosse stato introdotto un nuovo parametro di configurazione nel config.txt, che potremmo chiamare STOP2OSMURL o qualcosa di simile, destinato a contenere l'URL del servizio Web che viene invocato per ottenere il nodo OSM più vicino data una coppia di coordinate, e che la trasformazione /media/Trasformazioni/getConfig.ktr fosse stata modificata così da valorizzare la variabile STOP2OSMURL con tale parametro. Tuttavia, la parte di configurazione non l'ho toccata, né il file, né la trasformazione, quindi se lanciassimo in questo momento, non funzionerebbe sicuramente. Da decidere se vogliamo modificare effettivamente la parte di configurazione, o se vogliamo modificare la nuova trasformazione inserendo l'URL hard-coded invece di leggerlo dalla variabile.

TRIPLIFICAZIONE DELLA RICONCILIAZIONE DELLE PALINE TPLBUS CON I NODI OSM: INTEGRAZIONE NELL'ETL COMPLETO

Per l'integrazione della parte di produzione delle triple, analogamente alla ingestion, in sviluppo (cartella /media/Trasformazioni/Trasformazioni SVILUPPO/TrasformazioneTPLBus_new_model/Triplification), ho modificato il Main_Bus.kjb aggiungendo dopo lo stage Stops Triplification, il nuovo stage Stops2OSM Triplification, ed ho introdotto il nuovo job Stops2OSM.kjb (stesso nome del job di ingestion ma cartelle diverse) e la nuova trasformazione Stops2OSM_ToSQL.ktr. Due dubbi. Primo: i modelli avevamo concordato di inserirli in una cartella Models, sottocartella di Triplification. Guardando però il comando Linux che esegue la triplificazione, va a prendere il modello in /media/Triples_RT/Models/. Per il momento ho messo il nuovo modello, TransferServiceAndRenting__basedNear__Node.ttl, sia in /media/Trasformazioni/Trasformazioni SVILUPPO/TrasformazioneTPLBus_new_model/Triplification/Models che in /media/Triples_RT/Models/. Secondo: fino ad oggi ho sempre utilizzato la connessione local72 per andare sul database Mysql, che era l'unica funzionante nel momento in cui ho iniziato gli sviluppi che sono terminati oggi con l'esecuzione delle ultime tra le riconciliazioni iniziali. Vedo però che per le altre triplificazioni (es. quella delle Stop, Shape, etc.) viene usata la connectionParam, per cui per il momento ho allineato e nella trasformazione Stops2OSM_ToSQL.ktr integrata in sviluppo utilizzo anch'io la connectionParam. Sono intercambiabili? Anche questi sviluppi per integrare la parte di triplification sono tutti da provare, non ho lanciato niente.

I job e le trasformazioni il cui sviluppo è stato abbozzato per l'integrazione della riconciliazione a regime si trovano nelle cartelle Regime_Ingestion e Regime_Triplification.

Informazioni sono disponibili inoltre nel documento "Mappatura OSM KM4C v0.8" e successive. 

MS, 18/12/2017
