REM  OSM2KM4C
REM  Copyright (C) 2017 DISIT Lab http://www.disit.org - University of Florence
REM
REM  This program is free software: you can redistribute it and/or modify
REM  it under the terms of the GNU Affero General Public License as
REM  published by the Free Software Foundation, either version 3 of the
REM  License, or (at your option) any later version.
REM
REM  This program is distributed in the hope that it will be useful,
REM  but WITHOUT ANY WARRANTY; without even the implied warranty of
REM  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM  GNU Affero General Public License for more details.
REM 
REM You should have received a copy of the GNU Affero General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>. 
   
REM INIZIALIZZAZIONE
REM ----------------

REM Creo il named graph dove andrò ad inserire tutte le triple di riconciliazione tra i due grafi
REM isql è uno strumento command-line incluso in Virtuoso. 

isql 1111 dba dba "EXEC=SPARQL CREATE GRAPH <http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto>"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM RICONCILIAZIONE DELLE PROVINCE
REM ------------------------------

REM Genero le triple di riconciliazione delle province e le memorizzo su di un file locale in posizione visibile da Virtuoso
REM Opportune misure devono essere adottate per garantire che le librerie esterne necessarie siano disponibili e visibili

java -jar rt2osm.jar -h 192.168.0.207 -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto" -og "urn:km4city:OSM:test:grosseto" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto" -w counties -o "C:\Program Files\virtuoso-opensource\database\GR_counties.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_counties.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Carico su Virtuoso le triple generate al passo precedente

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_counties.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM RICONCILIAZIONE DEI COMUNI
REM PUO' ESSERE ESEGUITA ANCHE SENZA AVER PREVENTIVAMENTE RICONCILIATO LE PROVINCE
REM ------------------------------------------------------------------------------

REM Genero le triple di riconciliazione dei comuni e le memorizzo su di un file locale in posizione visibile da Virtuoso
REM Opportune misure devono essere adottate per garantire che le librerie esterne necessarie siano disponibili e visibili

java -jar rt2osm.jar -h 192.168.0.207 -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto" -og "urn:km4city:OSM:test:grosseto" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto" -w municipalities -o "C:\Program Files\virtuoso-opensource\database\GR_municipalities.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_municipalities.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Carico su Virtuoso le triple generate al passo precedente

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_municipalities.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM RICONCILIAZIONE DEI TOPONIMI PER UN COMUNE IN PARTICOLARE, QUELLO DI GROSSETO
REM NEL CASO SI DEBBANO RICONCILIARE I TOPONIMI DELL'INTERA PROVINCIA, SI RIPETERA' QUANTO FATTO PER GROSSETO, ANCHE PER GLI ALTRI COMUNI
REM PUO' ESSERE ESEGUITA ANCHE SENZA AVER PREVENTIVAMENTE RICONCILIATO I COMUNI
REM -------------------------------------------------------------------------------------------------------------------------------------

REM Creo il grafo RDF in cui andrò ad inserire le triple del grafo ottimizzato per il Comune di Grosseto estratto dal grafo della Regione Toscana

isql 1111 dba dba "EXEC=SPARQL CREATE GRAPH <http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT>"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Genero il grafo stradale ottimizzato per il Comune di Grosseto partendo dal grafo stradale della Regione Toscana e lo memorizzo in locale

java -jar rt2osm.jar -h 192.168.0.207 -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT" -w optimize-rt -m GROSSETO -o "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_RT_opt.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_RT_opt.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Carico le triple generate al passo precedente, nel grafo opportuno

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_Grosseto_RT_opt.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Creo il grafo RDF in cui andrò ad inserire le triple del grafo ottimizzato per il Comune di Grosseto estratto dal grafo di Open Street Map

isql 1111 dba dba "EXEC=SPARQL CREATE GRAPH <http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM>"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Genero il grafo stradale ottimizzato per il Comune di Grosseto partendo dal grafo stradale della Regione Toscana e lo memorizzo in locale

java -jar rt2osm.jar -h 192.168.0.207 -p 1111 -u dba -P dba -og "urn:km4city:OSM:test:grosseto" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM" -w optimize-osm -m Grosseto -o "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_OSM_opt.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_OSM_opt.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Carico le triple generate al passo precedente, nel grafo opportuno

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_Grosseto_OSM_opt.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Getto il seme per la riconciliazione dei toponimi sul Comune di Grosseto

java -jar rt2osm.jar -h localhost -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT" -og "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto" -w roads-seed -o "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_roads_seed.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_roads_seed.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Carico le triple generate al passo precedente, nel grafo opportuno

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_Grosseto_roads_seed.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM Ripeto più volte lo step di riconciliazione dei toponimi per il Comune di Grosseto, sfruttando ogni volta le corrispondenze stabilite all'iterazione 
REM precedente, finché non arrivo ad un punto in cui non riesco più a stabilire nuove corrispondenze

:grosseto

java -jar rt2osm.jar -h localhost -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT" -og "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto" -w roads-step -o "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_roads_step.n3" 

if not errorlevel 0 ( goto fine_grosseto )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_roads_step.n3" ( goto fine_grosseto )

timeout 5

if not errorlevel 0 ( exit /B 1 )

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_Grosseto_roads_step.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

del "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_roads_step.n3"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

GOTO grosseto

:fine_grosseto

REM RICONCILIAZIONE DEGLI ELEMENTI STRADALI
REM DEVE ESSERE ESEGUITA DOPO AVER RICONCILIATO I TOPONIMI
----------------------------------------------------------

java -jar rt2osm.jar -h localhost -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT" -og "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto" -w elements-step1 -o "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_elements_step1.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_elements_step1.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_Grosseto_elements_step1.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

java -jar rt2osm.jar -h localhost -p 1111 -u dba -P dba -rg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT" -og "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM" -tg "http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto" -w elements-step2 -o "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_elements_step2.n3" 

if not errorlevel 0 ( exit /B 1 )

if not exist "C:\Program Files\virtuoso-opensource\database\GR_Grosseto_elements_step2.n3" ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

isql 1111 dba dba "EXEC=log_enable(2); DB.DBA.TTLP(file_to_string_output ('C:\\Program Files\\virtuoso-opensource\\database\\GR_Grosseto_elements_step2.n3'), '', 'http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/urn:km4city:OSM:test:grosseto')"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM SVUOTAMENTO DEI GRAFI TEMPORANEI NECESSARI PER LA RICONCILIAZIONE DEI TOPONIMI E DEGLI ELEMENTI STRADALI
REM --------------------------------------------------------------------------------------------------------

isql 1111 dba dba "EXEC=SPARQL CLEAR GRAPH <http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/RT>"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

isql 1111 dba dba "EXEC=SPARQL CLEAR GRAPH <http://www.disit.org/km4city/resource/GrafoStradale/Grafo_stradale_Grosseto/RT2OSM/Temporary/OSM>"

if not errorlevel 0 ( exit /B 1 )

timeout 5

if not errorlevel 0 ( exit /B 1 )

REM SE DEL CASO RIPETO LA RICONCILIAZIONE DEI TOPONIMI E DEGLI ELEMENTI STRADALI PER ALTRI COMUNI
REM ---------------------------------------------------------------------------------------------


