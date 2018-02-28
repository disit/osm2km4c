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
select * from extra_all_boundaries where relation_id in (276369);

create index extra_config_boundaries_index_1 on extra_config_boundaries using gist(boundary);

create index extra_config_boundaries_index_2 on extra_config_boundaries using gist(bbox);

create index extra_config_boundaries_index_3 on extra_config_boundaries using gist(centroid);

-- Grafo

drop table if exists extra_config_graph ;

create table extra_config_graph (
id serial primary key,
graph_uri varchar(255)
);

insert into extra_config_graph(graph_uri) values ('http://www.disit.org/km4city/graph/OSM/CA'); 

-- Utilizzo dei numeri civici della Regione Toscana piuttosto che nativi di OSM

drop table if exists extra_config_civic_num ;

create table extra_config_civic_num (
id serial primary key,
civic_num_source varchar(255)
);

-- insert into extra_config_civic_num(civic_num_source) values ('Regione Toscana'); -- decommentare questa riga per utilizzare i numeri civici della Regione Toscana
insert into extra_config_civic_num(civic_num_source) values ('Open Street Map'); -- decommentare questa riga per utilizzare i numeri civici nativi di Open Street Map

/********************************************
************ TABELLE DI APPOGGIO ************
*********************************************/

-- Esplosione delle way

drop table if exists extra_ways;

create table extra_ways as
select prev_waynode.way_id global_id, prev_waynode.sequence_id local_id, prev_node.geom start_node, next_node.geom end_node, prev_node.id prev_node_id, next_node.id next_node_id
from way_nodes prev_waynode 
join nodes prev_node on prev_waynode.node_id = prev_node.id
join way_nodes next_waynode on prev_waynode.way_id = next_waynode.way_id and prev_waynode.sequence_id = next_waynode.sequence_id-1
join nodes next_node on next_waynode.node_id = next_node.id
join way_tags on prev_waynode.way_id = way_tags.way_id and way_tags.k = 'highway' and way_tags.v <> 'proposed'
join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, next_node.geom);

create index on extra_ways (global_id);

create index on extra_ways using gist(start_node);

create index on extra_ways using gist(end_node);

-- Comuni di interesse

drop table if exists extra_comuni;

create table extra_comuni as
select relations.id relation_id, extra_all_boundaries.centroid, extra_all_boundaries.boundary boundary, extra_all_boundaries.bbox bbox
from relations 
join relation_tags tag_type on relations.id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relations.id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relations.id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '8' 
-- join relation_tags catasto on relations.id = catasto.relation_id and catasto.k = 'ref:catasto' -- taglio sugli italiani
join extra_all_boundaries on relations.id = extra_all_boundaries.relation_id
join extra_config_boundaries on ST_Covers(extra_config_boundaries.boundary, extra_all_boundaries.boundary);

create index extra_comuni_index_1 on extra_comuni using gist(centroid);

create index extra_comuni_index_2 on extra_comuni using gist(boundary);

create index extra_comuni_index_3 on extra_comuni using gist(bbox);

-- Numeri civici ed accessi senza strada (indirizzo di tipo place)

drop table if exists extra_node_housenumber_without_street;

create table extra_node_housenumber_without_street as
select nodes.*, housenumber.v housenumber, place.v place 
from nodes
join node_tags housenumber on nodes.id = housenumber.node_id and housenumber.k = 'addr:housenumber';
join node_tags place on nodes.id = place.node_id and place.k = 'addr:place';
join extra_config_boundaries on ST_Covers(boundary, nodes.geom)

create index on extra_node_housenumber_without_street(id);
create index on extra_node_housenumber_without_street using gist(geom);

drop table if exists extra_node_motorcycle;

create table extra_node_motorcycle as
select id 
from extra_node_city 
join node_tags on id = node_id and k = 'motorcycle' and v = 'yes';

create index on extra_node_motorcycle(id);

drop table if exists extra_node_motorcar;

create table extra_node_motorcar as
select id 
from extra_node_city 
join node_tags on id = node_id and k = 'motorcar' and v = 'yes';

create index on extra_node_motorcar(id);

drop table if exists extra_civicnum_municipalities;

create table extra_civicnum_municipalities as
select cast(extra_comuni.relation_id as varchar(20)) relation_id,  'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' id, relation_tags.v m_name, extra_comuni.boundary geom
from extra_comuni
join relation_tags on extra_comuni.relation_id = relation_tags.relation_id and relation_tags.k = 'name' ;

create index on extra_civicnum_municipalities using gist(geom);
create index on extra_civicnum_municipalities(relation_id);

drop table if exists extra_streetnumbers_on_nodes_without_street;

create table extra_streetnumbers_on_nodes_without_street as
select distinct 'OS' || lpad(node_address.id::text,11,'0') || 'NN' cn_id, 
       node_address.housenumber extend_number,
       substring(node_address.housenumber FROM '[0-9]+') number,
       substring(node_address.housenumber FROM '[a-zA-Z]+') exponent,
node_address.place place, 
CASE 
WHEN municipalities.m_name = any ('{Firenze,Genova,Savona}') and node_address.housenumber ilike '%r%' THEN 'Rosso'
WHEN municipalities.m_name = any ('{Firenze,Genova,Savona}') and not node_address.housenumber ilike '%r%' THEN 'Nero'
ELSE 'Privo colore'
END as class_code,
'OS' || lpad(node_address.id::text,11,'0') || 'NE' en_id,  
'Accesso esterno diretto' entry_type,
ST_X(node_address.geom) long,
ST_Y(node_address.geom) lat,
CASE WHEN motorcycle.id is not null or motorcar.id is not null THEN 'Accesso carrabile' ELSE 'Accesso non carrabile' END as porte_cochere, 
'Open Street Map' node_source
from extra_node_housenumber_without_street node_address 
left join extra_node_motorcycle motorcycle on node_address.id = motorcycle.id 
left join extra_node_motorcar motorcar on node_address.id = motorcar.id 
join extra_civicnum_municipalities municipalities on ST_Covers(municipalities.geom, node_address.geom);

drop table if exists NodeStreetNumberPlace ;

Create Table NodeStreetNumberPlace As
select cfg.graph_uri, extra_streetnumbers_on_nodes_without_street.*
  from extra_streetnumbers_on_nodes_without_street
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = node_source
;

drop table if exists extra_streetnumbers_on_ways_without_street ;

create table extra_streetnumbers_on_ways_without_street as
select * from ( 
select distinct 
	'OS' || lpad(ways.id::text,11,'0') || 'WN' cn_id, 
    housenumber.v extend_number, 
    substring(housenumber.v FROM '[0-9]+') number,
    substring(housenumber.v FROM '[a-zA-Z]+') exponent,
	addr_place.v place,
	CASE 
		WHEN municipalities.m_name = any ('{Firenze,Genova,Savona}') and housenumber.v ilike '%r%' THEN 'Rosso'
		WHEN municipalities.m_name = any ('{Firenze,Genova,Savona}') and not housenumber.v ilike '%r%' THEN 'Nero'
		ELSE 'Privo colore'
	END as class_code,
	'OS' || lpad(nodes.id::text,11,'0') || 'WE' en_id,  
	'Accesso esterno diretto' entry_type,
	ST_X(nodes.geom) long,
	ST_Y(nodes.geom) lat,
	CASE 
		WHEN motor.node_id is not null 
		THEN 'Accesso carrabile' 
		ELSE 'Accesso non carrabile' 
	END as porte_cochere, 
	'Open Street Map' node_source,
	'--' native_node_ref,
	dense_rank() over (partition by ways.id order by coalesce(entrance.v,'ZZZ'), coalesce(motor.v,'ZZZ'), way_nodes.sequence_id) as node_rank
from 
	ways
	join way_tags housenumber on ways.id = housenumber.way_id and housenumber.k = 'addr:housenumber'
	join way_nodes on ways.id = way_nodes.way_id
	join nodes on way_nodes.node_id = nodes.id
	join extra_civicnum_municipalities municipalities on ST_Covers(municipalities.geom, nodes.geom)
	join way_tags addr_place on ways.id = addr_place.way_id and addr_place.k = 'addr:place'
	left join way_tags addr_street on ways.id = addr_street.way_id and addr_street.k = 'addr:street'
	left join node_tags entrance on nodes.id = entrance.node_id and entrance.k in ('entrance','building','barrier')
	left join node_tags motor on nodes.id = motor.node_id and motor.k in ('motorcycle','motorcar')
where addr_street.way_id is null 
) q where node_rank = 1;

drop table if exists WayStreetNumberPlace ;

Create Table WayStreetNumberPlace As
select cfg.graph_uri, extra_streetnumbers_on_ways_without_street.*
  from extra_streetnumbers_on_ways_without_street
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = 'Open Street Map'
;
