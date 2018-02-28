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

Il materiale contenuto in questa cartella si inserisce nell'ambito del problema di mappare un punto arbitrario (caratterizzato da latitudine e longitudine) su di un'entità OSM.

Si tratta di un archivio WAR da deployare su Tomcat o similare, che contiene una servlet denominata Latlon2Osm, che si invoca inviando in ingresso i parametri:
> lat (obbligatorio, latitudine del punto di interesse)
> lon (obbligatorio, longitudine del punto di interesse)
> type (opzionale, default=node, si veda sotto per maggiori dettagli)
> restrictions (opzionale, default=0, si veda sotto per maggiori dettagli) 

La servlet restituisce:
per type=region, l'ID OSM della relation che rappresenta la regione in cui il punto si trova
per type=county, l'ID OSM della relation che rappresenta la provincia in cui il punto si trova
per type=municipality, l'ID OSM della relation che rappresenta il comune in cui il punto si trova
per type=way, l'ID OSM della way più vicina al punto di interesse
per type=node, l'ID OSM del nodo più vicino al punto di interesse, scelto tra quelli appartenenti alla way più vicina al punto di interesse

Nel caso in cui il parametro restrictions sia valorizzato a 1, non vengono presi in considerazione per la riconciliazione i percorsi (e quindi anche i nodi) che non possono essere raggiunti a piedi.

La servlet è stata originariamente sviluppata con l'obiettivo di mappare le fermate degli autobus, che sono georeferenziate ma hanno una posizione che in generale non coincide esattamente con quella di alcun nodo del grafo stradale, sui nodi del grafo stradale, perché questo è un passaggio fondamentale per l'integrazione delle fermate degli autobus all'interno dell'algoritmo di calcolo del percorso. 

CONFIGURAZIONE

Un parametro di inizializzazione inserito nel Web.xml contiene il percorso del file .properties, relativo alla home utente (System.getProperty("user.home")).

Il file .properties contiene i parametri per il collegamento al database Postgres, che sono gli unici parametri necessari per il funzionamento della servlet.

Un esempio di file properties è contenuto nel WAR, all'interno della cartella dei sorgenti Java: src\java\org\disit\latlon2osnode\Latlon2Osm.properties

URL DI ESEMPIO

http://192.168.0.207:8080/latlon2osnode/Latlon2Osm?lat=43.7317&lon=11.0206

ULTERIORI INFORMAZIONI

Informazioni su questo problema e sulla sua implementazione sono anche disponibili nel documento "Mappatura OSM KM4C v0.6" e successivi.

MS, 05/12/2017