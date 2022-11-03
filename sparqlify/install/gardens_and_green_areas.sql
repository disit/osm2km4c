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
   
-- CONFIGURAZIONE DELL'INSTALLAZIONE
------------------------------------

-- Delimitazione geografica dell'installazione

drop table if exists extra_config_boundaries; 

create table extra_config_boundaries as 
select * from extra_all_boundaries where relation_id in (59518);

create index extra_config_boundaries_index_1 on extra_config_boundaries using gist(boundary);

create index extra_config_boundaries_index_2 on extra_config_boundaries using gist(bbox);

create index extra_config_boundaries_index_3 on extra_config_boundaries using gist(centroid);

-- Grafo

drop table if exists extra_config_graph ;

create table extra_config_graph (
id serial primary key,
graph_uri varchar(255)
);

insert into extra_config_graph(graph_uri) values ('http://www.disit.org/km4city/resource/Services/mypoi'); 

-- Utilizzo dei numeri civici della Regione Toscana piuttosto che nativi di OSM

drop table if exists extra_config_civic_num ;

create table extra_config_civic_num (
id serial primary key,
civic_num_source varchar(255)
);

-- insert into extra_config_civic_num(civic_num_source) values ('Regione Toscana'); -- decommentare questa riga per utilizzare i numeri civici della Regione Toscana
insert into extra_config_civic_num(civic_num_source) values ('Open Street Map'); -- decommentare questa riga per utilizzare i numeri civici nativi di Open Street Map

-- GARDENS AND GREEN AREAS
--------------------------

-- Gardens from Nodes

drop table if exists gardens_from_nodes;

create table gardens_from_nodes as
select graph_uri, n.id node_id, 'OS' || lpad(n.id::text,11,'0') || 'GN' garden_id, ST_X(n.geom) garden_long, ST_Y(n.geom) garden_lat, nn.v as garden_name
from nodes n
join node_tags l on n.id = l.node_id and l.k = 'leisure' and l.v = 'garden'
join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, n.geom)
left join node_tags nn on n.id = nn.node_id and nn.k = 'name'
join extra_config_graph cfg on 1=1;

update gardens_from_nodes
set garden_name = garden_names.garden_name
from (
	select g.node_id, d.v as garden_name from gardens_from_nodes g join node_tags d on g.node_id = d.node_id and d.k = 'description' where g.garden_name is null
) garden_names
where garden_names.node_id = gardens_from_nodes.node_id;

update gardens_from_nodes
set garden_name = garden_names.garden_name
from (
	select g.node_id, 'Unnamed Garden' as garden_name from gardens_from_nodes g where g.garden_name is null
) garden_names
where garden_names.node_id = gardens_from_nodes.node_id;

-- Gardens from Ways

drop table if exists gardens_from_ways;

create table gardens_from_ways as
select graph_uri, w.id way_id, 'OS' || lpad(w.id::text,11,'0') || 'GW' garden_id, ST_AsText((ST_Dump(ST_Polygonize(w.linestring))).geom) garden_geom, ST_X(ST_Centroid((ST_Dump(ST_Polygonize(w.linestring))).geom)) garden_long, ST_Y(ST_Centroid((ST_Dump(ST_Polygonize(w.linestring))).geom)) garden_lat, wn.v as garden_name
from ways w
join way_tags l on w.id = l.way_id and l.k = 'leisure' and l.v = 'garden'
join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, w.linestring)
left join way_tags wn on w.id = wn.way_id and wn.k = 'name'
join extra_config_graph cfg on 1=1
group by graph_uri, w.id, wn.v
;

update gardens_from_ways 
set garden_name = garden_names.garden_name
from (
	select gw.way_id, rt.v garden_name from gardens_from_ways gw join relation_members rm on gw.way_id = rm.member_id join relation_tags rt on rt.relation_id = rm.relation_id and rt.k = 'name' where gw.garden_name is null
) garden_names
where garden_names.way_id = gardens_from_ways.way_id;

update gardens_from_ways
set garden_name = garden_names.garden_name
from (
	select g.way_id, 'Unnamed Garden' as garden_name from gardens_from_ways g where g.garden_name is null
) garden_names
where garden_names.way_id = gardens_from_ways.way_id;

-- Gardens from Relations

drop table if exists gardens_from_relations;

create table gardens_from_relations as
select graph_uri, relation_id, garden_id, ST_AsText((ST_Dump(ST_Polygonize(garden_geom))).geom) garden_geom, ST_X(ST_Centroid((ST_Dump(ST_Polygonize(garden_geom))).geom)) garden_long, ST_Y(ST_Centroid((ST_Dump(ST_Polygonize(garden_geom))).geom)) garden_lat, garden_name 
from (
select graph_uri, relation_id, 'OS' || lpad(relation_id::text,11,'0') || 'GR' garden_id, (ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom garden_geom, (ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom garden_long, (ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom garden_lat, garden_name from ( 
	select graph_uri, relation_members.relation_id, ways.linestring, tag_name.v garden_name
	from relation_members 
	join ways on ways.id = relation_members.member_id and relation_members.member_type='W' and relation_members.member_role = 'outer'
	join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, ways.linestring)
	join relation_tags tag_leisure on relation_members.relation_id = tag_leisure.relation_id and tag_leisure.k = 'leisure' and tag_leisure.v = 'garden'
	join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'multipolygon'
	left join relation_tags tag_name on relation_members.relation_id = tag_name.relation_id and tag_name.k = 'name' 
	join extra_config_graph cfg on 1=1
 ) sub group by graph_uri, relation_id, garden_name
 ) foo group by graph_uri, relation_id, garden_id, garden_name ;
 
update gardens_from_relations
set garden_name = garden_names.garden_name
from (
	select g.relation_id, 'Unnamed Garden' as garden_name from gardens_from_relations g where g.garden_name is null
) garden_names
where garden_names.relation_id = gardens_from_relations.relation_id;

-- Green Areas from Nodes

drop table if exists green_areas_from_nodes;

create table green_areas_from_nodes as
select graph_uri, n.id node_id, 'OS' || lpad(n.id::text,11,'0') || 'GAN' green_area_id, ST_X(n.geom) green_area_long, ST_Y(n.geom) green_area_lat, nn.v as green_area_name
from nodes n
left join node_tags l on n.id = l.node_id and l.k = 'leisure' and l.v in ('dog_park','firepit','nature_reserve','park','playground')
left join node_tags lu on n.id = lu.node_id and lu.k = 'landuse' and lu.v in ('village_green','grass')
join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, n.geom)
left join node_tags nn on n.id = nn.node_id and nn.k = 'name'
join extra_config_graph cfg on 1=1
where l.node_id is not null or lu.node_id is not null;

update green_areas_from_nodes
set green_area_name = green_area_names.green_area_name
from (
	select g.node_id, d.v as green_area_name from green_areas_from_nodes g join node_tags d on g.node_id = d.node_id and d.k = 'description' where g.green_area_name is null
) green_area_names
where green_area_names.node_id = green_areas_from_nodes.node_id;

update green_areas_from_nodes
set green_area_name = green_area_names.green_area_name
from (
	select g.node_id, 'Unnamed Green Area' as green_area_name from green_areas_from_nodes g where g.green_area_name is null
) green_area_names
where green_area_names.node_id = green_areas_from_nodes.node_id;

-- Green Areas from Ways

drop table if exists green_areas_from_ways;

create table green_areas_from_ways as
select graph_uri, w.id way_id, 'OS' || lpad(w.id::text,11,'0') || 'GAW' green_area_id, ST_AsText((ST_Dump(ST_Polygonize(w.linestring))).geom) green_area_geom, ST_X(ST_Centroid((ST_Dump(ST_Polygonize(w.linestring))).geom)) green_area_long, ST_Y(ST_Centroid((ST_Dump(ST_Polygonize(w.linestring))).geom)) green_area_lat, wn.v as green_area_name
from ways w
left join way_tags l on w.id = l.way_id and l.k = 'leisure' and l.v in ('dog_park','firepit','nature_reserve','park','playground')
left join way_tags lu on w.id = lu.way_id and lu.k = 'landuse' and lu.v in ('village_green','grass')
join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, w.linestring)
left join way_tags wn on w.id = wn.way_id and wn.k = 'name'
join extra_config_graph cfg on 1=1
where l.way_id is not null or lu.way_id is not null
group by graph_uri, w.id, wn.v;

update green_areas_from_ways 
set green_area_name = green_area_names.green_area_name
from (
	select gw.way_id, rt.v green_area_name from green_areas_from_ways gw join relation_members rm on gw.way_id = rm.member_id join relation_tags rt on rt.relation_id = rm.relation_id and rt.k = 'name' where gw.green_area_name is null
) green_area_names
where green_area_names.way_id = green_areas_from_ways.way_id;

update green_areas_from_ways
set green_area_name = green_area_names.green_area_name
from (
	select g.way_id, 'Unnamed Green Area' as green_area_name from green_areas_from_ways g where g.green_area_name is null
) green_area_names
where green_area_names.way_id = green_areas_from_ways.way_id;

-- Green Areas from Relations

drop table if exists green_areas_from_relations;

create table green_areas_from_relations as
select graph_uri, relation_id, green_area_id, ST_AsText((ST_Dump(ST_Polygonize(green_area_geom))).geom) green_area_geom, ST_X(ST_Centroid((ST_Dump(ST_Polygonize(green_area_geom))).geom)) green_area_long, ST_Y(ST_Centroid((ST_Dump(ST_Polygonize(green_area_geom))).geom)) green_area_lat, green_area_name 
from (
select graph_uri, relation_id, 'OS' || lpad(relation_id::text,11,'0') || 'GAR' green_area_id, (ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom green_area_geom, (ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom green_area_long, (ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom green_area_lat, green_area_name from ( 
	select graph_uri, relation_members.relation_id, ways.linestring, tag_name.v green_area_name
	from relation_members 
	join ways on ways.id = relation_members.member_id and relation_members.member_type='W' and relation_members.member_role = 'outer'
	join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, ways.linestring)
	left join relation_tags l on relation_members.relation_id = l.relation_id and l.k = 'leisure' and l.v in ('dog_park','firepit','nature_reserve','park','playground')
	left join relation_tags lu on relation_members.relation_id = lu.relation_id and lu.k = 'landuse' and lu.v in ('village_green','grass')
	join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'multipolygon'
	left join relation_tags tag_name on relation_members.relation_id = tag_name.relation_id and tag_name.k = 'name' 	
	join extra_config_graph cfg on 1=1
	where l.relation_id is not null or lu.relation_id is not null
 ) sub group by graph_uri, relation_id, green_area_name
 ) foo group by graph_uri, relation_id, green_area_id, green_area_name ;
 
update green_areas_from_relations
set green_area_name = green_area_names.green_area_name
from (
	select g.relation_id, 'Unnamed Green Area' as green_area_name from green_areas_from_relations g where g.green_area_name is null
) green_area_names
where green_area_names.relation_id = green_areas_from_relations.relation_id;