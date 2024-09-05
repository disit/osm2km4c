#!/bin/sh

#DB_USER="admin"
#DB_PASSWORD="admin"
#DB_NAME="maps"

OSM_ID=$1
RELATION_NAME=$2
GENERATE_OLD=$3

echo OSM2KM4C START IRDBCMAP $(date -Is) OSM_ID: $OSM_ID RELATION_NAME: $RELATION_NAME
# Generazione delle triple senza semplificazione se l'utente l'ha richiesto
if [ $GENERATE_OLD = "True" ]; then
  psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME  -f /osm2km4c/scripts/irdbcmap_old.sql -v OSM_ID=$OSM_ID -v ON_ERROR_STOP=1 ||
    { echo "Error while executing /osm2km4c/scripts/irdbcmap_old.sql on db"; exit 1; } 

  echo OSM2KM4C IRDBCMAP sparqlify $(date -Is)
  /osm2km4c/scripts/sparqlify.sh -m /osm2km4c/scripts/irdbcmap.sml -h postgres -d $DB_NAME -U $DB_USER -W $DB_PASSWORD -o ntriples --dump > /osm2km4c/maps/$OSM_ID/"$OSM_ID"_old.drt ||
    { echo "Error while executing /osm2km4c/scripts/sparqlify.sh"; exit 1; } 
  cd /osm2km4c/maps/$OSM_ID/

  #echo OSM2KM4C IRDBCMAP clean1 $(date -Is)
  #tail -n +3 "$OSM_ID"_old.drt > "$OSM_ID"_old.cln 
  echo OSM2KM4C IRDBCMAP clean $(date -Is)
  sort "$OSM_ID"_old.drt | uniq > "$OSM_ID"_old.n3 
  rm "$OSM_ID"_old.drt

else

  # Generazione delle triple con semplificazione
  psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME  -f /osm2km4c/scripts/irdbcmap.sql -v OSM_ID=$OSM_ID -v ON_ERROR_STOP=1 ||
    { echo "Error while executing /osm2km4c/scripts/irdbcmap.sql on db"; exit 1; } 

  echo OSM2KM4C IRDBCMAP sparqlify $(date -Is)
  /osm2km4c/scripts/sparqlify.sh -m /osm2km4c/scripts/irdbcmap.sml -h postgres -d $DB_NAME -U $DB_USER -W $DB_PASSWORD -o ntriples --dump > /osm2km4c/maps/$OSM_ID/$OSM_ID.drt ||
    { echo "Error executing /osm2km4c/scripts/sparqlify.sh"; exit 1; } 
  cd /osm2km4c/maps/$OSM_ID/

  #echo OSM2KM4C IRDBCMAP clean1 $(date -Is)
  #tail -n +3 $OSM_ID.drt > $OSM_ID.cln 

  echo OSM2KM4C IRDBCMAP clean $(date -Is)
  sort $OSM_ID.drt | uniq > $OSM_ID.n3 
  rm $OSM_ID.drt

fi

echo OSM2KM4C END IRDBCMAP $(date -Is)
