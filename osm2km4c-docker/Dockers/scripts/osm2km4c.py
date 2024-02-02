#!/usr/bin/env python3

# Es di run 
# python3 triplification.py -r montemignaio -l http://example.org/test1
import argparse
import requests
import os
import shutil
import subprocess
import pathlib
import time
import sys

def parse_arguments():
    parser = argparse.ArgumentParser(prog="osm2km4c",
                                 description="Generates .n3 triples of an extract from Open Street Map, triples can be loaded on virtuoso rdf store",
                                 formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument("-f", "--file_name",
                        help="Copy the map as .pbf file in /osm2km4c/maps/",
                        nargs=1,
                        type=str)
    
    parser.add_argument("-r", "--relation_name",
                        help="Give the name of a relation to be downloaded from OSM, to choose a specific osm_id use --osm_id.",
                        nargs=1,
                        type=str)
    
    parser.add_argument("-o", "--osm_id",
                        help="Give the OSM_ID of the relation to be processed. \n\
    If FILE_NAME is not specified the map will be downloaded from overpass.",
                        nargs=1,
                        type=str)
    
    parser.add_argument("-l", "--load_to_rdf",
                        metavar="GRAPH_NAME",
                        help="Uploads the generated triples on virtuoso rdf store into the specified graph name (e.g. urn:osm:city)",
                        nargs=1,
                        type=str)
    
    parser.add_argument("--generate_old",
                        action="store_true",
                        help="Generate the triples for the old format (including all intermediate road elements)")

    args = parser.parse_args()


    if not (args.relation_name or args.osm_id):
        parser.error("No action to do, specify RELATION_NAME or OSM_ID or filename")
    elif args.relation_name and args.osm_id:
        parser.error("RELATION_NAME and OSM_ID specified, provide only one of the two options")

    return vars(args)
    
def get_relation_data_by_name(relation_name):
    json = requests.get(f"https://nominatim.openstreetmap.org/search.php?q={relation_name}&format=json").json()
    #filtro per estrarre la relazione
    print("for", relation_name,"found:")
    for osm_element in json:
        if (osm_element["osm_type"] == "relation" and osm_element["class"] == "boundary"):
            print("  ", osm_element["osm_id"], ":", osm_element["display_name"])
    print()
    for osm_element in json:
        if (osm_element["osm_type"] == "relation" and osm_element["class"] == "boundary"):
            relation_data = osm_element
            print("loading:", osm_element["osm_id"], osm_element["display_name"],"\n")
            return relation_data

def get_relation_data_by_osmid(osm_id):
    response = requests.get(f"https://nominatim.openstreetmap.org/lookup?osm_ids=R{osm_id}&format=json").json()
    relation_data = response[0]
    if relation_data["osm_type"] != "relation":
        print(f"Error osm_id : {osm_id} is not a relation")
        exit(-1)
    elif relation_data["class"] != "boundary":
        print(f"Error osm_id : {osm_id} is not a boundary")
        exit(-1)

    return relation_data
    

def download_map(osm_id, bbox):
   
    boundingbox = bbox
    for coord_idx in range(4):
        boundingbox[coord_idx] = float(boundingbox[coord_idx])
    
    #verifico che non esistano già dati relativi a questa relazione
    if os.path.exists(f"/osm2km4c/maps/{osm_id}.osm"):
        print(f"{osm_id}.osm already exists, map will be not downloaded")
        return osm_id


    query=(f"[out:xml];"
           f"(node({boundingbox[0]},{boundingbox[2]},{boundingbox[1]},{boundingbox[3]});"
           f"way({boundingbox[0]},{boundingbox[2]},{boundingbox[1]},{boundingbox[3]});"
           f"relation({boundingbox[0]},{boundingbox[2]},{boundingbox[1]},{boundingbox[3]});"
           f"<;);out%20center%20meta;")
    
    print(f"Downloading {osm_id} from open-street-map, wait...")
    
    with open(f"/osm2km4c/maps/{osm_id}.osm", "wb+") as f:
        map_data = requests.get(f"http://overpass-api.de/api/interpreter?data={query}", stream=True)
        for data in map_data.iter_content(1024):
            f.write(data)

    print("Map downloaded")

# def execute_shell_command(command, log_output=None, handle_exit_number=False):

#     if handle_exit_number==False:
#         process = subprocess.Popen(command, stdout=subprocess.PIPE)
#     else:
#         process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
#     while process.poll() is None:
#         while True:
#             line = process.stdout.readline()
#             if not line: break
#             if log_output != None:
#                 log_output.append(line.decode())
#             else:
#                 print(line.decode())

#     if process.returncode != 0 and handle_exit_number:
#         print(f"Errore durante l'esecuzione del comando: {command}. Codice di uscita: {process.returncode}")
#         sys.exit(1)

def execute_shell_command(command, log_output=None, handle_exit_number=False):
    process = subprocess.Popen(command, stdout=subprocess.PIPE,stderr=subprocess.STDOUT, universal_newlines=True)
    while True:
        output = process.stdout.readline()
        print(output.strip(), flush=True)
        # Do something else
        return_code = process.poll()
        if return_code is not None:
            # Process has finished, read rest of the output 
            for output in process.stdout.readlines():
                print(output.strip(), flush=True)
            break
    if return_code != 0 and handle_exit_number:
        print(f"Error while executing: {command}. Error code: {return_code}")
        sys.exit(1)

#BASE_DIR = pathlib.Path(__file__).parent.resolve()

def main():
    # Recupero delle opzioni con il parsing
    args = parse_arguments()
    relation_name = None
    file_name = args["file_name"]
    generate_old = args["generate_old"]
    graph_name = None
    osm_id = args["osm_id"]
    map_type = None
    bbox = [0, 0, 0, 0]
    

    if args["load_to_rdf"] != None:
        graph_name = args["load_to_rdf"][0]

    if args["relation_name"] != None:
        relation_name = args["relation_name"][0]

    # Recupero della bbox della mappa tramite osm_id o relation_name, 
    # nel secondo caso viene dedotto anche l'osm_id basandosi sulla relazione più importante con quel nome
    if relation_name != None:
        relation_data = get_relation_data_by_name(relation_name)
        osm_id = relation_data["osm_id"]
    elif osm_id != None:
        osm_id = osm_id[0]
        relation_data = get_relation_data_by_osmid(osm_id)
    bbox = relation_data["boundingbox"]

    # Se file_name è specificato si verifica che la mappa esista
    if file_name != None:
        file_name = file_name[0]
        map_type = "pbf"

        if not os.path.exists(f"/osm2km4c/maps/{file_name}"):
            print(f"File /osm2km4c/maps/{file_name} not found")
            exit(-1)
    # Se non è specificato file_name la mappa viene scaricata automaticamente
    else:
        download_map(osm_id, bbox)
        file_name = f"{osm_id}.osm"
        map_type = "osm"

    # Avviamo i container e attendiamo che postgres sia inizializzato e pronto a ricevere connessioni
    inizialization_postgres = False
    os.chdir(f"/osm2km4c/maps")

    # timeout = -1
    # ready_to_accept_conn = False
    # while not ready_to_accept_conn:
    #     time.sleep(1)
    #     timeout += 1
    #     if (timeout > 60):
    #         print("Errore container postgres non è pronto a ricevere connessioni. (TIMEOUT: 60 s)")
    #         return    
        
    #     isReady = []
    #     execute_shell_command(["pg_isready" ], log_output=isReady)
    #     for line in isReady:
    #         if line.find("accepting connections") != -1:
    #             if(inizialization_postgres):
    #                 print("Inizializzazione di postgress")
    #                 time.sleep(40)
    #                 inizialization_postgres = False   
    #             print("Container postgress avviato correttamente")
    #             ready_to_accept_conn = True
    #             break
    
    # Effettuiamo l'inizializazione del database su postgres rendendolo pronto a ricevere i dati postgis
    execute_shell_command(["bash", "-c", "/osm2km4c/scripts/init.sh"], handle_exit_number=True)
    # Effettuiamo il load della mappa e l'ottimizzazione del db
    file_name_cleaned = file_name.split(".")[0]
    execute_shell_command(["bash", "-c", f"/osm2km4c/scripts/load_map.sh {osm_id} {file_name_cleaned} {map_type} {float(bbox[0])} {float(bbox[1])} {float(bbox[2])} {float(bbox[3])}"], handle_exit_number=True)
    # Eseguiamo una serie di query sul db e la triplificazione 
    execute_shell_command(["bash", "-c", f"/osm2km4c/scripts/irdbcmap.sh {osm_id} {file_name_cleaned} {generate_old}"], handle_exit_number=True)

    # Se è specificato un grafo , le triple verrano caricate direttamente su di esso nel container con virtuoso rdf store
    if graph_name != None:
        path_in_virtuoso = f"/osm2km4c/virtuoso-osm/{osm_id}" 
        if os.path.exists(path_in_virtuoso):
            for triple in os.listdir(path_in_virtuoso):
                os.remove(path_in_virtuoso + "/" + triple)
            os.rmdir(path_in_virtuoso)
        old = ""
        if (generate_old):
            old = "_old"
        os.mkdir(path_in_virtuoso)
        shutil.copy2(f"/osm2km4c/maps/{osm_id}/{osm_id}{old}.n3", path_in_virtuoso + f"/{osm_id}.n3")
        execute_shell_command(["sh", "-c", f"/osm2km4c/scripts/load_to_virtuoso.sh {osm_id} {graph_name}"])

if __name__ == "__main__":
    main()
