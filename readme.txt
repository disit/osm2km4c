OSM2KM4C
Copyright (C) 2017 DISIT Lab http://www.disit.org - University of Florence

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>. 

------------
-- README --
------------

An outline is provided here of the tools that can be found in this folder.

busstops2osm 
------------

Pentaho ETL jobs and transformations that get geolocated public transport stops stored in HBase as input, and map each stop to the nearest street node retrieved from the Open Street Map through the latlon2osnode tool, producing in output a CSV and a N-Triples file.

doc
---

A comprehensive /italian/ documentation about everything that can be found in this folder, and more.

latlon2osnode
-------------

Java Web Application that accepts in input the geospatial coordinates of a point, and returns the Open Street Map ID of the region, province, municipality, street, or street node, that is the nearest to the given point. The user indicates what he wishes to get, through the /type/ argument.

rt2osm
------

Command-line Java tool that implements an algorithm that identifies the correspondences between two different representations of the Tuscany street graph, both stored in a graph database.

rthousenum
----------

Generation of a Open Street Change file that contains OSM nodes each representing a housenumber imported from the Open Data of the Tuscany Region, reading from a MySql database. This way our /local/ instance of the Open Street Map can be integrated.

serv2osm
--------

A command-line Java tool that reads a set of geolocated services from a graph database and identifies the road and the entrance door that are the nearest to the service. Roads and entrance doors are stored in the graph database too. The correspondences are represented as N-Triples.

sparqlify
---------

Triplification of extracts of the Open Street Map: Open Street Map data is loaded to a PostgreSQL database, transformed through appropriate SQL scripts, and represented as N-Triples or N-Quads through the Sparqlify. See also the quick-install-and-usage-guide.txt in the sparqlify folder.