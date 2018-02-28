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

Allo stesso livello di questo file readme sono collocati gli script sparql che contengono
le query che devono essere eseguite ai diversi passi dell'algoritmo, eventualmente da 
personalizzare variando le denominazioni dei grafi. 

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

Per maggiori informazioni, si può fare riferimento al capitolo "Riconciliazione 
del grafo stradale della RT con quello di OSM" del documento 
"Mappatura OSM KM4C v1.0" e successive, memorizzato nella cartella doc.

MS 26/06/2017
