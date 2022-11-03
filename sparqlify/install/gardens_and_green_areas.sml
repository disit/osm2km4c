/* OSM2KM4C
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
   along with this program.  If not, see <http://www.gnu.org/licenses/>. */
   
Prefix km4c:<http://www.disit.org/km4city/schema#>
Prefix dct:<http://purl.org/dc/terms/>
Prefix foaf:<http://xmlns.com/foaf/0.1/>
Prefix geo:<http://www.w3.org/2003/01/geo/wgs84_pos#>
Prefix fn:<http://aksw.org/sparqlify/>
Prefix rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
Prefix rdfs:<http://www.w3.org/2000/01/rdf-schema#>
Prefix schema:<http://schema.org/>
Prefix geosparql:<http://www.opengis.net/ont/geosparql#>

/******* Gardens and Green Areas ***************************/

Create View GardensFromNodes As
Construct {
Graph ?graph_uri {
	?garden a km4c:Gardens ;
		dct:identifier ?garden_id ;
		schema:name ?garden_name ;
		geo:lat ?garden_lat;
		geo:long ?garden_long
		
}}
With
?graph_uri = uri(?graph_uri)
?garden = uri(concat("http://www.disit.org/km4city/resource/", ?garden_id))
?garden_id = plainLiteral(?garden_id)
?garden_name = plainLiteral(?garden_name)
?garden_long = typedLiteral(?garden_long, "http://www.w3.org/2001/XMLSchema#float")
?garden_lat = typedLiteral(?garden_lat, "http://www.w3.org/2001/XMLSchema#float")

From [[
select * from gardens_from_nodes
]]

Create View GardensFromWays As
Construct {
Graph ?graph_uri {
	?garden a km4c:Gardens ;
		dct:identifier ?garden_id ;
		schema:name ?garden_name ;
		geo:lat ?garden_lat;
		geo:long ?garden_long;
		geosparql:hasGeometry ?garden_geometry. 
	?garden_geometry a geosparql:Geometry;
		dct:identifier ?garden_geometry_id;		
		geosparql:asWKT ?garden_geom		
}}
With
?graph_uri = uri(?graph_uri)
?garden = uri(concat("http://www.disit.org/km4city/resource/", ?garden_id))
?garden_geometry = uri(concat("http://www.disit.org/km4city/resource/", ?garden_geometry_id))
?garden_id = plainLiteral(?garden_id)
?garden_geometry_id = plainLiteral(?garden_geometry_id)
?garden_name = plainLiteral(?garden_name)
?garden_geom = typedLiteral(?garden_geom, "http://www.opengis.net/ont/geosparql#wktLiteral")
?garden_long = typedLiteral(?garden_long, "http://www.w3.org/2001/XMLSchema#float")
?garden_lat = typedLiteral(?garden_lat, "http://www.w3.org/2001/XMLSchema#float")
From [[
select *, garden_id || '/geom' as garden_geometry_id from gardens_from_ways
]]

Create View GardensFromRelations As
Construct {
Graph ?graph_uri {
	?garden a km4c:Gardens ;
		dct:identifier ?garden_id ;
		schema:name ?garden_name ;
		geo:lat ?garden_lat;
		geo:long ?garden_long;		
		geosparql:hasGeometry ?garden_geometry. 
	?garden_geometry a geosparql:Geometry;
		dct:identifier ?garden_geometry_id;		
		geosparql:asWKT ?garden_geom	
}}
With
?graph_uri = uri(?graph_uri)
?garden = uri(concat("http://www.disit.org/km4city/resource/", ?garden_id))
?garden_id = plainLiteral(?garden_id)
?garden_name = plainLiteral(?garden_name)
?garden_geom = typedLiteral(?garden_geom, "http://www.opengis.net/ont/geosparql#wktLiteral")
?garden_long = typedLiteral(?garden_long, "http://www.w3.org/2001/XMLSchema#float")
?garden_lat = typedLiteral(?garden_lat, "http://www.w3.org/2001/XMLSchema#float")
?garden_geometry = uri(concat("http://www.disit.org/km4city/resource/", ?garden_geometry_id))
?garden_geometry_id = plainLiteral(?garden_geometry_id)
From [[
select *, garden_id || '/geom' as garden_geometry_id from gardens_from_relations
]]


Create View GreenAreasFromNodes As
Construct {
Graph ?graph_uri {
	?green_area a km4c:Green_areas ;
		dct:identifier ?green_area_id ;
		schema:name ?green_area_name ;
		geo:lat ?green_area_lat;
		geo:long ?green_area_long
		
}}
With
?graph_uri = uri(?graph_uri)
?green_area = uri(concat("http://www.disit.org/km4city/resource/", ?green_area_id))
?green_area_id = plainLiteral(?green_area_id)
?green_area_name = plainLiteral(?green_area_name)
?green_area_long = typedLiteral(?green_area_long, "http://www.w3.org/2001/XMLSchema#float")
?green_area_lat = typedLiteral(?green_area_lat, "http://www.w3.org/2001/XMLSchema#float")

From [[
select * from green_areas_from_nodes
]]

Create View GreenAreasFromWays As
Construct {
Graph ?graph_uri {
	?green_area a km4c:Green_areas ;
		dct:identifier ?green_area_id ;
		schema:name ?green_area_name ;
		geo:lat ?green_area_lat;
		geo:long ?green_area_long;
		geosparql:hasGeometry ?green_area_geometry. 
	?green_area_geometry a geosparql:Geometry;
		dct:identifier ?green_area_geometry_id;		
		geosparql:asWKT ?green_area_geom	
		
}}
With
?graph_uri = uri(?graph_uri)
?green_area = uri(concat("http://www.disit.org/km4city/resource/", ?green_area_id))
?green_area_id = plainLiteral(?green_area_id)
?green_area_name = plainLiteral(?green_area_name)
?green_area_geom = typedLiteral(?green_area_geom, "http://www.opengis.net/ont/geosparql#wktLiteral")
?green_area_long = typedLiteral(?green_area_long, "http://www.w3.org/2001/XMLSchema#float")
?green_area_lat = typedLiteral(?green_area_lat, "http://www.w3.org/2001/XMLSchema#float")
?green_area_geometry = uri(concat("http://www.disit.org/km4city/resource/", ?green_area_geometry_id))
?green_area_geometry_id = plainLiteral(?green_area_geometry_id)
From [[
select *, green_area_id || '/geom' as green_area_geometry_id from green_areas_from_ways
]]

Create View GreenAreasFromRelations As
Construct {
Graph ?graph_uri {
	?green_area a km4c:Green_areas ;
		dct:identifier ?green_area_id ;
		schema:name ?green_area_name ;
		geo:lat ?green_area_lat;
		geo:long ?green_area_long;
		geosparql:hasGeometry ?green_area_geometry. 
	?green_area_geometry a geosparql:Geometry;
		dct:identifier ?green_area_geometry_id;		
		geosparql:asWKT ?green_area_geom	
		
}}
With
?graph_uri = uri(?graph_uri)
?green_area = uri(concat("http://www.disit.org/km4city/resource/", ?green_area_id))
?green_area_id = plainLiteral(?green_area_id)
?green_area_name = plainLiteral(?green_area_name)
?green_area_geom = typedLiteral(?green_area_geom, "http://www.opengis.net/ont/geosparql#wktLiteral")
?green_area_long = typedLiteral(?green_area_long, "http://www.w3.org/2001/XMLSchema#float")
?green_area_lat = typedLiteral(?green_area_lat, "http://www.w3.org/2001/XMLSchema#float")
?green_area_geometry = uri(concat("http://www.disit.org/km4city/resource/", ?green_area_geometry_id))
?green_area_geometry_id = plainLiteral(?green_area_geometry_id)
From [[
select *, green_area_id || '/geom' as green_area_geometry_id from green_areas_from_relations
]]

