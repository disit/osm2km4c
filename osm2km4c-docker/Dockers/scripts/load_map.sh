#!/bin/sh

#DB_USER="admin"
#DB_PASSWORD="admin"
#DB_NAME="maps"
osmosis="/osm2km4c/tools/osmosis/bin/osmosis"

OSM_ID=$1
RELATION_NAME=$2
MAP_TYPE=$3
BBOX_LEFT=$6
BBOX_RIGHT=$7
BBOX_TOP=$5
BBOX_BOTTOM=$4

# Creazione o rimozione della mappa se già presente
if [ ! -d /osm2km4c/maps/$OSM_ID ]; then
    mkdir /osm2km4c/maps/$OSM_ID
else
    rm -r /osm2km4c/maps/$OSM_ID
    mkdir /osm2km4c/maps/$OSM_ID
fi

cp /osm2km4c/scripts/pgsimple_load_0.6.sql /osm2km4c/maps/$OSM_ID ||
  { echo "Error while copying /osm2km4c/scripts/pgsimple_load_0.6.sql in /osm2km4c/maps/$OSM_ID"; exit 1; }


# Si esegue il dump dei dati della mappa in file .txt
# Se la mappa è fornita dall'utente (pbf) prima di eseguire il dump viene eseguito un filtro sull'bbox di interesse
echo OSM2KM4C START LOAD_MAP $(date -Is)
if [ $MAP_TYPE = "osm" ]; then
    $osmosis --read-xml  /osm2km4c/maps/$OSM_ID.osm --log-progress --write-pgsimp-dump directory=/osm2km4c/maps/$OSM_ID/ enableBboxBuilder=yes enableLinestringBuilder=yes ||
  { echo "Error while loading /osm2km4c/maps/$OSM_ID.osm with osmosis"; exit 1; } 
elif [ $MAP_TYPE = "pbf" ]; then
    # Filtriamo la mappa in base al bbox di interesse
    $osmosis --read-pbf /osm2km4c/maps/$RELATION_NAME.osm.pbf --bounding-box left=$BBOX_LEFT right=$BBOX_RIGHT top=$BBOX_TOP bottom=$BBOX_BOTTOM --log-progress --write-pgsimp-dump directory=/osm2km4c/maps/$OSM_ID/ enableBboxBuilder=yes enableLinestringBuilder=yes ||
  { echo "Error while loading di /osm2km4c/maps/$RELATION_NAME.osm.pbf with osmosis"; exit 1; } 
else
   { echo "Invalid map type $MAP_TYPE"; exit 1; } 
fi

echo OSM2KM4C LOAD_MAP pgsimple_load $(date -Is)
# Si effettua il caricamento dei dump sul database e l'ottimizzazione
cd /osm2km4c/maps/$OSM_ID/
psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/maps/$OSM_ID/pgsimple_load_0.6.sql ||
  { echo "Error while running /osm2km4c/maps/$OSM_ID/pgsimple_load_0.6.sql on db"; exit 1; } 

echo OSM2KM4C LOAD_MAP performance optimization $(date -Is)
cd /osm2km4c/scripts/
psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/scripts/performance_optimization.sql -v OSM_ID=$OSM_ID ||
  { echo "Error while running /osm2km4c/scripts/performance_optimization.sql on db"; exit 1; } 

echo OSM2KM4C END LOAD_MAP $(date -Is)
