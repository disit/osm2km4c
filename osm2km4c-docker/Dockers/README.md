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

The triples are generated in the maps/<osmid>/<osmid>.n3 (always use --generate_old option, the new version is not fully supported by snap4city)

## Example 1

`docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py -r Firenze -l urn:osm:firenze --generate_old`

It automatically searches for a boundary relation and downloads the .osm file of "Firenze", processes it and uploads the triples on the local virtuoso instance.

## Example 2

If you have a pbf file put it in the maps directory as .osm.pbf (e.g. firenze.osm.pbf), you need to identify on OSM the osm_id of a relation that describes the boundary (for Florence it is 42602, see it on https://www.openstreetmap.org/relation/42602)

`docker compose exec osm2km4c /osm2km4c/scripts/osm2km4c.py -f firenze.osm.pbf -o 42602 -l urn:osm:firenze --generate_old`
