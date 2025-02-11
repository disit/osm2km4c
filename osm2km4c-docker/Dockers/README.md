# osm2kmc docker version
How to run:
- do `docker compose up -d` to start
- to run the script do `docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py --help`
```
usage: osm2km4c [-h] [-f FILE_NAME] [-r RELATION_NAME] [-d DB] [-o OSM_ID] [-l GRAPH_NAME] [--generate_old]

Generates .n3 triples of an extract from Open Street Map, triples can be loaded on virtuoso rdf store

options:
  -h, --help            show this help message and exit
  -f FILE_NAME, --file_name FILE_NAME
                        Copy the map as .osm.pbf file in /osm2km4c/maps/
  -r RELATION_NAME, --relation_name RELATION_NAME
                        Give the name of a relation to be downloaded from OSM, to choose a specific osm_id use --osm_id.
  -d DB, --db DB        Give the ip:port,db,user,password of the server
  -o OSM_ID, --osm_id OSM_ID
                        Give the OSM_ID of the relation to be processed.
                            If FILE_NAME is not specified the map will be downloaded from overpass.
  -l GRAPH_NAME, --load_to_rdf GRAPH_NAME
                        Uploads the generated triples on virtuoso rdf store into the specified graph name (e.g. urn:osm:city)
  --generate_old        Generate the triples for the old format (including all intermediate road elements)
```

The triples are generated in the `maps/<osm_id>/<osm_id>.n3` file (always use --generate_old option, the new version is not fully supported by snap4city)

## Example 1 (from boudary name)

`docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py -r Firenze -l urn:osm:firenze --generate_old`

It automatically searches for a boundary relation with name "Firenze" and downloads the .osm file, it then processes the data and uploads the generated triples on the local virtuoso instance (processing takes a long time).

## Example 2 (from pbf file)

If you have a pbf file put it in the maps directory as .osm.pbf (e.g. firenze.osm.pbf), you need to identify on OSM the osm_id of a relation that describes the boundary (for Florence it is 42602, see it on https://www.openstreetmap.org/relation/42602)

`docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py -f firenze.osm.pbf -o 42602 -l urn:osm:firenze --generate_old`

## Example 3 (from a live osm instance via apidb)

If you want to get the map from a live osm instance accessible via apidb (postgres db) you have to do:

`docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py -db <hostname>:5432,openstreetmap,openstreetmap,openstreetmap -o 42602 -l urn:osm:firenze --generate_old`

## Example 4 (split a live osm instance to a splitted db)

If you want to split all the double way roads into two one-way roads, you should set the appropriate values for the env vars of the osm-road-splitter container than do:

`docker compose exec osm-road-splitter bash -c "cd /snap4osm; ./clone-db.sh && ./run.sh" `

It makes a clone of the db and then it performs the split by modifying the cloned db. Then to generate the triples for this splitted db you should use apidb access:

`docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py -db <hostname>:5432,openstreetmap_splitted,openstreetmap,openstreetmap -o 42602 -l urn:osm:firenze-splitted --generate_old`




