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

Il materiale contenuto in questa cartella si inquadra nell'ambito del problema 
di generare il grafo stradale per aree geografiche al di fuori della Toscana (e a temdere anche per la Toscana sostituendo l'attuale grafo stradale),
 importando i dati dalle mappe stradali di Open Street Map, e popolando con
tali dati il database RDF di Km4City conformemente alla Smart City Ontology.

In particolare il materiale contenuto direttamente sotto sparqlify è:
> irdbcmap.cfg.sql, script di configurazione che deve essere personalizzato ed eseguito sul database relazionale su cui si trova il database di tipo simple popolato da osmosis, come passo iniziale della generazione delle triple RDF
> irdbcmap.sql, script che genera tabelle ad-hoc finalizzate alla generazione delle triple RDF del grafo stradaole, aggiuntive rispetto a quelle generate da osmosis, ma sullo stesso database su cui si trovano le tabelle popolate da osmosis. L'esecuzione di questo script costituisce il secondo passo dell'iter di generazione delle triple RDF del grafo stradale a partire dalle mappe stradali OSM
> irdbcmap.sml, script di configurazione di Sparqlify, che è lo strumento in uso per la traduzione effettiva dei dati contenuti nel database relazionale, in triple RDF (alternativa a Karma).
Questi file sono:
> stabili
> OBSOLETI: non comprendono la generazione delle triple per le Regioni, e non comprendono la generazione delle triple per le piazze pedonali che non siano circondate da strade denominate su OSM con lo stesso nome della piazza. Quindi, si perdono delle piazze, con conseguenti numeri civici, riconciliazioni di servizi, e quant'altro collegato. Si perde inoltre quant'altro sia stato aggiunto successivamente rispetto a quanto indicato, e si perdono in particolare tutti gli accorgimenti che sono stati adottati nel tempo per ridurre il tempo di esecuzione della triplificazione. 

Invece, il materiale contenuto nella sottocartella install è:
> irdbcmap.sql, script SQL da eseguire sullo stesso database relazionale su cui si trovano le tabelle popolate da osmosis, che include sia una parte di configurazione iniziale che deve essere personalizzata prima di lanciare lo script, sia una parte di generazione di tabelle ad-hoc finalizzate all'esportazione della mappa OSM sotto forma di triple RDF. L'esecuzione di questo script è il primo step dell'iter che consente la generazione di triple RDF per nuovi territori, per i quali cioè debba essere generato l'intero grafo stradale
> irdbcmap.sml, script di configurazione di Sparqlify, che è lo strumento in uso per la traduzione effettiva dei dati contenuti nel database relazionale, in triple RDF (alternativa a Karma)
Questi file sono:
> più giovani quindi meno esercitati
> allo stato dell'arte: comprendono sia la generazione delle istanze delle Regioni con tutte le varie proprietà, sia la generazione delle triple per le piazze pedonali, sia quant'altro sia stato introdotto successivamente, e comprendono in particolare tutto il set di accorgimenti che hanno permesso di ridurre drasticamente i tempi di esecuzione della triplificazione.

Infine, il materiale contenuto nella sottocartella update deve essere utilizzato nel caso in cui si debbano generare le triple relative ad una specifica proprietà di una specifica classe. Sono quindi utili nel caso in cui si sia già esportato e caricato su Virtuoso il grafo stradale di un certo territorio, e si debba procedere all'aggiornamento o all'integrazione di uno specifico aspetto. La sottocartella update contiene in particolare un insieme di sottocartelle, una per ciascuna classe della Smart City Ontology inerente il grafo stradale, e poi per ciascuna di tali classi, ulteriori sottocartelle, una per ciascuna proprietà della classe. In queste ultime sottocartelle si trovano uno script SQL che deve essere personalizzato nella parte iniziale di configurazione, ed eseguito sullo stesso database su cui si trovano le tabelle popolate da osmosis. Dopo aver eseguito lo script SQL, si deve eseguire Sparqlify configurato utilizzando il documento di configurazione che si trova affiancato allo script SQL. In questo modo si genereranno le sole triple che valorizzano la specifica proprietà della specifica classe. In taluni casi la parzializzazione è stata arrestata al livello della classe senza scendere al livello della singola proprietà, questo in particolare nei casi in cui l'aggiornamento di una proprietà isolata porterebbe a inconsistenze o non avrebbe comunque senso agli effetti pratici.

Per ulteriori informazioni si può fare riferimento al documento "Mappatura OSM KM4C" nelle 
sue diverse versioni. L'ultima versione rilasciata al momento in cui aggiorna questo README è la 1.3. 

MS 12/07/2017 
