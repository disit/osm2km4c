FROM node:latest
WORKDIR /snap4osm
RUN apt-get update
RUN apt-get install postgresql-client -y

COPY . .
RUN npm install

ENTRYPOINT [ "sleep", "inf" ]
