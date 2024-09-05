#!/bin/sh

#VIRTUOSO_PSW="admin"
#VIRTUOSO_HOST=virtuoso

echo OSM2KM4C START LOAD_TO_VIRTUOSO $VIRTUOSO_HOST $(date -Is)

RELATION_NAME=$1
GRAPH_NAME=$2

# Controlliamo se il grafo contiene già delle triple
GRAPH_EXISTS=$(echo "SPARQL ASK { GRAPH <$GRAPH_NAME> { ?s ?p ?o } };" | isql-vt -H $VIRTUOSO_HOST -P $VIRTUOSO_PSW) 
GRAPH_EXISTS=$(echo $GRAPH_EXISTS | grep -oP 'ask_retval INTEGER _*?\K ([10])')


if [ "$GRAPH_EXISTS" -eq 1 ];
    then
        # Il grafo contiene già delle triple,le eliminiamo 
        echo "\nELIMINAZIONE TRIPLE DA VECCHIO GRAFO $GRAPH_NAME\n"
        echo "SPARQL CLEAR GRAPH <$GRAPH_NAME>;" | isql-vt isql-vt -H $VIRTUOSO_HOST -P $VIRTUOSO_PSW
    fi

# Rimuoviamo il file dalla load list per ricaricarlo
echo "DELETE FROM DB.DBA.LOAD_LIST WHERE ll_file='osm/$RELATION_NAME/$RELATION_NAME.n3';" | isql-vt isql-vt -H $VIRTUOSO_HOST -P $VIRTUOSO_PSW

echo "\n\nCARICAMENTO TRIPLE DA FILE : $RELATION_NAME.n3 NEL GRAFO : $GRAPH_NAME\n"

# Si effettua il caricamento delle triple sul grafo
echo "ld_dir('osm/$RELATION_NAME', '$RELATION_NAME.n3', '$GRAPH_NAME');" | isql-vt isql-vt -H $VIRTUOSO_HOST -P $VIRTUOSO_PSW
echo "rdf_loader_run();" | isql-vt isql-vt -H $VIRTUOSO_HOST -P $VIRTUOSO_PSW

echo OSM2KM4C END LOAD_TO_VIRTUOSO $(date -Is)

