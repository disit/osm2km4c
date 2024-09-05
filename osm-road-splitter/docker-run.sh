docker run -it --rm -v $(pwd):/snap4osm node:latest /bin/bash -c "cd snap4osm; npm install; ./run.sh $@"
