#!/bin/sh
DB_NAME=openstreetmap
#DB_NAME="maps"
#DB_PASSWORD="admin"

echo OSM2KM4C START INITOSM $(date -Is)

# Le seguente query creano un nuovo database (maps) e lo inizializzano per il caricamento della mappa con osmosis
psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/postgres -c "DROP DATABASE IF EXISTS $DB_NAME;" ||
  { echo "Error while running psql command: Dropping the db $DB_NAME"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/postgres -c "CREATE DATABASE $DB_NAME;" ||
  { echo "Error while running psql command: Creating the db $DB_NAME"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;" ||
  { echo "Error while running psql command: Creating extensions postgis and hstore"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/scripts/structure.sql ||
  { echo "Error while running psql command: import structure schema"; exit 1; }

echo OSM2KM4C END INITOSM $(date -Is)

exit 0
