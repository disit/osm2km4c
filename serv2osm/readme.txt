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

Il materiale contenuto in questa cartella si inquadra nell'ambito del problema di 
attribuire a ciascuno dei servizi (ed altri elementi georeferenziati) di KM4C, 
una posizione all'interno del grafo stradale generato tramite importazione da OSM.

Attribuire una posizione significa valorizzare la proprietà km4c:isInRoad con 
la URI dell'istanza di km4c:Road che rappresenta il toponimo su cui il servizio 
si trova, ed inoltre la proprietà km4c:hasAccess con la URI dell'istanza di
 km4c:Entry che rappresenta (idealmente) la porta di accesso al locale ove è 
fornito il servizio. 

L'archivio serv2osm.jar contenuto nella sottocartella dist assieme alle necessarie librerie esterne, rappresenta lo stato dell'arte dell'implementazione di tale riconciliazione. Si tratta di un tool che si esegue da riga di comando, la cui usage guide può essere ottenuta invocandolo senza fornire alcun parametro in ingresso. 

Il rimanente contenuto di questa cartella, è l'estrazione dell'archivio ZIP del progetto esportato da Netbeans.

Per ulteriori informazioni si può fare riferimento al documento "Mappatura OSM KM4C v0.5" nella cartella doc del repository SVN "osm_ingestion". 

MS, 27/09/2017
