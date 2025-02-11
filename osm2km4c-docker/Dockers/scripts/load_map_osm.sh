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
APIDB_HOST=$8
APIDB_DATABASE=$9
APIDB_USER=${10}
APIDB_PWD=${11}

DBNAME=osm

# Si esegue il dump dei dati della mappa in file .txt
# Se la mappa è fornita dall'utente (pbf) prima di eseguire il dump viene eseguito un filtro sull'bbox di interesse
echo OSM2KM4C START LOAD_MAP OSM $(date -Is)
if [ $MAP_TYPE = "osm" ]; then
    $osmosis --read-xml  /osm2km4c/maps/$OSM_ID.osm --log-progress --write-apidb host="$APIDB_HOST" database=$APIDB_DATABASE user=$APIDB_USER password=$APIDB_PWD validateSchemaVersion=no ||
  { echo "Error while loading /osm2km4c/maps/$OSM_ID.osm with osmosis"; exit 1; } 
elif [ $MAP_TYPE = "pbf" ]; then
    # Filtriamo la mappa in base al bbox di interesse
    $osmosis --read-pbf /osm2km4c/maps/$RELATION_NAME.osm.pbf --bounding-box left=$BBOX_LEFT right=$BBOX_RIGHT top=$BBOX_TOP bottom=$BBOX_BOTTOM clipIncompleteEntities=true --log-progress  --write-apidb host="$APIDB_HOST" database=$APIDB_DATABASE user=$APIDB_USER password=$APIDB_PWD validateSchemaVersion=no ||
  { echo "Error while loading di /osm2km4c/maps/$RELATION_NAME.osm.pbf with osmosis"; exit 1; } 
else
   { echo "Invalid map type $MAP_TYPE"; exit 1; } 
fi

echo OSM2KM4C END LOAD_MAP OSM $(date -Is)
