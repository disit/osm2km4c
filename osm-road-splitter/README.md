# Progetto OSM per snap4city

Il progetto consiste nello sdoppiamento delle strade bidirezionali in due strade inverse a senso unico, da essere poi inserite nella Knowledge Base. Inoltre vengono corrette eventuali rotatorie che non hanno il tag oneway impostato che sono presenti sul database.  I dati di partenza sono presi da un database Postgres con l’architettura di OSM, e inseriti in un secondo database con la medesima architettura che deve essere un clone del db di partenza.

Il progetto è stato sviluppato in Javascript con l’ausilio di Node.js, che è richiesto per il funzionamento di questo programma. 

## Fasi
Il programma è composto da nove fasi tutte espresse nel file index.js.

Le prime due fasi si occupano di ottenere e unire i dati necessari dal database, evitando di fare questo processo direttamente dal DBMS stesso per ottenere prestazioni migliori con dataset di grandi dimensioni.

La terza fase crea una struttura dati facile da manipolare. 

La quarta ottiene le rotonde e le rimuove dal processo di sdoppiamento. 

La quinta crea le nuove strade invertendo i nodi. 

La sesta, settima e ottava gestisce la parte delle relazioni comi tag, restrizioni, etc. 

Infine la nona serve per aggiornare il database o per creare il file SQL a seconda della configurazione.


## Esecuzione 

Per eseguire il codice è necessario avere installato Node.js e di installare le relative dipendenze con

    npm install

Per eseguire il codice con i parametri di default è sufficente eseguirlo con 

    node ./src/index.js

### Parametri

    node --max-old-space-size=8192 ./src/index.js -t 8 -p 2

- -t --treads: numero di thread per le elaborazioni in parallelo
- -p --phase: fase da dove ripartire (devono essere presenti i dati ellaborati nella fase precedente nella cartella "data")
- --max-old-space-size=[MB] parametro per aumentare la memoria che puo essere allocata con node.js, utile nel caso si debba elaborare un dataset di grandi dimensioni.

## Configurazioni

È presente anche un file di configurazione chiamato config.yml dove vengono configurate le connessini per il database iniziale e finale.

    initialDatabase:
        host: 192.168.230.128
        database: openstreetmap
        port: 54321
        username: openstreetmap
        password: openstreetmap

    destinationType: 'db' # 'db' | 'sql'
    # se è stato scelto sql verrà creato un output.sql nella directory ./out
    # e le opzioni destinationDatabase verrano ignorate
    # attenzione il db osm_splitted deve essere già presente ed essere un clone del db openstreetmap
    destinationDatabase:
        host: 192.168.230.128
        database: osm_final
        port: 54321
        username: openstreetmap
        password: openstreetmap

    savePhasesResult: true
