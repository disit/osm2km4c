#!/bin/sh

#DB_USER="admin"
#DB_NAME="maps"
#DB_PASSWORD="admin"

echo OSM2KM4C START INIT $(date -Is)

# Scarichiamo osmosis se non è presente
if [ ! -d /osm2km4c/tools/osmosis ]; then
    mkdir -p /osm2km4c/tools/osmosis
    wget -P /osm2km4c/tools/osmosis https://github.com/openstreetmap/osmosis/releases/download/0.48.3/osmosis-0.48.3.tgz 
    tar xvfz /osm2km4c/tools/osmosis/osmosis-0.48.3.tgz -C /osm2km4c/tools/osmosis
    rm /osm2km4c/tools/osmosis/osmosis-0.48.3.tgz
    chmod a+x /osm2km4c/tools/osmosis/bin/osmosis      
fi
# Estraiamo sparqlify se non è presente
if [ ! -d /osm2km4c/tools/sparqlify ]; then
    unzip /osm2km4c/tools/sparqlify.zip -d /osm2km4c/tools/ ||
  { echo "Error while extracting /osm2km4c/scripts/sparqlify.zip in /osm2km4c/tools/"; exit 1; }
fi

chmod -R 777 /osm2km4c/scripts/
chmod -R 777 /osm2km4c/maps/

# Le seguente query creano un nuovo database (maps) e lo inizializzano per il caricamento della mappa con osmosis
psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/postgres -c "DROP DATABASE IF EXISTS $DB_NAME;" ||
  { echo "Error while running psql command: Dropping the db $DB_NAME"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/postgres -c "CREATE DATABASE $DB_NAME;" ||
  { echo "Error while running psql command: Creating the db $DB_NAME"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -c "CREATE EXTENSION postgis; CREATE EXTENSION hstore;" ||
  { echo "Error while running psql command: Creating extensions postgis and hstore"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/tools/osmosis/script/pgsimple_schema_0.6.sql ||
  { echo "Error while running psql command: import pgsimple schema"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/tools/osmosis/script/pgsimple_schema_0.6_action.sql ||
  { echo "Error while running psql command: import pgsimple schema action"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/tools/osmosis/script/pgsimple_schema_0.6_bbox.sql ||
  { echo "Error while running psql command: import pgsimple schema bounding box"; exit 1; }

psql postgresql://$DB_USER:$DB_PASSWORD@postgres:5432/$DB_NAME -f /osm2km4c/tools/osmosis/script/pgsimple_schema_0.6_linestring.sql ||
  { echo "Error while running psql command: import pgsimple schema linestring"; exit 1; }

echo OSM2KM4C END INIT $(date -Is)

exit 0
