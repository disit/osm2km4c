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

\timing

-- Delimitazione geografica dell'installazione

drop table if exists extra_config_boundaries; 

create table extra_config_boundaries as 
select * from extra_all_boundaries where relation_id in (:OSM_ID); --OpenStreetMap id della relazione su cui si vuole fare la triplificazione

create index extra_config_boundaries_index_1 on extra_config_boundaries using gist(boundary);

create index extra_config_boundaries_index_2 on extra_config_boundaries using gist(bbox);

create index extra_config_boundaries_index_3 on extra_config_boundaries using gist(centroid);

-- Grafo

drop table if exists extra_config_graph ;

create table extra_config_graph (
id serial primary key,
graph_uri varchar(255)
);

insert into extra_config_graph(graph_uri) values ('http://www.disit.org/km4city/resource/OSM/'); 

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


-- drop table if exists all_extra_ways;

-- create table all_extra_ways as
-- select prev_waynode.way_id global_id, prev_waynode.sequence_id local_id, prev_node.geom start_node, next_node.geom end_node, prev_node.id prev_node_id, next_node.id next_node_id
-- from all_way_nodes prev_waynode 
-- join nodes prev_node on prev_waynode.node_id = prev_node.id
-- join all_way_nodes next_waynode on prev_waynode.way_id = next_waynode.way_id and prev_waynode.sequence_id = next_waynode.sequence_id-1
-- join nodes next_node on next_waynode.node_id = next_node.id
-- join way_tags on prev_waynode.way_id = way_tags.way_id and way_tags.k = 'highway' and way_tags.v <> 'proposed'
-- join extra_config_boundaries boundaries on ST_Covers(boundaries.boundary, next_node.geom);

-- create index on all_extra_ways (global_id);

-- create index on all_extra_ways using gist(start_node);

-- create index on all_extra_ways using gist(end_node);

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

-- Province di interesse

drop table if exists extra_province;

create table extra_province as
select relations.id relation_id, extra_all_boundaries.centroid, extra_all_boundaries.boundary boundary, extra_all_boundaries.bbox bbox
from relations 
join relation_tags tag_type on relations.id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relations.id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relations.id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '6' 
join extra_all_boundaries on relations.id = extra_all_boundaries.relation_id
join extra_config_boundaries on ST_Covers(extra_config_boundaries.boundary, extra_all_boundaries.boundary);

create index extra_province_index_1 on extra_province using gist(centroid);

create index extra_province_index_2 on extra_province using gist(boundary);

create index extra_province_index_3 on extra_province using gist(bbox);

-- Corrispondenze tra comuni e province

drop table if exists extra_city_county ;

create table extra_city_county as
select extra_comuni.relation_id comune, province_short_name.v provincia
from extra_comuni, extra_province, relation_tags province_short_name
where ST_Covers(extra_province.boundary,extra_comuni.boundary)
and extra_province.relation_id = province_short_name.relation_id
and province_short_name.k = 'short_name';

-- Quartieri

drop table if exists extra_suburbs;

create table extra_suburbs as
select distinct suburb.id, suburb.centroid, suburb.boundary, suburb.suburb_type, suburb.suburb_name, extra_comuni.relation_id municipality_id
from 
(
-- suburb ways
select ways.id, 
	--ST_GeomFromText(ST_AsText(ST_Centroid(ST_ConvexHull(ST_Collect(ways.linestring)))),4326) centroid, 
	ST_GeomFromText(ST_AsText(ST_Centroid(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(linestring, ST_PointN(linestring, 1))))))),4326) centroid,
	--ST_GeomFromText(ST_AsText(ST_ConvexHull(ST_Collect(linestring))),4326) boundary, 
	ST_GeomFromText(ST_AsText(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(linestring, ST_PointN(linestring, 1)))))),4326) boundary,
	'W'::text suburb_type, way_suburb_name.v suburb_name 
from ways
join way_tags boundary on ways.id = boundary.way_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join way_tags admin_level on ways.id = admin_level.way_id and admin_level.k = 'admin_level' and cast(admin_level.v as int) > 8 
join way_tags way_suburb_name on ways.id = way_suburb_name.way_id and way_suburb_name.k = 'name'
where ST_NumPoints(ways.linestring) >= 4
group by ways.id, way_suburb_name.v
union
select ways.id, 
	--ST_GeomFromText(ST_AsText(ST_Centroid(ST_ConvexHull(ST_Collect(ways.linestring)))),4326) centroid, 
	ST_GeomFromText(ST_AsText(ST_Centroid(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(linestring, ST_PointN(linestring, 1))))))),4326) centroid,
	--ST_GeomFromText(ST_AsText(ST_ConvexHull(ST_Collect(linestring))),4326) boundary, 
	ST_GeomFromText(ST_AsText(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(linestring, ST_PointN(linestring, 1)))))),4326) boundary,
	'W'::text suburb_type, way_suburb_name.v suburb_name 
from ways
join way_tags on ways.id = way_tags.way_id and ( 
	( way_tags.k = 'site' and way_tags.v in ('housing') ) or 
	( way_tags.k = 'landuse' and way_tags.v in ('centre_zone','residential', 'industrial', 'commercial', 'retail') ) or 
	( way_tags.k = 'place' and way_tags.v in ('city', 'city_block','hamlet','isolated_dwelling','neighbourhood','quarter','suburb','town','village') ) or 
	( way_tags.k = 'boundary' and way_tags.v in ('quarter','city_limit','civil','town','urban','limited_traffic_zone','village') ) 
)
join way_tags way_suburb_name on ways.id = way_suburb_name.way_id and way_suburb_name.k = 'name'
where ST_NumPoints(ways.linestring) >= 4
group by ways.id, way_suburb_name.v
union
-- suburb relations
select rsuburbs.id, ST_GeomFromText(ST_AsText(ST_Centroid(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(tmp_boundary, ST_PointN(tmp_boundary, 1))),4326)))),4326) centroid, ST_GeomFromText(ST_AsText(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(tmp_boundary, ST_PointN(tmp_boundary, 1))),4326))),4326) boundary, rsuburbs.suburb_type, rel_suburb_name.v suburb_name from 
(
select relation_id id, 
	-- ST_GeomFromText(ST_AsText(ST_Centroid(ST_ConvexHull(ST_Collect(linestring)))),4326) centroid, 
	--ST_GeomFromText(ST_AsText(ST_ConvexHull(ST_Collect(linestring))),4326) boundary, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom tmp_boundary,
	'R'::text suburb_type from ( 
	select relation_members.relation_id, ways.linestring
	from relation_members 
	join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
	join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
	join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
	join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and cast(admin_level.v as int) > 8 
 ) sub group by relation_id
) rsuburbs 
join relation_tags rel_suburb_name on rsuburbs.id = rel_suburb_name.relation_id and rel_suburb_name.k = 'name'
where ST_NumPoints(ST_GeomFromText(ST_AsText(ST_AddPoint(tmp_boundary, ST_PointN(tmp_boundary, 1))),4326)) >= 4
union
select rsuburbs.id, ST_GeomFromText(ST_AsText(ST_Centroid(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(tmp_boundary, ST_PointN(tmp_boundary, 1))),4326)))),4326) centroid, ST_GeomFromText(ST_AsText(ST_MakePolygon(ST_GeomFromText(ST_AsText(ST_AddPoint(tmp_boundary, ST_PointN(tmp_boundary, 1))),4326))),4326) boundary, rsuburbs.suburb_type, rel_suburb_name.v suburb_name from 
(
select relation_id id, 
	--ST_GeomFromText(ST_AsText(ST_Centroid(ST_ConvexHull(ST_Collect(linestring)))),4326) centroid, 
	-- ST_GeomFromText(ST_AsText(ST_ConvexHull(ST_Collect(linestring))),4326) boundary, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(linestring))),4326))).geom tmp_boundary,
	'R'::text suburb_type from ( 
	select relation_members.relation_id, ways.linestring
	from relation_members 
	join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags on relation_members.relation_id = relation_tags.relation_id and ( 
	( relation_tags.k = 'site' and relation_tags.v in ('housing') ) or 
	( relation_tags.k = 'landuse' and relation_tags.v in ('centre_zone','residential', 'industrial', 'commercial', 'retail') ) or 
	( relation_tags.k = 'place' and relation_tags.v in ('city', 'city_block','hamlet','isolated_dwelling','neighbourhood','quarter','suburb','town','village') ) or 
	( relation_tags.k = 'boundary' and relation_tags.v in ('quarter','city_limit','civil','town','urban','limited_traffic_zone','village') ) 
)
 ) sub group by relation_id
) rsuburbs 
join relation_tags rel_suburb_name on rsuburbs.id = rel_suburb_name.relation_id and rel_suburb_name.k = 'name'
where ST_NumPoints(ST_GeomFromText(ST_AsText(ST_AddPoint(tmp_boundary, ST_PointN(tmp_boundary, 1))),4326)) >= 4
union
-- suburb nodes
select id, geom centroid, geom boundary, 'N'::text suburb_type, nd_suburb_name.v suburb_name 
from nodes 
join node_tags b on nodes.id = b.node_id and b.k = 'boundary' and b.v = 'administrative' 
join node_tags l on nodes.id = l.node_id and l.k = 'admin_level' and cast(l.v as int) > 8
join node_tags nd_suburb_name on nodes.id = nd_suburb_name.node_id and nd_suburb_name.k = 'name'
union
select id, geom centroid, geom boundary, 'N'::text suburb_type, nd_suburb_name.v suburb_name 
from nodes 
join node_tags on nodes.id = node_tags.node_id and ( 
	( node_tags.k = 'site' and node_tags.v in ('housing') ) or 
	( node_tags.k = 'landuse' and node_tags.v in ('centre_zone','residential', 'industrial', 'commercial', 'retail') ) or 
	( node_tags.k = 'place' and node_tags.v in ('city', 'city_block','hamlet','isolated_dwelling','neighbourhood','quarter','suburb','town','village') ) or 
	( node_tags.k = 'boundary' and node_tags.v in ('quarter','city_limit','civil','town','urban','limited_traffic_zone','village') ) 
)
join node_tags nd_suburb_name on nodes.id = nd_suburb_name.node_id and nd_suburb_name.k = 'name'
) suburb
join extra_comuni on ST_Covers(extra_comuni.boundary, suburb.boundary)
;

create index extra_suburbs_index_1 on extra_suburbs using gist(centroid);

create index extra_suburbs_index_2 on extra_suburbs using gist(boundary);

-- Corrispondenze tra elementi stradali, comuni e quartieri

drop table if exists extra_toponym_city ;

create table extra_toponym_city (
	id serial primary key,
	global_way_id bigint,
	local_way_id int,
	city varchar(255), 		
	suburb varchar(255)		
);

insert into extra_toponym_city(global_way_id, local_way_id, city) 
select highways.global_id global_way_id,
highways.local_id local_way_id,
nome_comune.v city 
from 
(
-- ways in relation roads
select extra_ways.global_id, extra_ways.local_id, 
extra_ways.start_node start_pt,
extra_ways.end_node end_pt
from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_ways on rwt.way_id = extra_ways.global_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
union
-- ways in relation pedestrian multipolygon 
select extra_ways.global_id, extra_ways.local_id, 
extra_ways.start_node start_pt,
extra_ways.end_node end_pt
from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_ways on r_ways.member_id = extra_ways.global_id 
union
-- ways that are roads
select extra_ways.global_id, extra_ways.local_id, 
extra_ways.start_node start_pt,
extra_ways.end_node end_pt
from way_tags wt
join extra_ways on wt.way_id = extra_ways.global_id
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
) highways
join extra_comuni comuni on ST_Covers(comuni.boundary, highways.start_pt) or ST_Covers(comuni.boundary, highways.end_pt)
join relation_tags nome_comune on comuni.relation_id = nome_comune.relation_id and nome_comune.k = 'name';

update extra_toponym_city 
set suburb = suburb.suburb_name
from (

select i_suburb.global_way_id, i_suburb.local_way_id, suburb_name from (
select highways.global_way_id, highways.local_way_id,
coalesce(way_suburb_name.v, rel_suburb_name.v) suburb_name,
dense_rank() over (partition by highways.global_way_id, highways.local_way_id, coalesce(way_suburb_name.v, rel_suburb_name.v) order by cast(coalesce(way_suburb_level.v, rel_suburb_level.v) as int) desc) suburb_rank
from
(
-- ways in relation roads
select extra_ways.global_id global_way_id, extra_ways.local_id local_way_id, 
extra_ways.start_node start_pt,
extra_ways.end_node end_pt
from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_ways on rwt.way_id = extra_ways.global_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
union
-- ways in relation pedestrian multipolygon 
select extra_ways.global_id, extra_ways.local_id, 
extra_ways.start_node start_pt,
extra_ways.end_node end_pt
from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_ways on r_ways.member_id = extra_ways.global_id 
union
-- ways that are roads
select extra_ways.global_id global_way_id, extra_ways.local_id local_way_id, 
extra_ways.start_node start_pt,
extra_ways.end_node end_pt
from way_tags wt
join extra_ways on wt.way_id = extra_ways.global_id
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
) highways
join extra_suburbs st_end_suburb on ST_Covers(st_end_suburb.boundary, highways.start_pt) and ST_Covers(st_end_suburb.boundary, highways.end_pt)
left join way_tags way_suburb_name on st_end_suburb.id = way_suburb_name.way_id and way_suburb_name.k = 'name'
left join relation_tags rel_suburb_name on st_end_suburb.id = rel_suburb_name.relation_id and rel_suburb_name.k = 'name'
left join way_tags way_suburb_level on st_end_suburb.id = way_suburb_level.way_id and way_suburb_level.k = 'admin_level'
left join relation_tags rel_suburb_level on st_end_suburb.id = rel_suburb_level.relation_id and rel_suburb_level.k = 'admin_level'

) i_suburb where suburb_rank = 1

) suburb 
where extra_toponym_city.global_way_id = suburb.global_way_id and extra_toponym_city.local_way_id = suburb.local_way_id;

-- Numeri civici ed accessi

drop table if exists extra_tmp_1 ;

create table extra_tmp_1 as
    select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' road_id,
    'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id, 
    cast(m.id as varchar(20)) municipality_relation_id,
    r_name.v road_extend_name,
    r_ways_routes.global_way_id a_global_way_id,
    r_ways_routes.local_way_id a_local_way_id,
    r_ways_routes.linestring a_way_route, 
    r_ways_routes.prev_node_id a_start_node_id, 
    r_ways_routes.next_node_id a_end_node_id
    from relations r
    join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
    left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
    left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
    join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
    join ( select global_id global_way_id, local_id local_way_id, ST_MakeLine(start_node,end_node) linestring, prev_node_id, next_node_id from extra_ways ) r_ways_routes on r_ways.member_id = r_ways_routes.global_way_id
    join extra_toponym_city e on r_ways_routes.global_way_id = e.global_way_id and r_ways_routes.local_way_id = e.local_way_id
    join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
    join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
    join relation_tags m_name on m_name.k = 'name' and m_name.v = e.city
    join relations m on m_name.relation_id = m.id
    join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
    join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
    join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
    where COALESCE(r_route.v,'road') = 'road'
    and COALESCE(r_network.v, '--') <> 'e-road' 
    and rwt.v <> 'proposed'
union -- pedestrian (squares)
    select distinct 'OS' || lpad(r.id::text,11,'0') || 'SQ' road_id,
    'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id, 
    cast(m.id as varchar(20)) municipality_relation_id,
    r_name.v road_extend_name,
    r_ways_routes.global_way_id a_global_way_id,
    r_ways_routes.local_way_id a_local_way_id,
    r_ways_routes.linestring a_way_route,
    r_ways_routes.prev_node_id a_start_node_id,
    r_ways_routes.next_node_id a_end_node_id
    from relations r
    join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
    join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
    join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
    join ( select global_id global_way_id, local_id local_way_id, ST_MakeLine(start_node,end_node) linestring, prev_node_id, next_node_id from extra_ways ) r_ways_routes on r_ways.member_id = r_ways_routes.global_way_id
    join extra_toponym_city e on r_ways_routes.global_way_id = e.global_way_id and r_ways_routes.local_way_id = e.local_way_id
    join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
    join relation_tags m_name on m_name.k = 'name' and m_name.v = e.city
    join relations m on m_name.relation_id = m.id
    join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
    join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
    join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'

;

create index on extra_tmp_1(municipality_relation_id);
create index on extra_tmp_1(road_extend_name);
create index on extra_tmp_1(a_start_node_id);
create index on extra_tmp_1(a_end_node_id);

drop table if exists extra_tmp_2 ;

create table extra_tmp_2 as 
    select distinct 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' road_id,  
    'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id,
    cast(m.id as varchar(20)) municipality_relation_id, 
    way_name.v road_extend_name,
    extra_ways.global_way_id a_global_way_id,
    extra_ways.local_way_id a_local_way_id,
    extra_ways.linestring a_way_route,
    extra_ways.prev_node_id a_start_node_id,
    extra_ways.next_node_id a_end_node_id
    from ways 
    join way_tags wt on ways.id = wt.way_id
    join extra_toponym_city e on wt.way_id = e.global_way_id 
    join ( select global_id global_way_id, local_id local_way_id, ST_MakeLine(start_node,end_node) linestring, prev_node_id, next_node_id from extra_ways ) extra_ways on e.global_way_id = extra_ways.global_way_id and e.local_way_id = extra_ways.local_way_id
    join way_tags way_name on wt.way_id = way_name.way_id and way_name.k='name'
    join relation_tags m_name on m_name.k = 'name' and m_name.v = e.city
    join relations m on m_name.relation_id = m.id
    join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
    join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
    join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
    where wt.k = 'highway' 
    and wt.v <> 'proposed';

create index on extra_tmp_2(municipality_relation_id);
create index on extra_tmp_2(road_extend_name);
create index on extra_tmp_2(a_start_node_id);
create index on extra_tmp_2(a_end_node_id);

drop table if exists extra_node_housenumber;

create table extra_node_housenumber as
select nodes.*, node_tags.v housenumber 
from nodes
join extra_config_boundaries on ST_Covers(boundary, nodes.geom)
join node_tags on nodes.id = node_tags.node_id and node_tags.k = 'addr:housenumber';

create index on extra_node_housenumber(id);
create index on extra_node_housenumber using gist(geom);

drop table if exists extra_node_street;

create table extra_node_street as
select extra_node_housenumber.*, node_tags.v street 
from extra_node_housenumber
join node_tags on extra_node_housenumber.id = node_tags.node_id and node_tags.k = 'addr:street';

create index on extra_node_street(id);

drop table if exists extra_node_city;

create table extra_node_city as
select extra_node_street.*, node_tags.v city 
from extra_node_street
join node_tags on extra_node_street.id = node_tags.node_id and node_tags.k = 'addr:city';

create index on extra_node_city(id);
create index on extra_node_city(street);
create index on extra_node_city using gist(geom);

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

drop table if exists extra_node_rt;

create table extra_node_rt as
select id 
from extra_node_city 
join node_tags on id = node_id and k = 'source' and v = 'Regione Toscana';

create index on extra_node_rt(id);

drop table if exists extra_node_rt_ref;

create table extra_node_rt_ref as
select id, v osnode
from extra_node_rt
join node_tags on id = node_id and k = 'ref';

create index on extra_node_rt_ref(id);
create index on extra_node_rt_ref(osnode);

drop table if exists extra_civicnum_municipalities;

create table extra_civicnum_municipalities as
select cast(extra_comuni.relation_id as varchar(20)) relation_id,  'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' id, relation_tags.v m_name, extra_comuni.boundary geom
from extra_comuni
join relation_tags on extra_comuni.relation_id = relation_tags.relation_id and relation_tags.k = 'name' ;

create index on extra_civicnum_municipalities using gist(geom);
create index on extra_civicnum_municipalities(relation_id);

drop table if exists extra_streetnumbers_on_nodes;

create table extra_streetnumbers_on_nodes as
select * from (
select distinct 'OS' || lpad(node_address.id::text,11,'0') || 'NN' cn_id, 
       node_address.housenumber extend_number,
       substring(node_address.housenumber FROM '[0-9]+') number,
       substring(node_address.housenumber FROM '[a-zA-Z]+') exponent,
	COALESCE(long_roads.road_id,short_roads.road_id) road_id,
CASE 
WHEN node_address.city = any ('{Firenze,Genova,Savona}') and node_address.housenumber ilike '%r%' THEN 'Rosso'
WHEN node_address.city = any ('{Firenze,Genova,Savona}') and not node_address.housenumber ilike '%r%' THEN 'Nero'
ELSE 'Privo colore'
END as class_code,
'OS' || lpad(node_address.id::text,11,'0') || 'NE' en_id,  
'Accesso esterno diretto' entry_type,
ST_X(node_address.geom) long,
ST_Y(node_address.geom) lat,
CASE WHEN motorcycle.id is not null or motorcar.id is not null THEN 'Accesso carrabile' ELSE 'Accesso non carrabile' END as porte_cochere, 
CASE WHEN long_roads.road_id is null THEN 'OS' || lpad(short_roads.a_global_way_id::text,11,'0') || 'RE/' || short_roads.a_local_way_id ELSE 'OS' || lpad(long_roads.a_global_way_id::text,11,'0') || 'RE/' || long_roads.a_local_way_id END as re_id,
CASE WHEN source_rt.id is not null THEN 'Regione Toscana' ELSE 'Open Street Map' END node_source,
coalesce(ref_tag.osnode,'--') native_node_ref,
dense_rank() over (partition by node_address.id order by ST_Distance(node_address.geom, COALESCE(long_roads.a_way_route,node_address.geom))) as long_roads_way_rank,
dense_rank() over (partition by node_address.id order by ST_Distance(node_address.geom, COALESCE(short_roads.a_way_route,node_address.geom))) as short_roads_way_rank
from extra_node_city node_address 
left join extra_node_motorcycle motorcycle on node_address.id = motorcycle.id 
left join extra_node_motorcar motorcar on node_address.id = motorcar.id 
left join extra_node_rt source_rt on node_address.id = source_rt.id 
left join extra_node_rt_ref ref_tag on node_address.id = ref_tag.id 
join extra_civicnum_municipalities municipalities on ST_Covers(municipalities.geom, node_address.geom)
left join extra_tmp_1 long_roads on municipalities.relation_id = long_roads.municipality_relation_id and ( node_address.street = long_roads.road_extend_name or coalesce(cast(ref_tag.osnode as numeric),-1) = long_roads.a_start_node_id or coalesce(cast(ref_tag.osnode as numeric),-1) = long_roads.a_end_node_id )
left join extra_tmp_2 short_roads on municipalities.relation_id = short_roads.municipality_relation_id and ( node_address.street = short_roads.road_extend_name or coalesce(cast(ref_tag.osnode as numeric),-1) = short_roads.a_start_node_id or coalesce(cast(ref_tag.osnode as numeric),-1) = short_roads.a_end_node_id )
where COALESCE(long_roads.road_id,short_roads.road_id,'--') <> '--' 
) q 
where long_roads_way_rank = 1 and short_roads_way_rank = 1;

drop table if exists extra_streetnumbers_on_relations ;

create table extra_streetnumbers_on_relations as 
select * from (
select distinct 'OS' || lpad(streetNumbers.member_id::text,11,'0') || 'NN' cn_id,
       housenumber.v extend_number,
       substring(housenumber.v FROM '[0-9]+') number,
       substring(housenumber.v FROM '[a-zA-Z]+') exponent,
COALESCE(super_road.road_id, pedestrian_super_road.road_id, 'OS' || lpad(road.member_id::text,11,'0') || 'SR') road_id,
CASE 
WHEN COALESCE(city.v,'--') = any ('{Firenze,Genova,Savona}') and housenumber.v ilike '%r%' THEN 'Rosso'
WHEN COALESCE(city.v,'--') = any ('{Firenze,Genova,Savona}') and not housenumber.v ilike '%r%' THEN 'Nero'
ELSE 'Privo colore'
END as class_code,
'OS' || lpad(streetNumberNodes.id::text,11,'0') || 'NE' en_id,  
'Accesso esterno diretto' entry_type,
ST_X(streetNumberNodes.geom) long,
ST_Y(streetNumberNodes.geom) lat,
CASE WHEN motorcycle.node_id is not null or motorcar.node_id is not null THEN 'Accesso carrabile' ELSE 'Accesso non carrabile' END as porte_cochere,
'OS' || lpad(road.member_id::text,11,'0') || 'RE/' || extra_ways.local_id re_id,
dense_rank() over (partition by streetNumbers.member_id, extra_ways.global_id order by ST_Distance(streetNumberNodes.geom, ST_MakeLine(extra_ways.start_node,extra_ways.end_node))) as road_element_rank
from relations
join relation_tags associatedStreet on relations.id = associatedStreet.relation_id and associatedStreet.k = 'type' and associatedStreet.v = 'associatedStreet'
left join relation_tags city on relations.id = city.relation_id and city.k = 'addr:city'
join relation_members streetNumbers on relations.id = streetNumbers.relation_id and streetNumbers.member_type = 'N'
join nodes streetNumberNodes on streetNumbers.member_id = streetNumberNodes.id
left join node_tags motorcycle on streetNumberNodes.id = motorcycle.node_id and motorcycle.k = 'motorcycle' and motorcycle.v = 'yes'
left join node_tags motorcar on streetNumberNodes.id = motorcar.node_id and motorcar.k = 'motorcar' and motorcar.v = 'yes'
join node_tags housenumber on housenumber.node_id = streetNumbers.member_id and housenumber.k = 'addr:housenumber'
join relation_members road on relations.id = road.relation_id and road.member_type = 'W'
join extra_ways on extra_ways.global_id = road.member_id
join extra_toponym_city e on road.member_id = e.global_way_id and extra_ways.local_id = e.local_way_id
left join 
(
select distinct r_ways.member_id way_id,
       'OS' || lpad(r.id::text,11,'0') || 'LR' road_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
) super_road on road.member_id = super_road.way_id 
left join
(
select distinct r_ways.member_id way_id,
       'OS' || lpad(r.id::text,11,'0') || 'SQ' road_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
) pedestrian_super_road on road.member_id = pedestrian_super_road.way_id 
) q where road_element_rank = 1;

drop table if exists extra_streetnumbers_on_junctions ;

create table extra_streetnumbers_on_junctions as
select distinct 'OS' || lpad(housenumber.id::text,11,'0') || 'NN' cn_id,
       housenumber.housenumber extend_number,
       substring(housenumber.housenumber FROM '[0-9]+') number,
       substring(housenumber.housenumber FROM '[a-zA-Z]+') exponent,
       COALESCE(super_road.road_id, pedestrian_super_road.road_id, simple_road.road_id) road_id,
CASE 
WHEN e.city = any ('{Firenze,Genova,Savona}') and housenumber.housenumber ilike '%r%' THEN 'Rosso'
WHEN e.city = any ('{Firenze,Genova,Savona}') and not housenumber.housenumber ilike '%r%' THEN 'Nero'
ELSE 'Privo colore'
END as class_code,
'OS' || lpad(housenumber.id::text,11,'0') || 'NE' en_id,  
'Accesso esterno diretto' entry_type,
ST_X(housenumber.geom) long,
ST_Y(housenumber.geom) lat,
CASE WHEN motorcycle.id is not null or motorcar.id is not null THEN 'Accesso carrabile' ELSE 'Accesso non carrabile' END as porte_cochere,
'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id re_id
from extra_node_housenumber housenumber 
left join extra_node_motorcycle motorcycle on housenumber.id = motorcycle.id 
left join extra_node_motorcar motorcar on housenumber.id = motorcar.id 
join way_nodes junctions on housenumber.id = junctions.node_id
join extra_ways on junctions.way_id = extra_ways.global_id and extra_ways.prev_node_id = housenumber.id
join extra_toponym_city e on e.global_way_id = extra_ways.global_id and e.local_way_id = extra_ways.local_id 
left join 
(
select distinct r_ways.member_id way_id,
       'OS' || lpad(r.id::text,11,'0') || 'LR' road_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
) super_road on junctions.way_id = super_road.way_id 
left join 
(
  select distinct r_ways.member_id way_id,
       'OS' || lpad(r.id::text,11,'0') || 'SQ' road_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
) pedestrian_super_road on junctions.way_id = pedestrian_super_road.way_id 
left join
(
select distinct 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' road_id,
wt.way_id osm_road_id
  from way_tags wt
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
) simple_road on junctions.way_id = simple_road.osm_road_id
where COALESCE(super_road.road_id, pedestrian_super_road.road_id, simple_road.road_id, '--') <> '--';

drop table if exists extra_streetnumbers_on_ways ;

create table extra_streetnumbers_on_ways as
select * from ( 
select distinct 
	'OS' || lpad(ways.id::text,11,'0') || 'WN' cn_id, 
    housenumber.v extend_number, 
    substring(housenumber.v FROM '[0-9]+') number,
    substring(housenumber.v FROM '[a-zA-Z]+') exponent,
	COALESCE(long_roads.road_id,short_roads.road_id) road_id,
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
	CASE 
		WHEN long_roads.road_id is null 
		THEN 'OS' || lpad(short_roads.a_global_way_id::text,11,'0') || 'RE/' || short_roads.a_local_way_id 
		ELSE 'OS' || lpad(long_roads.a_global_way_id::text,11,'0') || 'RE/' || long_roads.a_local_way_id 
	END as re_id,
	'Open Street Map' node_source,
	'--' native_node_ref,
	dense_rank() over (partition by ways.id, nodes.id order by ST_Distance(nodes.geom, COALESCE(long_roads.a_way_route,nodes.geom)), long_roads.road_id) as long_roads_way_rank,
	dense_rank() over (partition by ways.id, nodes.id order by ST_Distance(nodes.geom, COALESCE(short_roads.a_way_route,nodes.geom)), short_roads.road_id) as short_roads_way_rank,
	dense_rank() over (partition by ways.id order by coalesce(entrance.v,'ZZZ'), coalesce(motor.v,'ZZZ'), ST_Distance(nodes.geom, COALESCE(short_roads.a_way_route, long_roads.a_way_route )), way_nodes.sequence_id) as node_rank
from 
	ways
	join way_tags housenumber on ways.id = housenumber.way_id and housenumber.k = 'addr:housenumber'
	join way_nodes on ways.id = way_nodes.way_id
	join nodes on way_nodes.node_id = nodes.id
	join extra_civicnum_municipalities municipalities on ST_Covers(municipalities.geom, nodes.geom)
	join way_tags addr_street on ways.id = addr_street.way_id and addr_street.k = 'addr:street'
	left join node_tags entrance on nodes.id = entrance.node_id and entrance.k in ('entrance','building','barrier')
	left join node_tags motor on nodes.id = motor.node_id and motor.k in ('motorcycle','motorcar')
	left join extra_tmp_1 long_roads on municipalities.relation_id = long_roads.municipality_relation_id 
		and addr_street.v = long_roads.road_extend_name 
	left join extra_tmp_2 short_roads on municipalities.relation_id = short_roads.municipality_relation_id 
		and addr_street.v = short_roads.road_extend_name 
where COALESCE(long_roads.road_id,short_roads.road_id,'--') <> '--' 
) q where long_roads_way_rank = 1 and short_roads_way_rank = 1 and node_rank = 1;

drop table if exists extra_way_names;

create table extra_way_names as select way_tags.* from way_tags join extra_ways on way_tags.way_id = extra_ways.global_id where way_tags.k = 'name';

create index extra_way_names_id on extra_way_names(way_id);

create index extra_way_names_lower_v on extra_way_names(lower(v));

drop table if exists extra_roadwaytype;

create table extra_roadwaytype As
select graph_uri, 
 'OS' || lpad(wt.global_id::text,11,'0') || 'SR' id,  
       way_name.v extend_name,
       g.naming road_type
  from extra_ways wt
  join extra_way_names way_name on wt.global_id = way_name.way_id 
  join extra_generic_namings g on lower(way_name.v) like lower(g.naming) || '%'
  join extra_config_graph cfg on 1=1
  left join 
(
select r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
) tbl on wt.global_id = tbl.member_id
 where way_name.k='name' and tbl.member_id is null
;

/***********************************************************************
************* PREPARAZIONE DEI DATI PER SPARQLIFY **********************
***********************************************************************/

/*******************************
*********** Province ***********
*******************************/

/********** Province URI **********/

drop table if exists ProvinceURI ;

Create table ProvinceURI As
  select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join extra_province prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_config_graph cfg on 1=1;

/********** Province.Identifier **********/

drop table if exists ProvinceIdentifier ;

Create table ProvinceIdentifier As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join extra_province prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Province.Name **********/

drop table if exists ProvinceName ;

Create Table ProvinceName As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id,
       r_name.v p_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_province prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Province.Alternative **********/

drop table if exists ProvinceAlternative ;

Create Table ProvinceAlternative As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id,
       r_short_name.v alternative
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join relation_tags r_short_name on r.id = r_short_name.relation_id and r_short_name.k = 'short_name'
  join extra_province prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Province.hasMunicipality **********/

drop table if exists ProvinceHasMunicipality ;

Create Table ProvinceHasMunicipality As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id,
       'OS' || lpad(e.comune::text,11,'0') || 'CO' has_municipality
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join relation_tags r_short_name on r.id = r_short_name.relation_id and r_short_name.k = 'short_name'
  join extra_province prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_city_county e on r_short_name.v = e.provincia
  join extra_config_graph cfg on 1=1
;


/***********************************
*********** Municipality ***********
***********************************/

/********** Municipality URI **********/

drop table if exists MunicipalityURI ;

Create Table MunicipalityURI As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'CO' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8'
  join extra_comuni com_of_interest on r.id = com_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;


/********** Municipality.Identifier **********/

drop table if exists MunicipalityIdentifier ;

Create Table MunicipalityIdentifier As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'CO' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8'
  join extra_comuni com_of_interest on r.id = com_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Municipality.Name **********/

drop table if exists MunicipalityName ;

Create Table MunicipalityName As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'CO' id,
       r_name.v p_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8'
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_comuni com_of_interest on r.id = com_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Municipality.Alternative **********/

drop table if exists MunicipalityAlternative ;

Create Table MunicipalityAlternative As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'CO' id,
       r_catasto.v alternative
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8'
  join relation_tags r_catasto on r.id = r_catasto.relation_id and r_catasto.k = 'ref:catasto'
  join extra_comuni com_of_interest on r.id = com_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Municipality.isPartOfProvince **********/

drop table if exists MunicipalityIsPartOfProvince ;

Create Table MunicipalityIsPartOfProvince As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'CO' id,
       'OS' || lpad(pr.id::text,11,'0') || 'PR' province_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8'
  join extra_comuni com_of_interest on r.id = com_of_interest.relation_id 
  join extra_city_county e on r.id = e.comune
  join relation_tags p_short_tag on p_short_tag.k = 'short_name' and p_short_tag.v = e.provincia
  join relations pr on p_short_tag.relation_id = pr.id
  join relation_tags pr_type on pr.id = pr_type.relation_id and pr_type.k = 'type' and pr_type.v = 'boundary'
  join relation_tags pr_boundary on pr.id = pr_boundary.relation_id and pr_boundary.k = 'boundary' and pr_boundary.v = 'administrative'
  join relation_tags pr_admin_level on pr.id = pr_admin_level.relation_id and pr_admin_level.k = 'admin_level' and pr_admin_level.v = '6'
  join extra_config_graph cfg on 1=1
;

/***************************
********** Hamlet **********
***************************/

drop table if exists Hamlet ;

Create Table Hamlet As
select distinct graph_uri, 'OS' || lpad(extra_suburbs.id::text,11,'0') || 'HT' hamlet_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id,
       t.suburb hamlet_name,
	ST_X(extra_suburbs.centroid::geometry) long, 
	ST_Y(extra_suburbs.centroid::geometry) lat
  from extra_toponym_city t 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join extra_suburbs on extra_suburbs.municipality_id = m.id and extra_suburbs.suburb_name = t.suburb --
  join extra_config_graph cfg on 1=1
  where extra_suburbs.suburb_type = 'N'::text and not ((t.suburb = '') IS NOT FALSE)
;

insert into Hamlet(graph_uri, hamlet_id, municipality_id, hamlet_name, long, lat) 
select distinct graph_uri, 
'OS' || lpad(nodes.id::text,11,'0') || 'HT' hamlet_id,
'OS' || lpad(m.relation_id::text,11,'0') || 'CO' municipality_id,
place_name.v hamlet_name,
ST_X(nodes.geom) long, 
ST_Y(nodes.geom) lat
from nodes
join node_tags place_suburb on nodes.id = place_suburb.node_id and ( 
	( place_suburb.k = 'site' and place_suburb.v in ('housing') ) or 
	( place_suburb.k = 'landuse' and place_suburb.v in ('centre_zone','residential', 'industrial', 'commercial', 'retail') ) or 
	( place_suburb.k = 'place' and place_suburb.v in ('city', 'city_block','hamlet','isolated_dwelling','neighbourhood','quarter','suburb','town','village') ) or 
	( place_suburb.k = 'boundary' and place_suburb.v in ('quarter','city_limit','civil','town','urban','limited_traffic_zone','village', 'administrative') ) 
)
join node_tags place_name on nodes.id = place_name.node_id and place_name.k = 'name'
join extra_comuni m on ST_Covers(m.boundary, nodes.geom)
join extra_config_graph cfg on 1=1;

/**************************
*********** Road **********
**************************/

/********** Road(RELATION) URI **********/

drop table if exists RoadRelationURI ;

Create Table RoadRelationURI As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
union -- pedestrian relations (squares)
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
;

/********** Road(RELATION).Identifier **********/

drop table if exists RoadRelationIdentifier ;

Create Table RoadRelationIdentifier As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
union -- pedestrian relations (squares)
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
;

/********** Road(RELATION).RoadType **********/

drop table if exists RoadRelationType ;

Create Table RoadRelationType As
select graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' id,
       r_name.v extend_name,
       max(g.naming) road_type
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_generic_namings g on r_name.v ILIKE g.naming || '%'
  join extra_config_graph cfg on 1=1
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
 group by graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR', r_name.v
union -- pedestrian relations (squares)
select graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' id,
       r_name.v extend_name,
       max(g.naming) road_type
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_generic_namings g on r_name.v ILIKE g.naming || '%'
  join extra_config_graph cfg on 1=1
 group by graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ', r_name.v

;  

/********** Road(RELATION).RoadName **********/

drop table if exists RoadRelationName ;

Create Table RoadRelationName As
select graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' id,
       r_name.v extend_name,
       trim(substring(r_name.v, 1+char_length(max(coalesce(g.naming,''))))) road_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_config_graph cfg on 1=1
  left join extra_generic_namings g on r_name.v ILIKE g.naming || '%'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
 group by graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR', r_name.v
union -- pedestrian relations (squares)
select graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' id,
       r_name.v extend_name,
       trim(substring(r_name.v, 1+char_length(max(coalesce(g.naming,''))))) road_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_config_graph cfg on 1=1
  left join extra_generic_namings g on r_name.v ILIKE g.naming || '%'
 group by graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ', r_name.v
;

/********** Road(RELATION).ExtendName **********/

drop table if exists RoadRelationExtendName ;

Create Table RoadRelationExtendName As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' id,
       r_name.v extend_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_config_graph cfg on 1=1
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
union -- pedestrian relations (squares)
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' id,
       r_name.v extend_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_config_graph cfg on 1=1
;

/********** Road(RELATION).Alternative **********/

drop table if exists RoadRelationAlternative ;

Create Table RoadRelationAlternative As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' id,
       r_alt_name.v alternative
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_alt_name on r.id = r_alt_name.relation_id and r_alt_name.k = 'alt_name'
  join extra_config_graph cfg on 1=1
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
union -- pedestrian relations (squares)
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' id,
       r_alt_name.v alternative
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join relation_tags r_alt_name on r.id = r_alt_name.relation_id and r_alt_name.k = 'alt_name'
  join extra_config_graph cfg on 1=1
;

/*************************************************
*********** Generazione dei RoadElement **********
*********** a partire dalle Relation    **********
*********** che rappresentano toponimi  **********
*********** e legatura alla Road        **********
*************************************************/

drop table if exists RoadRelationElementType ;

Create Table RoadRelationElementType As
select distinct graph_uri, 
	'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id road_element_id,
	rwt.v road_element_type,
	'OS' || lpad(r.id::text,11,'0') || 'LR' road_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join extra_ways on extra_ways.global_id = r_ways.member_id
  join extra_config_graph cfg on 1=1
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
union
select distinct graph_uri, 
	'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id road_element_id,
       	coalesce(rwt.v,'not found') road_element_type,
	'OS' || lpad(r.id::text,11,'0') || 'SQ' road_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  left join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
  join extra_ways on extra_ways.global_id = r_ways.member_id
  join extra_config_graph cfg on 1=1
;

/********** Road(RELATION).inMunicipalityOf  *********/

drop table if exists RoadRelationInMunicipalityOf ;

Create Table RoadRelationInMunicipalityOf As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' road_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city t on r_ways.member_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join extra_config_graph cfg on 1=1
where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
union 
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' road_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city t on r_ways.member_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join extra_config_graph cfg on 1=1
;

/********** Road(RELATION).inHamletOf  ***************/

drop table if exists RoadRelationInHamletOf ;

Create Table RoadRelationInHamletOf As
select distinct cfg.graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' road_id,
       h.hamlet_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city t on r_ways.member_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join Hamlet h on h.hamlet_name = t.suburb and h.municipality_id = 'OS' || lpad(m.id::text,11,'0') || 'CO'
  join extra_config_graph cfg on 1=1
where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'
   AND not ((t.suburb = '') IS NOT FALSE)
union
select distinct cfg.graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'SQ' road_id,
       h.hamlet_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city t on r_ways.member_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join Hamlet h on h.hamlet_name = t.suburb and h.municipality_id = 'OS' || lpad(m.id::text,11,'0') || 'CO'
  join extra_config_graph cfg on 1=1
where not ((t.suburb = '') IS NOT FALSE);

/********** Road(WAY) URI **********************/
/********** Road(WAY).ContainsElement **********/

drop table if exists RoadWayURI ;

Create Table RoadWayURI As
select distinct graph_uri, 
	'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id,
       	'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id eid, 
	wt.v road_element_type 
  from way_tags wt
  join extra_toponym_city e on wt.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
;

/********** Road(WAY).Identifier **********/

drop table if exists RoadWayIdentifier ;

Create Table RoadWayIdentifier As
select distinct graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id  
  from way_tags wt
  join extra_toponym_city e on wt.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
;

/********** Road(WAY).RoadType **********/

drop table if exists RoadWayType ;

create table RoadWayType as
select graph_uri, id, extend_name, max(road_type) road_type from extra_roadwaytype group by graph_uri, id, extend_name;

/********** Road(WAY).RoadName **********/

drop table if exists RoadWayName;

create table RoadWayName As
select distinct cfg.graph_uri graph_uri, 
 'OS' || lpad(wt.global_id::text,11,'0') || 'SR' id,  
       way_name.v extend_name,
trim(substring(way_name.v, 1+char_length(coalesce(RoadWayType.road_type,'')))) road_name
  from extra_ways wt
  join extra_way_names way_name on wt.global_id = way_name.way_id 
  join extra_config_graph cfg on 1=1
  left join RoadWayType on RoadWayType.graph_uri = cfg.graph_uri and RoadWayType.id = 'OS' || lpad(wt.global_id::text,11,'0') || 'SR' and RoadWayType.extend_name = way_name.v
  left join 
(
select r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
) tbl on wt.global_id = tbl.member_id
 where way_name.k='name' and tbl.member_id is null
;

/********** Road(WAY).ExtendName **********/

drop table if exists RoadWayExtendName ;

Create Table RoadWayExtendName As
select distinct graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id,  
       way_name.v extend_name
  from way_tags wt
  join extra_toponym_city e on wt.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
  join way_tags way_name on wt.way_id = way_name.way_id and way_name.k='name'
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
;

/********** Road(WAY).Alternative **********/

drop table if exists RoadWayAlternative ;

Create Table RoadWayAlternative As
select distinct graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id,  
       way_alt_name.v alternative
  from way_tags wt
  join extra_toponym_city e on wt.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
  join way_tags way_alt_name on wt.way_id = way_alt_name.way_id and way_alt_name.k='alt_name'
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
;

/********** Road(WAY).InMunicipalityOf **********/

drop table if exists RoadWayInMunicipalityOf ;

Create Table RoadWayInMunicipalityOf As
select distinct graph_uri, 
'OS' || lpad(t.global_way_id ::text,11,'0') || 'SR' road_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id,
t.global_way_id
  from extra_toponym_city t 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join extra_config_graph cfg on 1=1;

delete from RoadWayInMunicipalityOf 
where global_way_id in 
(
select r_ways.member_id global_way_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
) ;

/********** Road(WAY).InHamletOf ****************/

drop table if exists RoadWayInHamletOf ;

Create Table RoadWayInHamletOf As
select distinct cfg.graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' road_id,
       h.hamlet_id
  from way_tags wt
  join extra_toponym_city t on wt.way_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join Hamlet h on h.hamlet_name = t.suburb and h.municipality_id = 'OS' || lpad(m.id::text,11,'0') || 'CO'
  join extra_config_graph cfg on 1=1  
  left join relation_members rm on rm.member_type = 'W' and rm.member_id = wt.way_id and rm.relation_id in 
(
select r.id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
)
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
   AND not ((t.suburb = '') IS NOT FALSE);

/**********************************
*********** RoadElement ***********
**********************************/

/********** RoadElement.ElementType **********/

drop table if exists RoadElementType_ ;

Create Table RoadElementType_ As
select graph_uri, t.global_way_id,
substring(min(case 
when highway.v = 'service' and coalesce(way_tags.k,'--') = 'service' and coalesce(way_tags.v,'--') = 'parking_aisle' 
then '01 di parcheggio' 
when highway.v = any ('{motorway,trunk,primary,secondary,tertiary,unclassified,residential,service}') 
then '02 di tronco carreggiata' 
when highway.v = any ('{motorway_link,trunk_link,primary_link,secondary_link,tertiary_link,escape,motorway_junction}') 
then '03 raccordo, bretella, svincolo' 
when coalesce(way_tags.k,'--') = 'amenity' and coalesce(way_tags.v,'--') = 'parking' 
then '04 di parcheggio strutturato' 
when highway.v = any ('{mini_roundabout,turning_cirle,turning_loop}') or ( coalesce(way_tags.k,'--') = 'junction' and coalesce(way_tags.v,'--') = 'roundabout')
then '05 di rotatoria'
when coalesce(way_tags.k,'--') = 'barrier' and coalesce(way_tags.v,'--') = 'toll_booth' 
then '06 di casello/barriera autostradale' 
when coalesce(way_tags.k,'--') = 'area' and coalesce(way_tags.v,'--') = 'yes' 
then '07 di piazza' 
when highway.v = any ('{pedestrian,living_street,footway,bridleway,steps,path,crossing,elevator}') 
then '08 pedonale' 
when coalesce(way_tags.k,'--') = 'railway' and coalesce(way_tags.v,'--') = 'level_crossing' 
then '09 di passaggio a livello' 
when highway.v = any ('{bus_stop,emergency_access_point,rest_area,services}') 
then '10 in area di pertinenza'
when coalesce(way_tags.k,'--') = 'lanes' and coalesce(way_tags.v,'--') is not null 
then '11 di area a traffico strutturato' 
else '12 di area a traffico non strutturato'
end),4) as element_type
from way_tags highway
  join extra_config_graph cfg on 1=1
join (select distinct global_way_id from extra_toponym_city ) t on highway.way_id = t.global_way_id 
left join way_tags on highway.way_id = way_tags.way_id and way_tags.k <> 'highway'
left join way_nodes on highway.way_id = way_nodes.way_id 
left join node_tags on way_nodes.node_id = node_tags.node_id
where highway.k = 'highway' 
and highway.v <> 'proposed'
group by graph_uri, t.global_way_id
;

drop table if exists RoadElementType;

create table RoadElementType as
select RoadElementType_.*, 'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id id
from RoadElementType_
join extra_ways on RoadElementType_.global_way_id = extra_ways.global_id;

drop table if exists RoadElementRoundabout_ ;

Create Table RoadElementRoundabout_ As
select graph_uri, t.global_way_id,  'di rotatoria'::text  as element_type
from way_tags highway
  join extra_config_graph cfg on 1=1
join (select distinct global_way_id from extra_toponym_city ) t on highway.way_id = t.global_way_id 
left join way_tags on highway.way_id = way_tags.way_id and way_tags.k <> 'highway'
left join way_nodes on highway.way_id = way_nodes.way_id 
left join node_tags on way_nodes.node_id = node_tags.node_id
where highway.k = 'highway' 
and highway.v <> 'proposed'
and ( highway.v = any ('{mini_roundabout,turning_cirle,turning_loop}') or ( coalesce(way_tags.k,'--') = 'junction' and coalesce(way_tags.v,'--') = 'roundabout') )
;

drop table if exists RoadElementRoundabout;

create table RoadElementRoundabout as
select RoadElementRoundabout_.*, 'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id id
from RoadElementRoundabout_
join extra_ways on RoadElementRoundabout_.global_way_id = extra_ways.global_id;

/********** RoadElement.ElementClass **********/

drop table if exists RoadElementClass ;

Create Table RoadElementClass As
select distinct graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id id,  
case 
when highway.v = 'motorway' 
then 'autostrada'
when highway.v = 'trunk' 
then 'extraurbana principale'
when highway.v = any ('{primary,secondary,tertiary}') 
then 'extraurbana secondaria'
when highway.v = 'unclassified' 
then 'urbana di scorrimento'
when highway.v = 'residential' 
then 'urbana di quartiere'
else 'locale/vicinale/privata ad uso privato'
end as element_class
from way_tags highway
  join extra_config_graph cfg on 1=1
join extra_toponym_city t on highway.way_id = t.global_way_id 
where highway.k = 'highway' 
and highway.v <> 'proposed'
;

/********** RoadElement.Composition **********/

drop table if exists RoadElementComposition ;

Create Table RoadElementComposition As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,  
       case when t.relation_id is not null or highway.v = 'motorway' or highway.v = 'trunk' then 'carreggiate separate' else 'carreggiata unica' end as composition
from way_tags highway
  join extra_config_graph cfg on 1=1
join extra_toponym_city e on highway.way_id = e.global_way_id 
left join relation_members m on highway.way_id = m.member_id and m.member_type = 'W'
left join relation_tags t on m.relation_id = t.relation_id and t.k = 'type' and t.v = 'double_carriageway'
where highway.k = 'highway'
and highway.v <> 'proposed'
;

/********** RoadElement.elemLocation **********/

drop table if exists RoadElementLocation ;

Create Table RoadElementLocation As
select graph_uri, elq.id, case when rate = 1110 then 'galleria, ponte e rampa' when rate = 1100 then 'ponte e rampa' when rate = 1010 then 'ponte e galleria' when rate = 1000 then 'ponte' when rate = 110 then 'galleria e rampa' when rate = 100 then 'rampa' when rate = 10 then 'galleria' else 'a raso' end as elem_location 
from (
select 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,   
       sum(case
       when way_tags.k = 'tunnel' and way_tags.v = 'yes' then 10
       when highway.v = any ('{motorway_link,trunk_link,primary_link,secondary_link,tertiary_link,escape,motorway_junction}')  then 100
       when ( way_tags.k = 'bridge' and way_tags.v = 'yes' ) or m.relation_id is not null  then 1000
       end) as rate
from way_tags highway
join extra_toponym_city e on highway.way_id = e.global_way_id 
left join way_tags on highway.way_id = way_tags.way_id and ( way_tags.k = 'tunnel' or way_tags.k = 'bridge' )
left join (select m.member_id, m.member_type, t.relation_id from relation_members m join relation_tags t on m.relation_id = t.relation_id and t.k = 'type' and t.v = 'bridge' ) m on highway.way_id = m.member_id and m.member_type = 'W'
where highway.k = 'highway'
and highway.v <> 'proposed'
group by 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id
) elq
  join extra_config_graph cfg on 1=1
;

/********** RoadElement.Length **********/

drop table if exists RoadElementLength ;

Create Table RoadElementLength As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,  
	round(ST_Distance(extra_ways.start_node::geography,extra_ways.end_node::geography)) length
from way_tags highway
  join extra_config_graph cfg on 1=1
join extra_toponym_city e on highway.way_id = e.global_way_id 
join extra_ways on extra_ways.global_id = e.global_way_id and extra_ways.local_id = e.local_way_id
where highway.k = 'highway'
and highway.v <> 'proposed'
;

/********** RoadElement.Width **********/

drop table if exists RoadElementWidth ;

Create Table RoadElementWidth As
select distinct graph_uri, wq.id, 
case 
when width > 7 then 'maggiore di 7 mt'
when width > 3.5 then 'tra 3,5 mt e 7 mt'
when width > 0 then 'minore di 3,5 mt'
else 'non rilevato'
end as width
from (
select 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,  
case 
when w.v is not null and trim(replace(replace(w.v, 'm',''),',','.')) ~ '^[0-9\.]+$' then trim(replace(replace(w.v, 'm',''),',','.'))::float
when ew.v is not null and trim(replace(replace(ew.v, 'm',''),',','.')) ~ '^[0-9\.]+$' then trim(replace(replace(ew.v, 'm',''),',','.'))::float
else -1
end as width
from way_tags highway
join extra_toponym_city e on highway.way_id = e.global_way_id 
left join way_tags w on highway.way_id = w.way_id and w.k = 'width' 
left join way_tags ew on highway.way_id = ew.way_id and ew.k = 'est_width' 
where highway.k = 'highway'
and highway.v <> 'proposed'
) wq
  join extra_config_graph cfg on 1=1
;

/********** RoadElement.OperatingStatus **********/

drop table if exists RoadElementOperatingStatus ;

Create Table RoadElementOperatingStatus As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,  
case 
when highway.v = 'construction' then 'in construzione'
when coalesce(abandoned.v,'--') = 'yes' or coalesce(disused.v,'--') = 'yes' then 'in disuso'
else 'in esercizio'
end as operating_status
from way_tags highway
  join extra_config_graph cfg on 1=1
join extra_toponym_city e on highway.way_id = e.global_way_id 
left join way_tags abandoned on highway.way_id = abandoned.way_id and abandoned.k = 'abandoned'
left join way_tags disused on highway.way_id = disused.way_id and disused.k = 'disused'
where highway.k = 'highway'
and highway.v <> 'proposed'
;

/********** RoadElement.SpeedLimit **********/

drop table if exists RoadElementSpeedLimit ;

Create Table RoadElementSpeedLimit As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,  maxspeed.v speed_limit
from way_tags highway
join extra_toponym_city e on highway.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
join way_tags maxspeed on highway.way_id = maxspeed.way_id and maxspeed.k = 'maxspeed' and maxspeed.v ~ '^[0-9\.]+$'
where highway.k = 'highway'
and highway.v <> 'proposed'
;

/********** RoadElement.TrafficDir **********/

drop table if exists RoadElementTrafficDir ;

Create Table RoadElementTrafficDir As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id,  
case 
when highway.v = 'construction' /*or coalesce(access.v,'--') = 'no'*/ then 'tratto stradale chiuso in entrambe le direzioni'
when coalesce(oneway.v,'--') = any('{1,yes}') then 'tratto stradale aperto nella direzione positiva (da giunzione NOD_INI a giunzione NOD_FIN)'
when coalesce(oneway.v,'--') = '-1' then 'tratto stradale aperto nella direzione negativa (da giunzione NOD_FIN a giunzione NOD_INI)'
else 'tratto stradale aperto in entrambe le direzioni (default)'
end as traffic_dir
from way_tags highway
join extra_toponym_city e on highway.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
/*left join way_tags access on highway.way_id = access.way_id and access.k = 'access'*/
left join way_tags oneway on highway.way_id = oneway.way_id and oneway.k = 'oneway'
where highway.k = 'highway'
and highway.v <> 'proposed'
;

/********** RoadElement.ManagingAuthority **********/

drop table if exists RoadElementManagingAuthority ;

Create Table RoadElementManagingAuthority As
select distinct graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id way_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id
from extra_toponym_city t  
join extra_config_graph cfg on 1=1
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
union -- pedestrian (squares)
select distinct graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id way_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id
  from extra_toponym_city t
  join extra_config_graph cfg on 1=1
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join relation_members r on  t.global_way_id  = r.member_id and r.member_type = 'W' 
  join relation_tags r_type on r.relation_id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.relation_id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
;

/********** RoadElement.InHamletOf *****************/

drop table if exists RoadElementHamlet ;

Create Table RoadElementHamlet As
select distinct cfg.graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id way_id,
       h.hamlet_id
from extra_toponym_city t
  join extra_config_graph cfg on 1=1
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join Hamlet h on h.hamlet_name = t.suburb and h.municipality_id = 'OS' || lpad(m.id::text,11,'0') || 'CO'
   where not ((t.suburb = '') IS NOT FALSE)
union -- pedestrian (squares)
select distinct cfg.graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id way_id,
       h.hamlet_id hamlet_id
  from extra_toponym_city t
  join extra_config_graph cfg on 1=1
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join relation_members r on t.global_way_id  = r.member_id and r.member_type = 'W' 
  join relation_tags r_type on r.relation_id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.relation_id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join Hamlet h on h.hamlet_name = t.suburb and h.municipality_id = 'OS' || lpad(m.id::text,11,'0') || 'CO'
  where not ((t.suburb = '') IS NOT FALSE);

/********** RoadElement.Route **********/

drop table if exists RoadElementRoute ;

Create Table RoadElementRoute As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id, ST_MakeLine(extra_ways.start_node,extra_ways.end_node) route
from ways 
  join extra_config_graph cfg on 1=1
join extra_toponym_city e on ways.id = e.global_way_id 
join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' and highway.v <> 'proposed'
join extra_ways on global_id = e.global_way_id and local_id = e.local_way_id
union -- pedestrian (squares)
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id, ST_MakeLine(extra_ways.start_node,extra_ways.end_node) route
from ways 
join extra_config_graph cfg on 1=1
join extra_toponym_city e on ways.id = e.global_way_id 
join extra_ways on global_id = e.global_way_id and local_id = e.local_way_id
join relation_members r on ways.id = r.member_id and r.member_type = 'W' 
join relation_tags r_type on r.relation_id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
join relation_tags r_pedestrian on r.relation_id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
;


/********** RoadElement.StartsAtNode **********/

drop table if exists RoadElementStartsAtNode ;

Create Table RoadElementStartsAtNode As
select distinct graph_uri,
'OS' || lpad(highway.way_id::text,11,'0') || 'RE/' || way_nodes.sequence_id way_id, 
'OS' || lpad(nodes.id::text,11,'0') || 'NO' start_node_id, 
'terminale (inizio o fine elemento stradale)' node_type,
ST_X(nodes.geom) long,
ST_Y(nodes.geom) lat
from way_tags highway 
join extra_config_graph cfg on 1=1
join (select distinct global_way_id from extra_toponym_city) e on highway.way_id = e.global_way_id 
join way_nodes on highway.way_id = way_nodes.way_id 
join nodes on way_nodes.node_id = nodes.id
join extra_ways on highway.way_id = extra_ways.global_id and way_nodes.sequence_id = extra_ways.local_id
where highway.k = 'highway' and highway.v <> 'proposed'
union -- pedestrian (squares)
select distinct graph_uri,
'OS' || lpad(highway.id::text,11,'0') || 'RE/' || way_nodes.sequence_id way_id, 
'OS' || lpad(nodes.id::text,11,'0') || 'NO' start_node_id, 
'terminale (inizio o fine elemento stradale)' node_type,
ST_X(nodes.geom) long,
ST_Y(nodes.geom) lat
from ways highway 
join extra_config_graph cfg on 1=1
join (select distinct global_way_id from extra_toponym_city) e on highway.id = e.global_way_id 
join way_nodes on highway.id = way_nodes.way_id 
join nodes on way_nodes.node_id = nodes.id
join extra_ways on highway.id = extra_ways.global_id and way_nodes.sequence_id = extra_ways.local_id
join relation_members r on highway.id = r.member_id and r.member_type = 'W' 
join relation_tags r_type on r.relation_id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
join relation_tags r_pedestrian on r.relation_id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
;

/********** RoadElement.EndsAtNode **********/

drop table if exists RoadElementEndsAtNode ;

Create Table RoadElementEndsAtNode As
select distinct graph_uri,
'OS' || lpad(highway.way_id::text,11,'0') || 'RE/' || (way_nodes.sequence_id-1) way_id, 
'OS' || lpad(nodes.id::text,11,'0') || 'NO' end_node_id, 
'terminale (inizio o fine elemento stradale)' node_type,
ST_X(nodes.geom) long,
ST_Y(nodes.geom) lat
from way_tags highway 
  join extra_config_graph cfg on 1=1
join (select distinct global_way_id from extra_toponym_city) e on highway.way_id = e.global_way_id 
join way_nodes on highway.way_id = way_nodes.way_id and way_nodes.sequence_id > 0
join nodes on way_nodes.node_id = nodes.id
join extra_ways on highway.way_id = extra_ways.global_id and way_nodes.sequence_id - 1 = extra_ways.local_id
where highway.k = 'highway' and highway.v <> 'proposed'
union -- pedestrian (squares)
select distinct graph_uri,
'OS' || lpad(highway.id::text,11,'0') || 'RE/' || (way_nodes.sequence_id-1) way_id, 
'OS' || lpad(nodes.id::text,11,'0') || 'NO' end_node_id, 
'terminale (inizio o fine elemento stradale)' node_type,
ST_X(nodes.geom) long,
ST_Y(nodes.geom) lat
from ways highway 
  join extra_config_graph cfg on 1=1
join (select distinct global_way_id from extra_toponym_city) e on highway.id = e.global_way_id 
join way_nodes on highway.id = way_nodes.way_id and way_nodes.sequence_id > 0
join nodes on way_nodes.node_id = nodes.id
join extra_ways on highway.id = extra_ways.global_id and way_nodes.sequence_id - 1 = extra_ways.local_id
join relation_members r on highway.id = r.member_id and r.member_type = 'W' 
join relation_tags r_type on r.relation_id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
join relation_tags r_pedestrian on r.relation_id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
;

/*****************************************
********* AdministrativeRoad *************
*****************************************/

drop table if exists AdministrativeRoad;

Create Table AdministrativeRoad As
select distinct 
	cfg.graph_uri,
	'OS' || lpad(rm.relation_id::text,11,'0') || 'LR/OS' || lpad(wt.way_id::text,11,'0') || 'AR' id,
	wt.v ad_road_name,
	lrn.extend_name alternative,
	lrt.road_type admin_class,
	'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id eid,
	ma.municipality_id  
from RoadRelationIdentifier lri
join RoadRelationType lrt on lri.id = lrt.id
join RoadRelationExtendName lrn on lri.id = lrn.id
join relation_members rm on cast(substring(lri.id from 3 for 11) as integer) = rm.relation_id and rm.member_type='W'
join way_tags wt on wt.way_id =  rm.member_id and wt.k = 'name'
join extra_toponym_city e on wt.way_id = e.global_way_id
join RoadElementManagingAuthority ma on ma.way_id = 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id
join extra_config_graph cfg on 1=1;

drop table if exists AdministrativeRoadNameGeneric;

create table AdministrativeRoadNameGeneric as
select cfg.graph_uri, ar.id, max(g.naming) ad_road_name_generic
from AdministrativeRoad ar
join extra_generic_namings g on lower(ar.ad_road_name) like lower(g.naming) || '%'
join extra_config_graph cfg on 1=1
group by cfg.graph_uri, ar.id;

drop table if exists AdministrativeRoadNameSpecific;

create table AdministrativeRoadNameSpecific as
select distinct cfg.graph_uri, ar.id, trim(substring(ar.ad_road_name from 1+char_length(argn.ad_road_name_generic))) ad_road_name_specific
from AdministrativeRoad ar
join AdministrativeRoadNameGeneric argn on ar.id = argn.id
join extra_config_graph cfg on 1=1;

/********** Road(WAY).RoadName **********/

drop table if exists RoadWayName;

create table RoadWayName As
select distinct cfg.graph_uri graph_uri, 
 'OS' || lpad(wt.global_id::text,11,'0') || 'SR' id,  
       way_name.v extend_name,
trim(substring(way_name.v, 1+char_length(coalesce(RoadWayType.road_type,'')))) road_name
  from extra_ways wt
  join extra_way_names way_name on wt.global_id = way_name.way_id 
  join extra_config_graph cfg on 1=1
  left join RoadWayType on RoadWayType.graph_uri = cfg.graph_uri and RoadWayType.id = 'OS' || lpad(wt.global_id::text,11,'0') || 'SR' and RoadWayType.extend_name = way_name.v
  left join 
(
select r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
) tbl on wt.global_id = tbl.member_id
 where way_name.k='name' and tbl.member_id is null
;

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso l'indirizzo ******
*********** indicato sul nodo ***********
****************************************/

drop table if exists NodeStreetNumberRoad ;

Create Table NodeStreetNumberRoad As
select cfg.graph_uri, extra_streetnumbers_on_nodes.*
  from extra_streetnumbers_on_nodes
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = node_source
;

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso le Relation ******
*********** di tipo associateStreet *****
****************************************/

drop table if exists RelationStreetNumberRoad ;

Create Table RelationStreetNumberRoad As
select cfg.graph_uri, extra_streetnumbers_on_relations.*
  from extra_streetnumbers_on_relations
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = 'Open Street Map'
;

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso il fatto che il **
*********** nodo è giunzione della Way **
****************************************/

drop table if exists NodeStreetNumberRoad2 ;

Create Table NodeStreetNumberRoad2 As
select cfg.graph_uri, extra_streetnumbers_on_junctions.*
  from extra_streetnumbers_on_junctions
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = 'Open Street Map'
;

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** scritti su di una way *******
*********** (building outline) e ********
*********** legati con la Road **********
*********** attraverso l'indirizzo ******
*********** indicato sulla way **********
****************************************/

drop table if exists WayStreetNumberRoad;

Create Table WayStreetNumberRoad As
select cfg.graph_uri, extra_streetnumbers_on_ways.*
  from extra_streetnumbers_on_ways
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = 'Open Street Map'
;

/********************************
*********** Milestone ***********
********************************/

drop table if exists Milestone ;

Create Table Milestone As
select graph_uri, 'OS' || lpad(nodes.id::text,11,'0') || 'MI' ml_id, 
       distance.v distance, 
       ST_Y(nodes.geom) lat, 
       ST_X(nodes.geom) long, 
       'OS' || lpad(way_nodes.way_id::text,11,'0') || 'RE/' || way_nodes.sequence_id re_id
from nodes 
join extra_config_graph cfg on 1=1
join node_tags milestone on nodes.id = milestone.node_id and milestone.k = 'highway' and milestone.v = 'milestone'
join node_tags distance on nodes.id = distance.node_id and distance.k = 'distance'
join way_nodes on way_nodes.node_id = milestone.node_id
join extra_toponym_city e on e.global_way_id = way_nodes.way_id 
;

/********************************
*********** EntryRule ***********
********************************/

drop table if exists EntryRule ;

Create Table EntryRule As
select *, 'OS' || lpad(q.way_id::text,11,'0') || 'RE/' || extra_ways.local_id re_id from (
select 'OS' || lpad(ways.id::text,11,'0') || 'NA' rl_id,
       --'OS' || lpad(ways.id::text,11,'0') || 'RE' re_id,
	ways.id way_id,
CASE 
WHEN temp_access.v = 'no' THEN 'Direzione flusso di traffico' 
WHEN temp_access.v is null and temp_oneway.v = 'yes' THEN 'Direzione flusso di traffico'
WHEN temp_access.v is null and temp_oneway.v = '-1' THEN 'Direzione flusso di traffico'
WHEN temp_access.v = 'destination' and temp_oneway.v = 'yes' THEN 'Passaggio bloccato'
WHEN temp_access.v = 'destination' and temp_oneway.v = '-1' THEN 'Passaggio bloccato'
ELSE '--'
END as restriction_type,
CASE 
WHEN temp_access.v = 'no' THEN 'Chiusa in entrambe le direzioni' 
WHEN temp_access.v is null and temp_oneway.v = 'yes' THEN 'Chiusa in direzione negativa'
WHEN temp_access.v is null and temp_oneway.v = '-1' THEN 'Chiusa in direzione positiva'
WHEN temp_access.v = 'destination' and temp_oneway.v = 'yes' THEN 'Blocco fisico sulla giunzione finale'
WHEN temp_access.v = 'destination' and temp_oneway.v = '-1' THEN 'Blocco fisico sulla giunzione iniziale'
ELSE '--'
END as restriction_value
from ways 
join extra_toponym_city e on e.global_way_id = ways.id 
join way_tags highway on ways.id = highway.way_id and highway.k = 'highway'
left join way_tags temp_access on ways.id = temp_access.way_id and temp_access.k = 'temporary:access'
left join way_tags temp_oneway on ways.id = temp_oneway.way_id and temp_oneway.k = 'temporary:oneway'
where highway.v <> 'proposed'
) q 
  join extra_config_graph cfg on 1=1
join extra_ways on extra_ways.global_id = q.way_id 
where restriction_type <> '--' and restriction_value <> '--'
;

/******************************
********* Region **************
******************************/

/*** Confini delle regioni ***/

drop table if exists extra_regioni;

create table extra_regioni as
select relations.id relation_id, extra_all_boundaries.centroid, extra_all_boundaries.boundary boundary, extra_all_boundaries.bbox bbox
from relations 
join relation_tags tag_type on relations.id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relations.id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relations.id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '4' 
join extra_all_boundaries on relations.id = extra_all_boundaries.relation_id
join extra_config_boundaries on ST_Covers(extra_all_boundaries.boundary, extra_config_boundaries.boundary);

create index extra_regioni_index_1 on extra_regioni using gist(centroid);

create index extra_regioni_index_2 on extra_regioni using gist(boundary);

create index extra_regioni_index_3 on extra_regioni using gist(bbox);

-- La tabella region_of_interest è stata soppressa perché la extra_regioni contiene tutte e sole le regioni di interesse

/********** Region URI **********/

drop table if exists RegionURI ;

Create table RegionURI As
  select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'RG' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '4'
  join extra_regioni region_of_interest on r.id = region_of_interest.relation_id 
  join extra_config_graph cfg on 1=1;

/********** Region.Identifier **********/

drop table if exists RegionIdentifier ;

Create table RegionIdentifier As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'RG' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '4'
  join extra_regioni region_of_interest on r.id = region_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/********** Region.Name **********/

drop table if exists RegionName ;

Create Table RegionName As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'RG' id,
       r_name.v p_name
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '4'
  join relation_tags r_name on r.id = r_name.relation_id and r_name.k = 'name'
  join extra_regioni region_of_interest on r.id = region_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;


/********** Region.Alternative **********/

drop table if exists RegionAlternative ;

Create Table RegionAlternative As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'RG' id,
       r_short_name.v alternative
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '4'
  join relation_tags r_short_name on r.id = r_short_name.relation_id and r_short_name.k = 'short_name'
  join extra_regioni region_of_interest on r.id = region_of_interest.relation_id 
  join extra_config_graph cfg on 1=1
;

/*********** Region.HasProvince ***********/

drop table if exists RegionHasProvince;

create table RegionHasProvince as
select 
	graph_uri, 
	'OS' || lpad(extra_regioni.relation_id::text,11,'0') || 'RG' id,
	'OS' || lpad(extra_province.relation_id::text,11,'0') || 'PR' has_province 
from extra_regioni 
join extra_province on ST_Covers(extra_regioni.boundary, extra_province.boundary)
join extra_config_graph cfg on 1=1;

/*******************************************
****************** Lanes & Restrictions ****
*******************************************/

drop table if exists i_node_tags;

create table i_node_tags as
select * from node_tags where not k like '%conditional%' 
union
select * from node_tags where k like '%conditional%' and (node_id, k) not in ( select node_id, k from (
select splitted.node_id, splitted.k, splitted.splitted_v from (
select *, unnest(regexp_split_to_array(v, ';(?![^\(]*\))')) splitted_v from node_tags  where k like '%conditional%' and v like '%;%'
) splitted 
join
(
select *, unnest(regexp_matches(v, '(;(?![^\(]*\)))([ \t]*)(yes|no|private|permissive|destination|delivery|customers|designated|use_sidepath|dismount|agricoltural|forestry|discouraged)')) matched_in_v from node_tags where k like '%conditional%' and v like '%;%'
) to_be_splitted
on splitted.node_id = to_be_splitted.node_id and splitted.k = to_be_splitted.k
) foo )
union 
select splitted.node_id, splitted.k, trim(splitted.splitted_v) v from (
select *, unnest(regexp_split_to_array(v, ';(?![^\(]*\))')) splitted_v from node_tags  where k like '%conditional%' and v like '%;%'
) splitted 
join
(
select *, unnest(regexp_matches(v, '(;(?![^\(]*\)))([ \t]*)(yes|no|private|permissive|destination|delivery|customers|designated|use_sidepath|dismount|agricoltural|forestry|discouraged)')) matched_in_v from node_tags where k like '%conditional%' and v like '%;%'
) to_be_splitted
on splitted.node_id = to_be_splitted.node_id and splitted.k = to_be_splitted.k
;

drop table if exists i_way_tags;

create table i_way_tags as
select * from way_tags where not k like '%conditional%' 
union
select * from way_tags where k like '%conditional%' and (way_id, k) not in ( select way_id, k from (
select splitted.way_id, splitted.k, splitted.splitted_v from (
select *, unnest(regexp_split_to_array(v, ';(?![^\(]*\))')) splitted_v from way_tags  where k like '%conditional%' and v like '%;%'
) splitted 
join
(
select *, unnest(regexp_matches(v, '(;(?![^\(]*\)))([ \t]*)(yes|no|private|permissive|destination|delivery|customers|designated|use_sidepath|dismount|agricoltural|forestry|discouraged)')) matched_in_v from way_tags where k like '%conditional%' and v like '%;%'
) to_be_splitted
on splitted.way_id = to_be_splitted.way_id and splitted.k = to_be_splitted.k
) foo )
union 
select splitted.way_id, splitted.k, trim(splitted.splitted_v) v from (
select *, unnest(regexp_split_to_array(v, ';(?![^\(]*\))')) splitted_v from way_tags  where k like '%conditional%' and v like '%;%'
) splitted 
join
(
select *, unnest(regexp_matches(v, '(;(?![^\(]*\)))([ \t]*)(yes|no|private|permissive|destination|delivery|customers|designated|use_sidepath|dismount|agricoltural|forestry|discouraged)')) matched_in_v from way_tags where k like '%conditional%' and v like '%;%'
) to_be_splitted
on splitted.way_id = to_be_splitted.way_id and splitted.k = to_be_splitted.k
;

drop table if exists i_relation_tags;

create table i_relation_tags as
select * from relation_tags where not k like '%conditional%' 
union
select * from relation_tags where k like '%conditional%' and (relation_id, k) not in ( select relation_id, k from (
select splitted.relation_id, splitted.k, splitted.splitted_v from (
select *, unnest(regexp_split_to_array(v, ';(?![^\(]*\))')) splitted_v from relation_tags  where k like '%conditional%' and v like '%;%'
) splitted 
join
(
select *, unnest(regexp_matches(v, '(;(?![^\(]*\)))([ \t]*)(yes|no|private|permissive|destination|delivery|customers|designated|use_sidepath|dismount|agricoltural|forestry|discouraged)')) matched_in_v from relation_tags where k like '%conditional%' and v like '%;%'
) to_be_splitted
on splitted.relation_id = to_be_splitted.relation_id and splitted.k = to_be_splitted.k
) foo )
union 
select splitted.relation_id, splitted.k, trim(splitted.splitted_v) v from (
select *, unnest(regexp_split_to_array(v, ';(?![^\(]*\))')) splitted_v from relation_tags  where k like '%conditional%' and v like '%;%'
) splitted 
join
(
select *, unnest(regexp_matches(v, '(;(?![^\(]*\)))([ \t]*)(yes|no|private|permissive|destination|delivery|customers|designated|use_sidepath|dismount|agricoltural|forestry|discouraged)')) matched_in_v from relation_tags where k like '%conditional%' and v like '%;%'
) to_be_splitted
on splitted.relation_id = to_be_splitted.relation_id and splitted.k = to_be_splitted.k
;

-- Turn Restrictions

drop table if exists turn_restrictions;

/*
create table turn_restrictions as
select graph.graph_uri, 
case when not from_relation.relation_uri is null then from_relation.relation_uri else 'OS' || lpad(from_way.member_id::text,11,'0') || 'SR' end from_uri, 
case when not to_relation.relation_uri is null then to_relation.relation_uri else 'OS' || lpad(to_way.member_id::text,11,'0') || 'SR' end to_uri, 
'OS' || lpad(via.member_id::text,11,'0') || 'NO' node_uri,
restriction_tag.v restriction,
tag_day_on.v day_on,
tag_day_off.v day_off,
tag_hour_on.v hour_on,
tag_hour_off.v hour_off,
tag_except.v exceptions 
from relation_tags relation_type
join relation_members from_way on relation_type.relation_id = from_way.relation_id and from_way.member_type = 'W' and from_way.member_role = 'from'
join relation_members to_way on relation_type.relation_id = to_way.relation_id and to_way.member_type = 'W' and to_way.member_role = 'to'
join relation_members via on relation_type.relation_id = via.relation_id and via.member_role = 'via' and via.member_type = 'N'
left join way_nodes via_way on via.member_type = 'W' and via.member_id = via_way.way_id and via_way.sequence_id = 0
left join nodes via_way_node on via_way.node_id = via_way_node.id
left join nodes via_node on via.member_type = 'N' and via.member_id = via_node.id
join relation_tags restriction_tag on relation_type.relation_id = restriction_tag.relation_id and restriction_tag.k = 'restriction'
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) from_relation on from_relation.member_id = from_way.member_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) to_relation on to_relation.member_id = to_way.member_id
left join relation_tags tag_day_on on relation_type.relation_id = tag_day_on.relation_id and tag_day_on.k = 'day_on'
left join relation_tags tag_day_off on relation_type.relation_id = tag_day_off.relation_id and tag_day_off.k = 'day_off'
left join relation_tags tag_hour_on on relation_type.relation_id = tag_hour_on.relation_id and tag_hour_on.k = 'hour_on'
left join relation_tags tag_hour_off on relation_type.relation_id = tag_hour_off.relation_id and tag_hour_off.k = 'hour_off'
left join relation_tags tag_except on relation_type.relation_id = tag_except.relation_id and tag_except.k = 'except'
--join extra_config_boundaries on ST_Covers(extra_config_boundaries.geom, coalesce(via_way_node.geom, via_node.geom))
join extra_all_boundaries boundaries on ST_Covers(boundaries.boundary, coalesce(via_way_node.geom, via_node.geom)) 
join extra_config_boundaries cfg_boundaries on boundaries.relation_id = cfg_boundaries.relation_id 
join extra_config_graph graph on 1=1
where relation_type.k = 'type' and relation_type.v = 'restriction';
*/

create table turn_restrictions as
select graph.graph_uri, 
'OS' || lpad(from_way.member_id::text,11,'0') || 'RE/' || (case when from_way_element.sequence_id = 0 or coalesce(from_oneway.v ,'--') = '-1' then from_way_element.sequence_id else from_way_element.sequence_id-1 end) from_uri,
'OS' || lpad(to_way.member_id::text,11,'0') || 'RE/' || (case when to_way_next_element.node_id is null then to_way_element.sequence_id - 1 when coalesce(to_oneway.v,'--') = '-1' and to_way_element.sequence_id > 0 then to_way_element.sequence_id - 1 else to_way_element.sequence_id end) to_uri,
'OS' || lpad(via.member_id::text,11,'0') || 'NO' node_uri,
restriction_tag.v restriction,
tag_day_on.v day_on,
tag_day_off.v day_off,
tag_hour_on.v hour_on,
tag_hour_off.v hour_off,
tag_except.v exceptions 
from relation_tags relation_type
join relation_members from_way on relation_type.relation_id = from_way.relation_id and from_way.member_type = 'W' and from_way.member_role = 'from'
join relation_members to_way on relation_type.relation_id = to_way.relation_id and to_way.member_type = 'W' and to_way.member_role = 'to'
join relation_members via on relation_type.relation_id = via.relation_id and via.member_role = 'via' and via.member_type = 'N'
join nodes via_node on via.member_id = via_node.id
join relation_tags restriction_tag on relation_type.relation_id = restriction_tag.relation_id and restriction_tag.k = 'restriction'
join way_nodes from_way_element on from_way.member_id = from_way_element.way_id and via.member_id = from_way_element.node_id
join way_nodes to_way_element on to_way.member_id = to_way_element.way_id and via.member_id = to_way_element.node_id
left join way_nodes to_way_next_element on to_way.member_id = to_way_next_element.way_id and to_way_next_element.sequence_id = to_way_element.sequence_id+1
left join relation_tags tag_day_on on relation_type.relation_id = tag_day_on.relation_id and tag_day_on.k = 'day_on'
left join relation_tags tag_day_off on relation_type.relation_id = tag_day_off.relation_id and tag_day_off.k = 'day_off'
left join relation_tags tag_hour_on on relation_type.relation_id = tag_hour_on.relation_id and tag_hour_on.k = 'hour_on'
left join relation_tags tag_hour_off on relation_type.relation_id = tag_hour_off.relation_id and tag_hour_off.k = 'hour_off'
left join relation_tags tag_except on relation_type.relation_id = tag_except.relation_id and tag_except.k = 'except'
left join way_tags from_oneway on from_way.member_id = from_oneway.way_id and from_oneway.k = 'oneway'
left join way_tags to_oneway on to_way.member_id = to_oneway.way_id and to_oneway.k = 'oneway'
join extra_all_boundaries boundaries on ST_Covers(boundaries.boundary, via_node.geom) 
join extra_config_boundaries cfg_boundaries on boundaries.relation_id = cfg_boundaries.relation_id 
join extra_config_graph graph on 1=1
where relation_type.k = 'type' and relation_type.v = 'restriction';

------ Access Restrictions

-- Access tags on nodes

drop table if exists node_access;

create table node_access as 
select 
graph.graph_uri, 
p_where,
p_access,
p_direction,
p_who,
nullif(trim(coalesce(readytouse_condition,'') || ' ' || coalesce(day_onoff,'') || ' ' || coalesce(date_onoff,'') || ' ' || coalesce(hour_onoff,'')),'') p_condition
from (
select 
'OS' || lpad(tag_access.node_id::text,11,'0') || 'NO' p_where, 
case when position('@' in tag_access.v) = 0 then tag_access.v else trim(substring(tag_access.v,1,-1+position('@' in tag_access.v))) end p_access, 
nullif(coalesce(tag_day_on.v,'') || case when tag_day_on.v is null or tag_day_off.v is null then '' else ' - ' end || coalesce(tag_day_off.v,''),'') day_onoff,
nullif(coalesce(tag_date_on.v,'') || case when tag_date_on.v is null or tag_date_off.v is null then '' else ' - ' end || coalesce(tag_date_off.v,'') ,'') date_onoff,
nullif(coalesce(tag_hour_on.v,'') || case when tag_hour_on.v is null or tag_hour_off.v is null then '' else ' - ' end || coalesce(tag_hour_off.v,''), '')  hour_onoff,
case when tag_access.k like '%forward%' then 'forward' when tag_access.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
case when position('@' in tag_access.v) > 1 then trim(substring(tag_access.v, 1+position('@' in tag_access.v))) else null end readytouse_condition
from nodes 
join i_node_tags tag_access on nodes.id = tag_access.node_id
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join node_tags tag_day_on on tag_access.node_id = tag_day_on.node_id and tag_day_on.k = 'day_on'
left join node_tags tag_day_off on tag_access.node_id = tag_day_off.node_id and tag_day_off.k = 'day_off'
left join node_tags tag_date_on on tag_access.node_id = tag_date_on.node_id and tag_date_on.k = 'date_on'
left join node_tags tag_date_off on tag_access.node_id = tag_date_off.node_id and tag_date_off.k = 'date_off'
left join node_tags tag_hour_on on tag_access.node_id = tag_hour_on.node_id and tag_hour_on.k = 'hour_on'
left join node_tags tag_hour_off on tag_access.node_id = tag_hour_off.node_id and tag_hour_off.k = 'hour_off'
left join land_based_transportation t on tag_access.k = t.description or tag_access.k like t.description || ':%' or tag_access.k like '%:' || t.description || ':%' or tag_access.k like '%:' || t.description 
where ( tag_access.k = 'access' or tag_access.k like 'access:%' or t.description is not null ) 
and ( resn.start_node_id is not null or reen.end_node_id is not null)
) node_access
join extra_config_graph graph on 1=1
where p_access in ('yes','no','private','permissive','destination','delivery','customers','designated','use_sidepath','dismount','agricoltural','forestry','discouraged','permit');

-- Access tags on ways

drop table if exists way_access;

create table way_access as 
select distinct
graph.graph_uri, 
p_where,
p_access,
p_direction,
p_who,
nullif(trim(coalesce(readytouse_condition,'') || ' ' || coalesce(day_onoff,'') || ' ' || coalesce(date_onoff,'') || ' ' || coalesce(hour_onoff,'')),'') p_condition
from (
select 
case when way_relation.relation_uri is null then 'OS' || lpad(tag_access.way_id::text,11,'0') || 'SR' else 'OS' || lpad(tag_access.way_id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
case when position('@' in tag_access.v) = 0 then tag_access.v else trim(substring(tag_access.v,1,-1+position('@' in tag_access.v))) end p_access, 
nullif(coalesce(tag_day_on.v,'') || case when tag_day_on.v is null or tag_day_off.v is null then '' else ' - ' end || coalesce(tag_day_off.v,''),'') day_onoff,
nullif(coalesce(tag_date_on.v,'') || case when tag_date_on.v is null or tag_date_off.v is null then '' else ' - ' end || coalesce(tag_date_off.v,'') ,'') date_onoff,
nullif(coalesce(tag_hour_on.v,'') || case when tag_hour_on.v is null or tag_hour_off.v is null then '' else ' - ' end || coalesce(tag_hour_off.v,''), '')  hour_onoff,
case when tag_access.k like '%forward%' then 'forward' when tag_access.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
case when position('@' in tag_access.v) > 1 then trim(substring(tag_access.v, 1+position('@' in tag_access.v))) else null end readytouse_condition
from 
ways 
join extra_ways on ways.id = extra_ways.global_id
join i_way_tags tag_access on ways.id = tag_access.way_id
left join way_tags tag_day_on on ways.id = tag_day_on.way_id and tag_day_on.k = 'day_on'
left join way_tags tag_day_off on ways.id = tag_day_off.way_id and tag_day_off.k = 'day_off'
left join way_tags tag_date_on on ways.id = tag_date_on.way_id and tag_date_on.k = 'date_on'
left join way_tags tag_date_off on ways.id = tag_date_off.way_id and tag_date_off.k = 'date_off'
left join way_tags tag_hour_on on ways.id = tag_hour_on.way_id and tag_hour_on.k = 'hour_on'
left join way_tags tag_hour_off on ways.id = tag_hour_off.way_id and tag_hour_off.k = 'hour_off'
left join land_based_transportation t on tag_access.k = t.description or tag_access.k like t.description || ':%' or tag_access.k like '%:' || t.description || ':%' or tag_access.k like '%:' || t.description 
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
where ( tag_access.k = 'access' or tag_access.k like 'access:%' or t.description is not null) 
) node_access
join extra_config_graph graph on 1=1
where p_access in ('yes','no','private','permissive','destination','delivery','customers','designated','use_sidepath','dismount','agricoltural','forestry','discouraged');

-- Access tags on relations

drop table if exists relation_access;

create table relation_access as 
select 
graph.graph_uri, 
p_where,
p_access,
p_direction,
p_who,
nullif(trim(coalesce(readytouse_condition,'') || ' ' || coalesce(day_onoff,'') || ' ' || coalesce(date_onoff,'') || ' ' || coalesce(hour_onoff,'')),'') p_condition
from (
select 
relations.relation_uri p_where, 
case when position('@' in tag_access.v) = 0 then tag_access.v else trim(substring(tag_access.v,1,-1+position('@' in tag_access.v))) end p_access, 
nullif(coalesce(tag_day_on.v,'') || case when tag_day_on.v is null or tag_day_off.v is null then '' else ' - ' end || coalesce(tag_day_off.v,''),'') day_onoff,
nullif(coalesce(tag_date_on.v,'') || case when tag_date_on.v is null or tag_date_off.v is null then '' else ' - ' end || coalesce(tag_date_off.v,'') ,'') date_onoff,
nullif(coalesce(tag_hour_on.v,'') || case when tag_hour_on.v is null or tag_hour_off.v is null then '' else ' - ' end || coalesce(tag_hour_off.v,''), '')  hour_onoff,
case when tag_access.k like '%forward%' then 'forward' when tag_access.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
case when position('@' in tag_access.v) > 1 then trim(substring(tag_access.v, 1+position('@' in tag_access.v))) else null end readytouse_condition
from 
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join i_relation_tags tag_access on relations.id = tag_access.relation_id
left join relation_tags tag_day_on on tag_access.relation_id = tag_day_on.relation_id and tag_day_on.k = 'day_on'
left join relation_tags tag_day_off on tag_access.relation_id = tag_day_off.relation_id and tag_day_off.k = 'day_off'
left join relation_tags tag_date_on on tag_access.relation_id = tag_date_on.relation_id and tag_date_on.k = 'date_on'
left join relation_tags tag_date_off on tag_access.relation_id = tag_date_off.relation_id and tag_date_off.k = 'date_off'
left join relation_tags tag_hour_on on tag_access.relation_id = tag_hour_on.relation_id and tag_hour_on.k = 'hour_on'
left join relation_tags tag_hour_off on tag_access.relation_id = tag_hour_off.relation_id and tag_hour_off.k = 'hour_off'
left join land_based_transportation t on tag_access.k = t.description or tag_access.k like t.description || ':%' or tag_access.k like '%:' || t.description || ':%' or tag_access.k like '%:' || t.description 
where ( tag_access.k = 'access' or tag_access.k like 'access:%' or t.description is not null ) 
) node_access
join extra_config_graph graph on 1=1
where p_access in ('yes','no','private','permissive','destination','delivery','customers','designated','use_sidepath','dismount','agricoltural','forestry','discouraged');

-- Oneway tags on nodes

drop table if exists node_oneway;

create table node_oneway as 
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
case when case when position('@' in tag_oneway.v) = 0 then tag_oneway.v else trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) end <> 'no' and tag_cycleway_opposite.node_id is null then 'no' else 'yes' end p_access,
case
when position('@' in tag_oneway.v) = 0 and (tag_oneway.v = 'yes' or tag_oneway.v = '1') then 'backward'
when position('@' in tag_oneway.v) > 0 and (trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = 'yes' or trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = '1') then 'backward'
when position('@' in tag_oneway.v) = 0 and tag_oneway.v = '-1' then 'forward'
when position('@' in tag_oneway.v) > 0 and trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = '-1' then 'forward'
when position('@' in tag_oneway.v) > 1 then trim(substring(tag_oneway.v, 1+position('@' in tag_oneway.v)))
else
case
when tag_oneway.v IN ('forward', 'backward') then tag_oneway.v
else 'forward'
end
end p_direction,
case when t.description is not null then t.description when coalesce(tag_ped_cycle.v,'') = 'pedestrian' then 'foot' when coalesce(tag_ped_cycle.v,'') = 'cycleway' or tag_cycleway_opposite.node_id is not null then 'bicycle' else 'vehicle' end p_who,
case when position('@' in tag_oneway.v) > 1 then trim(substring(tag_oneway.v, 1+position('@' in tag_oneway.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_oneway on nodes.id = tag_oneway.node_id and ( tag_oneway.k = 'oneway' or tag_oneway.k like '%:oneway:%' or tag_oneway.k like 'oneway:%' or tag_oneway.k like '%:oneway' )
left join land_based_transportation t on tag_oneway.k = t.description or tag_oneway.k like t.description || ':%' or tag_oneway.k like '%:' || t.description || ':%' or tag_oneway.k like '%:' || t.description 
left join node_tags tag_ped_cycle on nodes.id = tag_ped_cycle.node_id and tag_ped_cycle.k = 'highway' and tag_ped_cycle.v in ('pedestrian','cycleway')
left join node_tags tag_cycleway_opposite on nodes.id = tag_cycleway_opposite.node_id and tag_cycleway_opposite.k = 'cycleway' and tag_cycleway_opposite.v = 'opposite'
join extra_config_graph graph on 1=1
where ( resn.start_node_id is not null or reen.end_node_id is not null ) and 
(case when case when position('@' in tag_oneway.v) = 0 then tag_oneway.v else trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) end <> 'no' and tag_cycleway_opposite.node_id is null then 'no' else 'yes' end in ('yes', '1', '-1', 'no', 'reversible', 'alternating' ));

-- Oneway tags on ways

drop table if exists way_oneway;

create table way_oneway as 
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
case when case when position('@' in tag_oneway.v) = 0 then tag_oneway.v else trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) end <> 'no' and tag_cycleway_opposite.way_id is null then 'no' else 'yes' end p_access,
case
when position('@' in tag_oneway.v) = 0 and (tag_oneway.v = 'yes' or tag_oneway.v = '1') then 'backward'
when position('@' in tag_oneway.v) > 0 and (trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = 'yes' or trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = '1') then 'backward'
when position('@' in tag_oneway.v) = 0 and tag_oneway.v = '-1' then 'forward'
when position('@' in tag_oneway.v) > 0 and trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = '-1' then 'forward'
when position('@' in tag_oneway.v) > 1 then trim(substring(tag_oneway.v, 1+position('@' in tag_oneway.v)))
else
case
when tag_oneway.v IN ('forward', 'backward') then tag_oneway.v
else 'forward'
end
end p_direction,
case when t.description is not null then t.description when coalesce(tag_ped_cycle.v,'') = 'pedestrian' then 'foot' when coalesce(tag_ped_cycle.v,'') = 'cycleway' or tag_cycleway_opposite.way_id is not null then 'bicycle' else 'vehicle' end p_who,
case when position('@' in tag_oneway.v) > 1 then trim(substring(tag_oneway.v, 1+position('@' in tag_oneway.v))) else null end p_condition
from ways
join extra_ways on extra_ways.global_id = ways.id
join way_tags tag_oneway on ways.id = tag_oneway.way_id and ( tag_oneway.k = 'oneway' or tag_oneway.k like '%:oneway:%' or tag_oneway.k like 'oneway:%' or tag_oneway.k like '%:oneway' )
left join land_based_transportation t on tag_oneway.k = t.description or tag_oneway.k like t.description || ':%' or tag_oneway.k like '%:' || t.description || ':%' or tag_oneway.k like '%:' || t.description 
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
left join way_tags tag_ped_cycle on ways.id = tag_ped_cycle.way_id and tag_ped_cycle.k = 'highway' and tag_ped_cycle.v in ('pedestrian','cycleway')
left join way_tags tag_cycleway_opposite on ways.id = tag_cycleway_opposite.way_id and tag_cycleway_opposite.k = 'cycleway' and tag_cycleway_opposite.v = 'opposite'
join extra_config_graph graph on 1=1
where  
case when case when position('@' in tag_oneway.v) = 0 then tag_oneway.v else trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) end <> 'no' and tag_cycleway_opposite.way_id is null then 'no' else 'yes' end in ('yes', '1', '-1', 'no', 'reversible', 'alternating' )
;

-- Oneway tags on relations

drop table if exists relation_oneway;

create table relation_oneway as 
select distinct
graph.graph_uri, 
relations.relation_uri p_where,
case when case when position('@' in tag_oneway.v) = 0 then tag_oneway.v else trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) end <> 'no' and tag_cycleway_opposite.relation_id is null then 'no' else 'yes' end p_access,
case
when position('@' in tag_oneway.v) = 0 and (tag_oneway.v = 'yes' or tag_oneway.v = '1') then 'backward'
when position('@' in tag_oneway.v) > 0 and (trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = 'yes' or trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = '1') then 'backward'
when position('@' in tag_oneway.v) = 0 and tag_oneway.v = '-1' then 'forward'
when position('@' in tag_oneway.v) > 0 and trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) = '-1' then 'forward'
when position('@' in tag_oneway.v) > 1 then trim(substring(tag_oneway.v, 1+position('@' in tag_oneway.v)))
else
case
when tag_oneway.v IN ('forward', 'backward') then tag_oneway.v
else 'forward'
end
end p_direction,
case when t.description is not null then t.description when coalesce(tag_ped_cycle.v,'') = 'pedestrian' then 'foot' when coalesce(tag_ped_cycle.v,'') = 'cycleway' or tag_cycleway_opposite.relation_id is not null then 'bicycle' else 'vehicle' end p_who,
case when position('@' in tag_oneway.v) > 1 then trim(substring(tag_oneway.v, 1+position('@' in tag_oneway.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_oneway on relations.id = tag_oneway.relation_id and ( tag_oneway.k = 'oneway' or tag_oneway.k like '%:oneway:%' or tag_oneway.k like 'oneway:%' or tag_oneway.k like '%:oneway' )
left join land_based_transportation t on tag_oneway.k = t.description or tag_oneway.k like t.description || ':%' or tag_oneway.k like '%:' || t.description || ':%' or tag_oneway.k like '%:' || t.description 
left join relation_tags tag_ped_cycle on relations.id = tag_ped_cycle.relation_id and tag_ped_cycle.k = 'highway' and tag_ped_cycle.v in ('pedestrian','cycleway')
left join relation_tags tag_cycleway_opposite on relations.id = tag_cycleway_opposite.relation_id and tag_cycleway_opposite.k = 'cycleway' and tag_cycleway_opposite.v = 'opposite'
join extra_config_graph graph on 1=1
where 
case when case when position('@' in tag_oneway.v) = 0 then tag_oneway.v else trim(substring(tag_oneway.v,1,-1+position('@' in tag_oneway.v))) end <> 'no' and tag_cycleway_opposite.relation_id is null then 'no' else 'yes' end in ('yes', '1', '-1', 'no', 'reversible', 'alternating' )
;

----- Measure Restrictions

-- Measure Restrictions on Nodes

drop table if exists node_maxweight;

create table node_maxweight as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxweight' as varchar(255)) p_what,
case when position('@' in tag_maxweight.v) = 0 then tag_maxweight.v else trim(substring(tag_maxweight.v,1,-1+position('@' in tag_maxweight.v))) end p_limit, 
case when tag_maxweight.k like '%forward%' then 'forward' when tag_maxweight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxweight.v) > 1 then trim(substring(tag_maxweight.v, 1+position('@' in tag_maxweight.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxweight on nodes.id = tag_maxweight.node_id and 
trim(replace(replace(replace(replace(tag_maxweight.k,'maxweight',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_maxaxleload;

create table node_maxaxleload as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxaxleload' as varchar(255)) p_what,
case when position('@' in tag_maxaxleload.v) = 0 then tag_maxaxleload.v else trim(substring(tag_maxaxleload.v,1,-1+position('@' in tag_maxaxleload.v))) end p_limit, 
case when tag_maxaxleload.k like '%forward%' then 'forward' when tag_maxaxleload.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxaxleload.v) > 1 then trim(substring(tag_maxaxleload.v, 1+position('@' in tag_maxaxleload.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxaxleload on nodes.id = tag_maxaxleload.node_id and 
trim(replace(replace(replace(replace(tag_maxaxleload.k,'maxaxleload',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_maxheight;

create table node_maxheight as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxheight' as varchar(255)) p_what,
case when position('@' in tag_maxheight.v) = 0 then tag_maxheight.v else trim(substring(tag_maxheight.v,1,-1+position('@' in tag_maxheight.v))) end p_limit, 
case when tag_maxheight.k like '%forward%' then 'forward' when tag_maxheight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxheight.v) > 1 then trim(substring(tag_maxheight.v, 1+position('@' in tag_maxheight.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxheight on nodes.id = tag_maxheight.node_id and 
trim(replace(replace(replace(replace(tag_maxheight.k,'maxheight',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_maxwidth;

create table node_maxwidth as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxwidth' as varchar(255)) p_what,
case when position('@' in tag_maxwidth.v) = 0 then tag_maxwidth.v else trim(substring(tag_maxwidth.v,1,-1+position('@' in tag_maxwidth.v))) end p_limit, 
case when tag_maxwidth.k like '%forward%' then 'forward' when tag_maxwidth.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxwidth.v) > 1 then trim(substring(tag_maxwidth.v, 1+position('@' in tag_maxwidth.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxwidth on nodes.id = tag_maxwidth.node_id and
trim(replace(replace(replace(replace(tag_maxwidth.k,'maxwidth',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;
drop table if exists node_maxlength;

create table node_maxlength as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxlength' as varchar(255)) p_what,
case when position('@' in tag_maxlength.v) = 0 then tag_maxlength.v else trim(substring(tag_maxlength.v,1,-1+position('@' in tag_maxlength.v))) end p_limit, 
case when tag_maxlength.k like '%forward%' then 'forward' when tag_maxlength.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxlength.v) > 1 then trim(substring(tag_maxlength.v, 1+position('@' in tag_maxlength.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxlength on nodes.id = tag_maxlength.node_id and
trim(replace(replace(replace(replace(tag_maxlength.k,'maxlength',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_maxdraught;

create table node_maxdraught as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxdraught' as varchar(255)) p_what,
case when position('@' in tag_maxdraught.v) = 0 then tag_maxdraught.v else trim(substring(tag_maxdraught.v,1,-1+position('@' in tag_maxdraught.v))) end p_limit, 
case when tag_maxdraught.k like '%forward%' then 'forward' when tag_maxdraught.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxdraught.v) > 1 then trim(substring(tag_maxdraught.v, 1+position('@' in tag_maxdraught.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxdraught on nodes.id = tag_maxdraught.node_id and 
trim(replace(replace(replace(replace(tag_maxdraught.k,'maxdraught',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_maxspeed;

create table node_maxspeed as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxspeed' as varchar(255)) p_what,
case when position('@' in tag_maxspeed.v) = 0 then tag_maxspeed.v else trim(substring(tag_maxspeed.v,1,-1+position('@' in tag_maxspeed.v))) end p_limit, 
case when tag_maxspeed.k like '%forward%' then 'forward' when tag_maxspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxspeed.v) > 1 then trim(substring(tag_maxspeed.v, 1+position('@' in tag_maxspeed.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxspeed on nodes.id = tag_maxspeed.node_id and 
trim(replace(replace(replace(replace(tag_maxspeed.k,'maxspeed',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_minspeed;

create table node_minspeed as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'minspeed' as varchar(255)) p_what,
case when position('@' in tag_minspeed.v) = 0 then tag_minspeed.v else trim(substring(tag_minspeed.v,1,-1+position('@' in tag_minspeed.v))) end p_limit, 
case when tag_minspeed.k like '%forward%' then 'forward' when tag_minspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_minspeed.v) > 1 then trim(substring(tag_minspeed.v, 1+position('@' in tag_minspeed.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_minspeed on nodes.id = tag_minspeed.node_id and 
trim(replace(replace(replace(replace(tag_minspeed.k,'minspeed',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

drop table if exists node_maxstay;

create table node_maxstay as
select 
graph.graph_uri, 
coalesce(resn.start_node_id, reen.end_node_id) p_where,
cast(varchar 'maxstay' as varchar(255)) p_what,
case when position('@' in tag_maxstay.v) = 0 then tag_maxstay.v else trim(substring(tag_maxstay.v,1,-1+position('@' in tag_maxstay.v))) end p_limit, 
case when tag_maxstay.k like '%forward%' then 'forward' when tag_maxstay.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxstay.v) > 1 then trim(substring(tag_maxstay.v, 1+position('@' in tag_maxstay.v))) else null end p_condition
from nodes 
left join RoadElementStartsAtNode resn on resn.start_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
left join RoadElementEndsAtNode reen on reen.end_node_id = 'OS' || lpad(nodes.id::text,11,'0') || 'NO'
join node_tags tag_maxstay on nodes.id = tag_maxstay.node_id and 
trim(replace(replace(replace(replace(tag_maxstay.k,'maxstay',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1
where resn.start_node_id is not null or reen.end_node_id is not null ;

-- Measure Restrictions on Ways

drop table if exists way_maxweight;

create table way_maxweight as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxweight' as varchar(255)) p_what,
case when position('@' in tag_maxweight.v) = 0 then tag_maxweight.v else trim(substring(tag_maxweight.v,1,-1+position('@' in tag_maxweight.v))) end p_limit, 
case when tag_maxweight.k like '%forward%' then 'forward' when tag_maxweight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxweight.v) > 1 then trim(substring(tag_maxweight.v, 1+position('@' in tag_maxweight.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxweight on ways.id = tag_maxweight.way_id and 
trim(replace(replace(replace(replace(tag_maxweight.k,'maxweight',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxaxleload;

create table way_maxaxleload as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxaxleload' as varchar(255)) p_what,
case when position('@' in tag_maxaxleload.v) = 0 then tag_maxaxleload.v else trim(substring(tag_maxaxleload.v,1,-1+position('@' in tag_maxaxleload.v))) end p_limit, 
case when tag_maxaxleload.k like '%forward%' then 'forward' when tag_maxaxleload.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxaxleload.v) > 1 then trim(substring(tag_maxaxleload.v, 1+position('@' in tag_maxaxleload.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxaxleload on ways.id = tag_maxaxleload.way_id and 
trim(replace(replace(replace(replace(tag_maxaxleload.k,'maxaxleload',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxheight;

create table way_maxheight as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxheight' as varchar(255)) p_what,
case when position('@' in tag_maxheight.v) = 0 then tag_maxheight.v else trim(substring(tag_maxheight.v,1,-1+position('@' in tag_maxheight.v))) end p_limit, 
case when tag_maxheight.k like '%forward%' then 'forward' when tag_maxheight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxheight.v) > 1 then trim(substring(tag_maxheight.v, 1+position('@' in tag_maxheight.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxheight on ways.id = tag_maxheight.way_id and 
trim(replace(replace(replace(replace(tag_maxheight.k,'maxheight',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxwidth;

create table way_maxwidth as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxwidth' as varchar(255)) p_what,
case when position('@' in tag_maxwidth.v) = 0 then tag_maxwidth.v else trim(substring(tag_maxwidth.v,1,-1+position('@' in tag_maxwidth.v))) end p_limit, 
case when tag_maxwidth.k like '%forward%' then 'forward' when tag_maxwidth.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxwidth.v) > 1 then trim(substring(tag_maxwidth.v, 1+position('@' in tag_maxwidth.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxwidth on ways.id = tag_maxwidth.way_id and 
trim(replace(replace(replace(replace(tag_maxwidth.k,'maxwidth',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxlength;

create table way_maxlength as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxlength' as varchar(255)) p_what,
case when position('@' in tag_maxlength.v) = 0 then tag_maxlength.v else trim(substring(tag_maxlength.v,1,-1+position('@' in tag_maxlength.v))) end p_limit, 
case when tag_maxlength.k like '%forward%' then 'forward' when tag_maxlength.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxlength.v) > 1 then trim(substring(tag_maxlength.v, 1+position('@' in tag_maxlength.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxlength on ways.id = tag_maxlength.way_id and 
trim(replace(replace(replace(replace(tag_maxlength.k,'maxlength',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxdraught;

create table way_maxdraught as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxdraught' as varchar(255)) p_what,
case when position('@' in tag_maxdraught.v) = 0 then tag_maxdraught.v else trim(substring(tag_maxdraught.v,1,-1+position('@' in tag_maxdraught.v))) end p_limit, 
case when tag_maxdraught.k like '%forward%' then 'forward' when tag_maxdraught.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxdraught.v) > 1 then trim(substring(tag_maxdraught.v, 1+position('@' in tag_maxdraught.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxdraught on ways.id = tag_maxdraught.way_id and 
trim(replace(replace(replace(replace(tag_maxdraught.k,'maxdraught',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxspeed;

create table way_maxspeed as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxspeed' as varchar(255)) p_what,
case when position('@' in tag_maxspeed.v) = 0 then tag_maxspeed.v else trim(substring(tag_maxspeed.v,1,-1+position('@' in tag_maxspeed.v))) end p_limit, 
case when tag_maxspeed.k like '%forward%' then 'forward' when tag_maxspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxspeed.v) > 1 then trim(substring(tag_maxspeed.v, 1+position('@' in tag_maxspeed.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxspeed on ways.id = tag_maxspeed.way_id and trim(replace(replace(replace(replace(tag_maxspeed.k,'maxspeed',''),'forward',''),'backward',''),':','')) = '' 
join extra_config_graph graph on 1=1;

drop table if exists way_minspeed;

create table way_minspeed as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'minspeed' as varchar(255)) p_what,
case when position('@' in tag_minspeed.v) = 0 then tag_minspeed.v else trim(substring(tag_minspeed.v,1,-1+position('@' in tag_minspeed.v))) end p_limit, 
case when tag_minspeed.k like '%forward%' then 'forward' when tag_minspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_minspeed.v) > 1 then trim(substring(tag_minspeed.v, 1+position('@' in tag_minspeed.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_minspeed on ways.id = tag_minspeed.way_id and
trim(replace(replace(replace(replace(tag_minspeed.k,'minspeed',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists way_maxstay;

create table way_maxstay as
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
cast(varchar 'maxstay' as varchar(255)) p_what,
case when position('@' in tag_maxstay.v) = 0 then tag_maxstay.v else trim(substring(tag_maxstay.v,1,-1+position('@' in tag_maxstay.v))) end p_limit, 
case when tag_maxstay.k like '%forward%' then 'forward' when tag_maxstay.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxstay.v) > 1 then trim(substring(tag_maxstay.v, 1+position('@' in tag_maxstay.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxstay on ways.id = tag_maxstay.way_id and 
trim(replace(replace(replace(replace(tag_maxstay.k,'maxstay',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

-- Measure Restrictions on Relations

drop table if exists relation_maxweight;

create table relation_maxweight as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxweight' as varchar(255)) p_what,
case when position('@' in tag_maxweight.v) = 0 then tag_maxweight.v else trim(substring(tag_maxweight.v,1,-1+position('@' in tag_maxweight.v))) end p_limit, 
case when tag_maxweight.k like '%forward%' then 'forward' when tag_maxweight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxweight.v) > 1 then trim(substring(tag_maxweight.v, 1+position('@' in tag_maxweight.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxweight on relations.id = tag_maxweight.relation_id and 
trim(replace(replace(replace(replace(tag_maxweight.k,'maxweight',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxaxleload;

create table relation_maxaxleload as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxaxleload' as varchar(255)) p_what,
case when position('@' in tag_maxaxleload.v) = 0 then tag_maxaxleload.v else trim(substring(tag_maxaxleload.v,1,-1+position('@' in tag_maxaxleload.v))) end p_limit, 
case when tag_maxaxleload.k like '%forward%' then 'forward' when tag_maxaxleload.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxaxleload.v) > 1 then trim(substring(tag_maxaxleload.v, 1+position('@' in tag_maxaxleload.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxaxleload on relations.id = tag_maxaxleload.relation_id and 
trim(replace(replace(replace(replace(tag_maxaxleload.k,'maxaxleload',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxheight;

create table relation_maxheight as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxheight' as varchar(255)) p_what,
case when position('@' in tag_maxheight.v) = 0 then tag_maxheight.v else trim(substring(tag_maxheight.v,1,-1+position('@' in tag_maxheight.v))) end p_limit, 
case when tag_maxheight.k like '%forward%' then 'forward' when tag_maxheight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxheight.v) > 1 then trim(substring(tag_maxheight.v, 1+position('@' in tag_maxheight.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxheight on relations.id = tag_maxheight.relation_id and 
trim(replace(replace(replace(replace(tag_maxheight.k,'maxheight',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxwidth;

create table relation_maxwidth as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxwidth' as varchar(255)) p_what,
case when position('@' in tag_maxwidth.v) = 0 then tag_maxwidth.v else trim(substring(tag_maxwidth.v,1,-1+position('@' in tag_maxwidth.v))) end p_limit, 
case when tag_maxwidth.k like '%forward%' then 'forward' when tag_maxwidth.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxwidth.v) > 1 then trim(substring(tag_maxwidth.v, 1+position('@' in tag_maxwidth.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxwidth on relations.id = tag_maxwidth.relation_id and 
trim(replace(replace(replace(replace(tag_maxwidth.k,'maxwidth',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxlength;

create table relation_maxlength as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxlength' as varchar(255)) p_what,
case when position('@' in tag_maxlength.v) = 0 then tag_maxlength.v else trim(substring(tag_maxlength.v,1,-1+position('@' in tag_maxlength.v))) end p_limit, 
case when tag_maxlength.k like '%forward%' then 'forward' when tag_maxlength.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxlength.v) > 1 then trim(substring(tag_maxlength.v, 1+position('@' in tag_maxlength.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxlength on relations.id = tag_maxlength.relation_id and 
trim(replace(replace(replace(replace(tag_maxlength.k,'maxlength',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxdraught;

create table relation_maxdraught as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxdraught' as varchar(255)) p_what,
case when position('@' in tag_maxdraught.v) = 0 then tag_maxdraught.v else trim(substring(tag_maxdraught.v,1,-1+position('@' in tag_maxdraught.v))) end p_limit, 
case when tag_maxdraught.k like '%forward%' then 'forward' when tag_maxdraught.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxdraught.v) > 1 then trim(substring(tag_maxdraught.v, 1+position('@' in tag_maxdraught.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxdraught on relations.id = tag_maxdraught.relation_id and 
trim(replace(replace(replace(replace(tag_maxdraught.k,'maxdraught',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxspeed;

create table relation_maxspeed as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxspeed' as varchar(255)) p_what,
case when position('@' in tag_maxspeed.v) = 0 then tag_maxspeed.v else trim(substring(tag_maxspeed.v,1,-1+position('@' in tag_maxspeed.v))) end p_limit, 
case when tag_maxspeed.k like '%forward%' then 'forward' when tag_maxspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxspeed.v) > 1 then trim(substring(tag_maxspeed.v, 1+position('@' in tag_maxspeed.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxspeed on relations.id = tag_maxspeed.relation_id and 
trim(replace(replace(replace(replace(tag_maxspeed.k,'maxspeed',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_minspeed;

create table relation_minspeed as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'minspeed' as varchar(255)) p_what,
case when position('@' in tag_minspeed.v) = 0 then tag_minspeed.v else trim(substring(tag_minspeed.v,1,-1+position('@' in tag_minspeed.v))) end p_limit, 
case when tag_minspeed.k like '%forward%' then 'forward' when tag_minspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_minspeed.v) > 1 then trim(substring(tag_minspeed.v, 1+position('@' in tag_minspeed.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_minspeed on relations.id = tag_minspeed.relation_id and 
trim(replace(replace(replace(replace(tag_minspeed.k,'minspeed',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

drop table if exists relation_maxstay;

create table relation_maxstay as 
select 
graph.graph_uri, 
relations.relation_uri p_where,
cast(varchar 'maxstay' as varchar(255)) p_what,
case when position('@' in tag_maxstay.v) = 0 then tag_maxstay.v else trim(substring(tag_maxstay.v,1,-1+position('@' in tag_maxstay.v))) end p_limit, 
case when tag_maxstay.k like '%forward%' then 'forward' when tag_maxstay.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxstay.v) > 1 then trim(substring(tag_maxstay.v, 1+position('@' in tag_maxstay.v))) else null end p_condition
from
(
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxstay on relations.id = tag_maxstay.relation_id and 
trim(replace(replace(replace(replace(tag_maxstay.k,'maxstay',''),'forward',''),'backward',''),':','')) = ''
join extra_config_graph graph on 1=1;

------------- Lanes tagged on ways

-- Count

drop table if exists lanes_count;

create table lanes_count as 
select distinct
graph.graph_uri,
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where,
case when tag_lanes.k like '%forward%' then 'forward' when tag_lanes.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
tag_lanes.v lanes_count
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_lanes on ways.id = tag_lanes.way_id and tag_lanes.k like '%lanes%' and tag_lanes.v ~ '^[0-9\.]+$'
left join land_based_transportation t on tag_lanes.k = t.description or tag_lanes.k like t.description || ':%' or tag_lanes.k like '%:' || t.description || ':%' or tag_lanes.k like '%:' || t.description 
join extra_config_graph graph on 1=1
where trim(replace(replace(replace(replace(tag_lanes.k,coalesce(t.description,''),''),'forward',''),'backward',''),':','')) = 'lanes';

-- Turns

drop table if exists lanes_turn;

create table lanes_turn as
select distinct
graph_uri,
p_where,
p_direction,
pos,
turns[pos] turn
from 
(
select
graph.graph_uri,
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where,
case when tag_turn.k like '%forward%' then 'forward' when tag_turn.k like '%backward%' then 'backward' else null end p_direction ,
string_to_array(tag_turn.v, '|') turns,
generate_subscripts(string_to_array(tag_turn.v, '|'),1) as pos
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_turn on ways.id = tag_turn.way_id and tag_turn.k like '%turn%' and tag_turn.k like '%lanes%'
join extra_config_graph graph on 1=1
) unsorted_turns 
order by graph_uri, p_where, p_direction, pos; 

-- Access

drop table if exists lanes_access;

create table lanes_access as
select
graph_uri,
p_where,
p_direction,
p_who,
p_condition,
pos,
access_restrictions[pos] restriction
from 
(
select distinct
graph.graph_uri, 
p_where,
string_to_array(p_access, '|') access_restrictions,
generate_subscripts(string_to_array(p_access, '|'),1) pos,
p_direction,
p_who,
nullif(trim(coalesce(readytouse_condition,'') || ' ' || coalesce(day_onoff,'') || ' ' || coalesce(date_onoff,'') || ' ' || coalesce(hour_onoff,'')),'') p_condition
from (
select 
case when way_relation.relation_uri is null then 'OS' || lpad(tag_access.way_id::text,11,'0') || 'SR' else 'OS' || lpad(tag_access.way_id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
case when position('@' in tag_access.v) = 0 then tag_access.v else trim(substring(tag_access.v,1,-1+position('@' in tag_access.v))) end p_access, 
nullif(coalesce(tag_day_on.v,'') || case when tag_day_on.v is null or tag_day_off.v is null then '' else ' - ' end || coalesce(tag_day_off.v,''),'') day_onoff,
nullif(coalesce(tag_date_on.v,'') || case when tag_date_on.v is null or tag_date_off.v is null then '' else ' - ' end || coalesce(tag_date_off.v,'') ,'') date_onoff,
nullif(coalesce(tag_hour_on.v,'') || case when tag_hour_on.v is null or tag_hour_off.v is null then '' else ' - ' end || coalesce(tag_hour_off.v,''), '')  hour_onoff,
case when tag_access.k like '%forward%' then 'forward' when tag_access.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
case when position('@' in tag_access.v) > 1 then trim(substring(tag_access.v, 1+position('@' in tag_access.v))) else null end readytouse_condition
from 
ways 
join extra_ways on ways.id = extra_ways.global_id
join i_way_tags tag_access on ways.id = tag_access.way_id
left join way_tags tag_day_on on tag_access.way_id = tag_day_on.way_id and tag_day_on.k = 'day_on'
left join way_tags tag_day_off on tag_access.way_id = tag_day_off.way_id and tag_day_off.k = 'day_off'
left join way_tags tag_date_on on tag_access.way_id = tag_date_on.way_id and tag_date_on.k = 'date_on'
left join way_tags tag_date_off on tag_access.way_id = tag_date_off.way_id and tag_date_off.k = 'date_off'
left join way_tags tag_hour_on on tag_access.way_id = tag_hour_on.way_id and tag_hour_on.k = 'hour_on'
left join way_tags tag_hour_off on tag_access.way_id = tag_hour_off.way_id and tag_hour_off.k = 'hour_off'
left join land_based_transportation t on tag_access.k = t.description or tag_access.k like t.description || ':%' or tag_access.k like '%:' || t.description || ':%' or tag_access.k like '%:' || t.description 
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
where ( tag_access.k like '%lanes%' and ( tag_access.k like '%access%' or t.description is not null ) ) 
) node_access
join extra_config_graph graph on 1=1
) unsorted_restrictions
where access_restrictions[pos] in ('yes','no','private','permissive','destination','delivery','customers','designated','use_sidepath','dismount','agricoltural','forestry','discouraged')
order by graph_uri, p_where, p_direction, p_who, p_condition, pos;

-- Measures 

drop table if exists lanes_maxweight;

create table lanes_maxweight as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxweights[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxweight, '|') maxweights,
generate_subscripts(string_to_array(p_maxweight, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxweight' p_what,
case when position('@' in tag_maxweight.v) = 0 then tag_maxweight.v else trim(substring(tag_maxweight.v,1,-1+position('@' in tag_maxweight.v))) end p_maxweight, 
case when tag_maxweight.k like '%forward%' then 'forward' when tag_maxweight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxweight.v) > 1 then trim(substring(tag_maxweight.v, 1+position('@' in tag_maxweight.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxweight on ways.id = tag_maxweight.way_id and tag_maxweight.k like '%maxweight%' and tag_maxweight.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restriction
) unordered 
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxwidth;

create table lanes_maxwidth as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxwidths[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxwidth, '|') maxwidths,
generate_subscripts(string_to_array(p_maxwidth, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxwidth' p_what,
case when position('@' in tag_maxwidth.v) = 0 then tag_maxwidth.v else trim(substring(tag_maxwidth.v,1,-1+position('@' in tag_maxwidth.v))) end p_maxwidth, 
case when tag_maxwidth.k like '%forward%' then 'forward' when tag_maxwidth.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxwidth.v) > 1 then trim(substring(tag_maxwidth.v, 1+position('@' in tag_maxwidth.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxwidth on ways.id = tag_maxwidth.way_id and tag_maxwidth.k like '%maxwidth%' and tag_maxwidth.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unordered
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxaxleload;

create table lanes_maxaxleload as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxaxleloads[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxaxleload, '|') maxaxleloads,
generate_subscripts(string_to_array(p_maxaxleload, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxaxleload' p_what,
case when position('@' in tag_maxaxleload.v) = 0 then tag_maxaxleload.v else trim(substring(tag_maxaxleload.v,1,-1+position('@' in tag_maxaxleload.v))) end p_maxaxleload, 
case when tag_maxaxleload.k like '%forward%' then 'forward' when tag_maxaxleload.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxaxleload.v) > 1 then trim(substring(tag_maxaxleload.v, 1+position('@' in tag_maxaxleload.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxaxleload on ways.id = tag_maxaxleload.way_id and tag_maxaxleload.k like '%maxaxleload%' and tag_maxaxleload.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restriction
) unordered
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxheight;

create table lanes_maxheight as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxheights[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxheight, '|') maxheights,
generate_subscripts(string_to_array(p_maxheight, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxheight' p_what,
case when position('@' in tag_maxheight.v) = 0 then tag_maxheight.v else trim(substring(tag_maxheight.v,1,-1+position('@' in tag_maxheight.v))) end p_maxheight, 
case when tag_maxheight.k like '%forward%' then 'forward' when tag_maxheight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxheight.v) > 1 then trim(substring(tag_maxheight.v, 1+position('@' in tag_maxheight.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxheight on ways.id = tag_maxheight.way_id and tag_maxheight.k like '%maxheight%' and tag_maxheight.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxlength;

create table lanes_maxlength as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxlengths[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxlength, '|') maxlengths,
generate_subscripts(string_to_array(p_maxlength, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxlength' p_what,
case when position('@' in tag_maxlength.v) = 0 then tag_maxlength.v else trim(substring(tag_maxlength.v,1,-1+position('@' in tag_maxlength.v))) end p_maxlength, 
case when tag_maxlength.k like '%forward%' then 'forward' when tag_maxlength.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxlength.v) > 1 then trim(substring(tag_maxlength.v, 1+position('@' in tag_maxlength.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxlength on ways.id = tag_maxlength.way_id and tag_maxlength.k like '%maxlength%' and tag_maxlength.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxdraught;

create table lanes_maxdraught as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxdraughts[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxdraught, '|') maxdraughts,
generate_subscripts(string_to_array(p_maxdraught, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxdraught' p_what,
case when position('@' in tag_maxdraught.v) = 0 then tag_maxdraught.v else trim(substring(tag_maxdraught.v,1,-1+position('@' in tag_maxdraught.v))) end p_maxdraught, 
case when tag_maxdraught.k like '%forward%' then 'forward' when tag_maxdraught.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxdraught.v) > 1 then trim(substring(tag_maxdraught.v, 1+position('@' in tag_maxdraught.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxdraught on ways.id = tag_maxdraught.way_id and tag_maxdraught.k like '%maxdraught%' and tag_maxdraught.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxspeed;

create table lanes_maxspeed as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxspeeds[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxspeed, '|') maxspeeds,
generate_subscripts(string_to_array(p_maxspeed, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxspeed' p_what,
case when position('@' in tag_maxspeed.v) = 0 then tag_maxspeed.v else trim(substring(tag_maxspeed.v,1,-1+position('@' in tag_maxspeed.v))) end p_maxspeed, 
case when tag_maxspeed.k like '%forward%' then 'forward' when tag_maxspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxspeed.v) > 1 then trim(substring(tag_maxspeed.v, 1+position('@' in tag_maxspeed.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxspeed on ways.id = tag_maxspeed.way_id and tag_maxspeed.k like '%maxspeed%' and tag_maxspeed.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_minspeed;

create table lanes_minspeed as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
minspeeds[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_minspeed, '|') minspeeds,
generate_subscripts(string_to_array(p_minspeed, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'minspeed' p_what,
case when position('@' in tag_minspeed.v) = 0 then tag_minspeed.v else trim(substring(tag_minspeed.v,1,-1+position('@' in tag_minspeed.v))) end p_minspeed, 
case when tag_minspeed.k like '%forward%' then 'forward' when tag_minspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_minspeed.v) > 1 then trim(substring(tag_minspeed.v, 1+position('@' in tag_minspeed.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_minspeed on ways.id = tag_minspeed.way_id and tag_minspeed.k like '%minspeed%' and tag_minspeed.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

drop table if exists lanes_maxstay;

create table lanes_maxstay as
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxstays[pos] p_limit
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxstay, '|') maxstays,
generate_subscripts(string_to_array(p_maxstay, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
case when way_relation.relation_uri is null then 'OS' || lpad(ways.id::text,11,'0') || 'SR' else 'OS' || lpad(ways.id::text,11,'0') || 'RE/' || extra_ways.local_id end p_where, 
'maxstay' p_what,
case when position('@' in tag_maxstay.v) = 0 then tag_maxstay.v else trim(substring(tag_maxstay.v,1,-1+position('@' in tag_maxstay.v))) end p_maxstay, 
case when tag_maxstay.k like '%forward%' then 'forward' when tag_maxstay.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxstay.v) > 1 then trim(substring(tag_maxstay.v, 1+position('@' in tag_maxstay.v))) else null end p_condition
from ways
join extra_ways on ways.id = extra_ways.global_id
left join (
select distinct 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) way_relation on ways.id = way_relation.member_id
join way_tags tag_maxstay on ways.id = tag_maxstay.way_id and tag_maxstay.k like '%maxstay%' and tag_maxstay.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

------------ Lanes tagged on relations

-- Count

insert into lanes_count
select distinct
graph.graph_uri,
relations.relation_uri p_where,
case when tag_lanes.k like '%forward%' then 'forward' when tag_lanes.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
tag_lanes.v lanes_count
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_lanes on relations.id = tag_lanes.relation_id and tag_lanes.k like '%lanes%' and tag_lanes.v ~ '^[0-9\.]+$'
left join land_based_transportation t on tag_lanes.k = t.description or tag_lanes.k like t.description || ':%' or tag_lanes.k like '%:' || t.description || ':%' or tag_lanes.k like '%:' || t.description 
join extra_config_graph graph on 1=1
where trim(replace(replace(replace(replace(tag_lanes.k,coalesce(t.description,''),''),'forward',''),'backward',''),':','')) = 'lanes';

-- Turns

insert into lanes_turn 
select distinct
graph_uri,
p_where,
p_direction,
pos,
turns[pos] turn
from 
(
select
graph.graph_uri,
relations.relation_uri p_where,
case when tag_turn.k like '%forward%' then 'forward' when tag_turn.k like '%backward%' then 'backward' else null end p_direction ,
string_to_array(tag_turn.v, '|') turns,
generate_subscripts(string_to_array(tag_turn.v, '|'),1) as pos
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_turn on relations.id = tag_turn.relation_id and tag_turn.k like '%turn%' and tag_turn.k like '%lanes%'
join extra_config_graph graph on 1=1
) unsorted_turns 
order by graph_uri, p_where, p_direction, pos; 

-- Access

insert into lanes_access 
select
graph_uri,
p_where,
p_direction,
p_who,
p_condition,
pos,
access_restrictions[pos] restriction
from 
(
select distinct
graph.graph_uri, 
p_where,
string_to_array(p_access, '|') access_restrictions,
generate_subscripts(string_to_array(p_access, '|'),1) pos,
p_direction,
p_who,
nullif(trim(coalesce(readytouse_condition,'') || ' ' || coalesce(day_onoff,'') || ' ' || coalesce(date_onoff,'') || ' ' || coalesce(hour_onoff,'')),'') p_condition
from (
select 
relations.relation_uri p_where, 
case when position('@' in tag_access.v) = 0 then tag_access.v else trim(substring(tag_access.v,1,-1+position('@' in tag_access.v))) end p_access, 
nullif(coalesce(tag_day_on.v,'') || case when tag_day_on.v is null or tag_day_off.v is null then '' else ' - ' end || coalesce(tag_day_off.v,''),'') day_onoff,
nullif(coalesce(tag_date_on.v,'') || case when tag_date_on.v is null or tag_date_off.v is null then '' else ' - ' end || coalesce(tag_date_off.v,'') ,'') date_onoff,
nullif(coalesce(tag_hour_on.v,'') || case when tag_hour_on.v is null or tag_hour_off.v is null then '' else ' - ' end || coalesce(tag_hour_off.v,''), '')  hour_onoff,
case when tag_access.k like '%forward%' then 'forward' when tag_access.k like '%backward%' then 'backward' else null end p_direction ,
t.description p_who ,
case when position('@' in tag_access.v) > 1 then trim(substring(tag_access.v, 1+position('@' in tag_access.v))) else null end readytouse_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join i_relation_tags tag_access on relations.id = tag_access.relation_id
left join relation_tags tag_day_on on tag_access.relation_id = tag_day_on.relation_id and tag_day_on.k = 'day_on'
left join relation_tags tag_day_off on tag_access.relation_id = tag_day_off.relation_id and tag_day_off.k = 'day_off'
left join relation_tags tag_date_on on tag_access.relation_id = tag_date_on.relation_id and tag_date_on.k = 'date_on'
left join relation_tags tag_date_off on tag_access.relation_id = tag_date_off.relation_id and tag_date_off.k = 'date_off'
left join relation_tags tag_hour_on on tag_access.relation_id = tag_hour_on.relation_id and tag_hour_on.k = 'hour_on'
left join relation_tags tag_hour_off on tag_access.relation_id = tag_hour_off.relation_id and tag_hour_off.k = 'hour_off'
left join land_based_transportation t on tag_access.k = t.description or tag_access.k like t.description || ':%' or tag_access.k like '%:' || t.description || ':%' or tag_access.k like '%:' || t.description 
where ( tag_access.k like '%lanes%' and ( tag_access.k like '%access%' or t.description is not null ) ) 
) node_access
join extra_config_graph graph on 1=1
) unsorted_restrictions
where access_restrictions[pos] in ('yes','no','private','permissive','destination','delivery','customers','designated','use_sidepath','dismount','agricoltural','forestry','discouraged')
order by graph_uri, p_where, p_direction, p_who, p_condition, pos;

-- Measures 

insert into lanes_maxweight 
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxweights[pos] maxweight
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxweight, '|') maxweights,
generate_subscripts(string_to_array(p_maxweight, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxweight' p_what,
case when position('@' in tag_maxweight.v) = 0 then tag_maxweight.v else trim(substring(tag_maxweight.v,1,-1+position('@' in tag_maxweight.v))) end p_maxweight, 
case when tag_maxweight.k like '%forward%' then 'forward' when tag_maxweight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxweight.v) > 1 then trim(substring(tag_maxweight.v, 1+position('@' in tag_maxweight.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxweight on relations.id = tag_maxweight.relation_id and tag_maxweight.k like '%maxweight%' and tag_maxweight.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restriction
) unordered 
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxwidth 
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxwidths[pos] maxwidths
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxwidth, '|') maxwidths,
generate_subscripts(string_to_array(p_maxwidth, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxwidth' p_what,
case when position('@' in tag_maxwidth.v) = 0 then tag_maxwidth.v else trim(substring(tag_maxwidth.v,1,-1+position('@' in tag_maxwidth.v))) end p_maxwidth, 
case when tag_maxwidth.k like '%forward%' then 'forward' when tag_maxwidth.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxwidth.v) > 1 then trim(substring(tag_maxwidth.v, 1+position('@' in tag_maxwidth.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxwidth on relations.id = tag_maxwidth.relation_id and tag_maxwidth.k like '%maxwidth%' and tag_maxwidth.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unordered
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxaxleload
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxaxleloads[pos] maxaxleload
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxaxleload, '|') maxaxleloads,
generate_subscripts(string_to_array(p_maxaxleload, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxaxleload' p_what,
case when position('@' in tag_maxaxleload.v) = 0 then tag_maxaxleload.v else trim(substring(tag_maxaxleload.v,1,-1+position('@' in tag_maxaxleload.v))) end p_maxaxleload, 
case when tag_maxaxleload.k like '%forward%' then 'forward' when tag_maxaxleload.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxaxleload.v) > 1 then trim(substring(tag_maxaxleload.v, 1+position('@' in tag_maxaxleload.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxaxleload on relations.id = tag_maxaxleload.relation_id and tag_maxaxleload.k like '%maxaxleload%' and tag_maxaxleload.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restriction
) unordered
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxheight 
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxheights[pos] maxheight
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxheight, '|') maxheights,
generate_subscripts(string_to_array(p_maxheight, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxheight' p_what,
case when position('@' in tag_maxheight.v) = 0 then tag_maxheight.v else trim(substring(tag_maxheight.v,1,-1+position('@' in tag_maxheight.v))) end p_maxheight, 
case when tag_maxheight.k like '%forward%' then 'forward' when tag_maxheight.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxheight.v) > 1 then trim(substring(tag_maxheight.v, 1+position('@' in tag_maxheight.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxheight on relations.id = tag_maxheight.relation_id and tag_maxheight.k like '%maxheight%' and tag_maxheight.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxlength 
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxlengths[pos] maxlength
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxlength, '|') maxlengths,
generate_subscripts(string_to_array(p_maxlength, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxlength' p_what,
case when position('@' in tag_maxlength.v) = 0 then tag_maxlength.v else trim(substring(tag_maxlength.v,1,-1+position('@' in tag_maxlength.v))) end p_maxlength, 
case when tag_maxlength.k like '%forward%' then 'forward' when tag_maxlength.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxlength.v) > 1 then trim(substring(tag_maxlength.v, 1+position('@' in tag_maxlength.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxlength on relations.id = tag_maxlength.relation_id and tag_maxlength.k like '%maxlength%' and tag_maxlength.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxdraught
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxdraughts[pos] maxdraught
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxdraught, '|') maxdraughts,
generate_subscripts(string_to_array(p_maxdraught, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxdraught' p_what,
case when position('@' in tag_maxdraught.v) = 0 then tag_maxdraught.v else trim(substring(tag_maxdraught.v,1,-1+position('@' in tag_maxdraught.v))) end p_maxdraught, 
case when tag_maxdraught.k like '%forward%' then 'forward' when tag_maxdraught.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxdraught.v) > 1 then trim(substring(tag_maxdraught.v, 1+position('@' in tag_maxdraught.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxdraught on relations.id = tag_maxdraught.relation_id and tag_maxdraught.k like '%maxdraught%' and tag_maxdraught.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxspeed
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxspeeds[pos] maxspeed
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxspeed, '|') maxspeeds,
generate_subscripts(string_to_array(p_maxspeed, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxspeed' p_what,
case when position('@' in tag_maxspeed.v) = 0 then tag_maxspeed.v else trim(substring(tag_maxspeed.v,1,-1+position('@' in tag_maxspeed.v))) end p_maxspeed, 
case when tag_maxspeed.k like '%forward%' then 'forward' when tag_maxspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxspeed.v) > 1 then trim(substring(tag_maxspeed.v, 1+position('@' in tag_maxspeed.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxspeed on relations.id = tag_maxspeed.relation_id and tag_maxspeed.k like '%maxspeed%' and tag_maxspeed.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_minspeed
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
minspeeds[pos] minspeed
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_minspeed, '|') minspeeds,
generate_subscripts(string_to_array(p_minspeed, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'minspeed' p_what,
case when position('@' in tag_minspeed.v) = 0 then tag_minspeed.v else trim(substring(tag_minspeed.v,1,-1+position('@' in tag_minspeed.v))) end p_minspeed, 
case when tag_minspeed.k like '%forward%' then 'forward' when tag_minspeed.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_minspeed.v) > 1 then trim(substring(tag_minspeed.v, 1+position('@' in tag_minspeed.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_minspeed on relations.id = tag_minspeed.relation_id and tag_minspeed.k like '%minspeed%' and tag_minspeed.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

insert into lanes_maxstay
select 
graph_uri,
p_where,
p_what,
p_direction,
p_condition,
pos,
maxstays[pos] maxstay
from 
(
select 
graph_uri,
p_where,
p_what,
string_to_array(p_maxstay, '|') maxstays,
generate_subscripts(string_to_array(p_maxstay, '|'), 1 ) pos,
p_direction,
p_condition
from (
select distinct
graph.graph_uri, 
relations.relation_uri p_where, 
'maxstay' p_what,
case when position('@' in tag_maxstay.v) = 0 then tag_maxstay.v else trim(substring(tag_maxstay.v,1,-1+position('@' in tag_maxstay.v))) end p_maxstay, 
case when tag_maxstay.k like '%forward%' then 'forward' when tag_maxstay.k like '%backward%' then 'backward' else null end p_direction ,
case when position('@' in tag_maxstay.v) > 1 then trim(substring(tag_maxstay.v, 1+position('@' in tag_maxstay.v))) else null end p_condition
from (
select distinct r.id, 'OS' || lpad(r.id::text,11,'0') || 'LR' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
  left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
  left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join way_tags rwt on r_ways.member_id = rwt.way_id and rwt.k = 'highway'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
 where COALESCE(r_route.v,'road') = 'road'
   and COALESCE(r_network.v, '--') <> 'e-road' 
   and rwt.v <> 'proposed'  
 union -- pedestrian relations (squares)
select r.id, 'OS' || lpad(r.id::text,11,'0') || 'SQ' relation_uri, r_ways.member_id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'multipolygon'
  join relation_tags r_pedestrian on r.id = r_pedestrian.relation_id and r_pedestrian.k = 'highway' and r_pedestrian.v = 'pedestrian'
  join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
  join extra_toponym_city e on r_ways.member_id = e.global_way_id 
) relations
join relation_tags tag_maxstay on relations.id = tag_maxstay.relation_id and tag_maxstay.k like '%maxstay%' and tag_maxstay.k like '%lanes%'
join extra_config_graph graph on 1=1
) lanes_restrictions
) unsorted
order by graph_uri, p_where, p_what, p_direction, p_condition, pos;

-- Numeri civici ed accessi senza strada (indirizzo di tipo place)

drop table if exists extra_node_housenumber_without_street;

create table extra_node_housenumber_without_street as
select nodes.*, housenumber.v housenumber, place.v place 
from nodes
join node_tags housenumber on nodes.id = housenumber.node_id and housenumber.k = 'addr:housenumber'
join node_tags place on nodes.id = place.node_id and place.k = 'addr:place'
join extra_config_boundaries on ST_Covers(boundary, nodes.geom);

create index on extra_node_housenumber_without_street(id);
create index on extra_node_housenumber_without_street using gist(geom);

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

/*******************************************************************************************
*** Boundaries of residential, commercial, industrial, and administrative areas ************
*******************************************************************************************/

-- Adding geometries to Public Administrations
----------------------------------------------

drop table if exists RegionGeometry ;

Create Table RegionGeometry As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'RG' id,
       ST_AsText(eab.boundary) geometry
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '4'  
  join extra_regioni region_of_interest on r.id = region_of_interest.relation_id 
  join extra_all_boundaries eab on eab.relation_id = r.id 
  join extra_config_graph cfg on 1=1
;

drop table if exists ProvinceGeometry ;

Create Table ProvinceGeometry As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id,
       ST_AsText(eab.boundary) geometry
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join extra_province prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_all_boundaries eab on eab.relation_id = r.id 
  join extra_config_graph cfg on 1=1
;

drop table if exists MunicipalityGeometry ;

Create Table MunicipalityGeometry As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'CO' id,
       ST_AsText(eab.boundary) geometry
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '8'  
  join extra_comuni com_of_interest on r.id = com_of_interest.relation_id 
  join extra_all_boundaries eab on eab.relation_id = r.id 
  join extra_config_graph cfg on 1=1
;

-- NamedArea: ResidentialArea
-----------------------------

-- Relation site=housing

drop table if exists ResidentialArea;

Create Table ResidentialArea As
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'RAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_site on r.id = r_site.relation_id and r_site.k = 'site' and r_site.v in ('housing')
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
left join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
where cast(coalesce(r_admin_level.v,'10') as int) > 8
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Relation landuse=centre_zone|residential

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'RAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_landuse on r.id = r_landuse.relation_id and r_landuse.k = 'landuse' and r_landuse.v in ('centre_zone','residential')
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
left join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
left join ResidentialArea on ResidentialArea.area_id = 'OS' || lpad(r.id::text,11,'0') || 'RAR' 
where ResidentialArea.area_id is null and cast(coalesce(r_admin_level.v,'10') as int) > 8
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Relation place=city|city_block|hamlet|isolated_dwelling|neighbourhood|quarter|suburb|town|village

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'RAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_place on r.id = r_place.relation_id and r_place.k = 'place' and r_place.v in ('city', 'city_block','hamlet','isolated_dwelling','neighbourhood','quarter','suburb','town','village')
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
left join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
left join ResidentialArea on ResidentialArea.area_id = 'OS' || lpad(r.id::text,11,'0') || 'RAR' 
where ResidentialArea.area_id is null and cast(coalesce(r_admin_level.v,'10') as int) > 8
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Relation boundary=quarter|city_limit|civil|town|urban|limited_traffic_zone|village

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'RAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v in ('quarter','city_limit','civil','town','urban','limited_traffic_zone','village')
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
left join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
left join ResidentialArea on ResidentialArea.area_id = 'OS' || lpad(r.id::text,11,'0') || 'RAR' 
where ResidentialArea.area_id is null and cast(coalesce(r_admin_level.v,'10') as int) > 8
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Relation boundary=administrative, admin_level>8

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'RAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v in ('administrative')
join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and cast(r_admin_level.v as int) > 8
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
left join ResidentialArea on ResidentialArea.area_id = 'OS' || lpad(r.id::text,11,'0') || 'RAR' 
where ResidentialArea.area_id is null 
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Way site=housing

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(w.id::text,11,'0') || 'RAW' area_id, 
	w_name.v area_name, 
	case when left(w_name.k,5) = 'name:' then substring(w_name.k from 6) else null end name_language, 
	w.linestring boundary 
from ways w
join way_tags w_site on w.id = w_site.way_id and w_site.k = 'site' and w_site.v in ('housing')
left join way_tags w_name on w.id = w_name.way_id and w_name.k like 'name%'
left join relation_members rm on rm.member_id = w.id and rm.member_type = 'W'
left join ResidentialArea ra on ra.area_id = 'OS' || lpad(rm.relation_id::text,11,'0') || 'RAR'
join extra_config_graph cfg on 1=1
where ra.area_id is null
group by cfg.graph_uri, w.id, w_name.v, w_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Way landuse=centre_zone|residential

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(w.id::text,11,'0') || 'RAW' area_id, 
	w_name.v area_name, 
	case when left(w_name.k,5) = 'name:' then substring(w_name.k from 6) else null end name_language, 
	w.linestring boundary 
from ways w
join way_tags w_landuse on w.id = w_landuse.way_id and w_landuse.k = 'landuse' and w_landuse.v in ('centre_zone','residential')
left join way_tags w_name on w.id = w_name.way_id and w_name.k like 'name%'
left join relation_members rm on rm.member_id = w.id and rm.member_type = 'W'
left join ResidentialArea rar on rar.area_id = 'OS' || lpad(rm.relation_id::text,11,'0') || 'RAR'
left join ResidentialArea raw on raw.area_id = 'OS' || lpad(w.id::text,11,'0') || 'RAW' 
join extra_config_graph cfg on 1=1
where rar.area_id is null and raw.area_id is null
group by cfg.graph_uri, w.id, w_name.v, w_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Way place=city|city_block|hamlet|isolated_dwelling|neighbourhood|quarter|suburb|town|village

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(w.id::text,11,'0') || 'RAW' area_id, 
	w_name.v area_name, 
	case when left(w_name.k,5) = 'name:' then substring(w_name.k from 6) else null end name_language, 
	w.linestring boundary 
from ways w
join way_tags w_place on w.id = w_place.way_id and w_place.k = 'place' and w_place.v in ('city', 'city_block','hamlet','isolated_dwelling','neighbourhood','quarter','suburb','town','village')
left join way_tags w_name on w.id = w_name.way_id and w_name.k like 'name%'
left join relation_members rm on rm.member_id = w.id and rm.member_type = 'W'
left join ResidentialArea rar on rar.area_id = 'OS' || lpad(rm.relation_id::text,11,'0') || 'RAR'
left join ResidentialArea raw on raw.area_id = 'OS' || lpad(w.id::text,11,'0') || 'RAW' 
join extra_config_graph cfg on 1=1
where rar.area_id is null and raw.area_id is null
group by cfg.graph_uri, w.id, w_name.v, w_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Way boundary=quarter|city_limit|civil|town|urban|limited_traffic_zone|village

insert into ResidentialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(w.id::text,11,'0') || 'RAW' area_id, 
	w_name.v area_name, 
	case when left(w_name.k,5) = 'name:' then substring(w_name.k from 6) else null end name_language, 
	w.linestring boundary 
from ways w
join way_tags w_place on w.id = w_place.way_id and w_place.k = 'boundary' and w_place.v in ('quarter','city_limit','civil','town','urban','limited_traffic_zone','village')
left join way_tags w_name on w.id = w_name.way_id and w_name.k like 'name%'
left join relation_members rm on rm.member_id = w.id and rm.member_type = 'W'
left join ResidentialArea rar on rar.area_id = 'OS' || lpad(rm.relation_id::text,11,'0') || 'RAR'
left join ResidentialArea raw on raw.area_id = 'OS' || lpad(w.id::text,11,'0') || 'RAW' 
join extra_config_graph cfg on 1=1
where rar.area_id is null and raw.area_id is null
group by cfg.graph_uri, w.id, w_name.v, w_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

update ResidentialArea
set linked_hamlet = linked_hamlets.hamlet_id, area_name = coalesce(linked_hamlets.area_name, linked_hamlets.hamlet_name)
from (
select c.area_id, c.area_name, nullif(array_to_string(array_agg(distinct h.hamlet_id), '|'),'') hamlet_id, nullif(array_to_string(array_agg(distinct h.hamlet_name), ', '),'') hamlet_name
from ResidentialArea c
left join Hamlet h
on ST_Intersects(ST_GeomFromText(c.geometry,4326), ST_SetSRID(ST_MakePoint(h.long, h.lat),4326))
group by c.area_id, c.area_name
) linked_hamlets
where ResidentialArea.area_id = linked_hamlets.area_id;

-- NamedArea: IndustrialArea
----------------------------

-- Relation landuse=industrial

drop table if exists IndustrialArea;

Create Table IndustrialArea As
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'IAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_landuse on r.id = r_landuse.relation_id and r_landuse.k = 'landuse' and r_landuse.v in ('industrial')
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Way landuse=industrial

insert into IndustrialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(w.id::text,11,'0') || 'IAW' area_id, 
	w_name.v area_name, 
	case when left(w_name.k,5) = 'name:' then substring(w_name.k from 6) else null end name_language, 
	w.linestring boundary 
from ways w
join way_tags w_landuse on w.id = w_landuse.way_id and w_landuse.k = 'landuse' and w_landuse.v in ('industrial')
left join way_tags w_name on w.id = w_name.way_id and w_name.k like 'name%'
left join relation_members rm on rm.member_id = w.id and rm.member_type = 'W'
left join ResidentialArea ra on ra.area_id = 'OS' || lpad(rm.relation_id::text,11,'0') || 'IAR'
join extra_config_graph cfg on 1=1
where ra.area_id is null
group by cfg.graph_uri, w.id, w_name.v, w_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

update IndustrialArea
set area_name = coalesce(area_industries.area_name, area_industries.industry_names)
from (
select c.area_id, c.area_name, nullif(array_to_string(array_agg(distinct wname.v),', '),'') industry_names
from IndustrialArea c
join ways w on ST_Intersects(ST_GeomFromText(c.geometry,4326), w.linestring)
join way_tags wname on w.id = wname.way_id and wname.k = 'name' 
join way_tags wbuilding on w.id = wbuilding.way_id and wbuilding.k = 'building' 
group by c.area_id, c.area_name
) area_industries
where IndustrialArea.area_id = area_industries.area_id;

update IndustrialArea
set linked_hamlet = linked_hamlets.hamlet_id, area_name = coalesce(linked_hamlets.area_name, linked_hamlets.hamlet_name)
from (
select c.area_id, c.area_name, nullif(array_to_string(array_agg(distinct h.hamlet_id), '|'),'') hamlet_id, nullif(array_to_string(array_agg(distinct h.hamlet_name), ', '),'') hamlet_name
from IndustrialArea c
left join Hamlet h
on ST_Intersects(ST_GeomFromText(c.geometry,4326), ST_SetSRID(ST_MakePoint(h.long, h.lat),4326))
group by c.area_id, c.area_name
) linked_hamlets
where IndustrialArea.area_id = linked_hamlets.area_id;

-- NamedArea: CommercialArea
----------------------------

-- Relation landuse=retail,commercial

drop table if exists CommercialArea;

Create Table CommercialArea As
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(r.id::text,11,'0') || 'CAR' area_id, 
	r_name.v area_name, 
	case when left(r_name.k,5) = 'name:' then substring(r_name.k from 6) else null end name_language, 
	(ST_Dump(ST_GeomFromText(ST_AsText(ST_LineMerge(ST_Collect(ways.linestring))),4326))).geom boundary 
from relations r
join relation_tags r_landuse on r.id = r_landuse.relation_id and r_landuse.k = 'landuse' and r_landuse.v in ('retail','commercial')
left join relation_tags r_name on r.id = r_name.relation_id and r_name.k like 'name%'
join relation_members r_ways on r_ways.relation_id = r.id and r_ways.member_type = 'W'
join ways on r_ways.member_id = ways.id
join extra_config_graph cfg on 1=1
group by cfg.graph_uri, r.id, r_name.v, r_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

-- Way landuse=commercial

insert into CommercialArea 
select distinct graph_uri, 'OS' || lpad(extra_comuni.relation_id::text,11,'0') || 'CO' municipality_id, area_id, area_name, name_language, ST_AsText(ST_MakePolygon(ST_AddPoint(tmp.boundary, ST_PointN(tmp.boundary, 1)))) geometry, null linked_hamlet from (
select distinct 
	cfg.graph_uri, 
	'OS' || lpad(w.id::text,11,'0') || 'CAW' area_id, 
	w_name.v area_name, 
	case when left(w_name.k,5) = 'name:' then substring(w_name.k from 6) else null end name_language, 
	w.linestring boundary 
from ways w
join way_tags w_landuse on w.id = w_landuse.way_id and w_landuse.k = 'landuse' and w_landuse.v in ('retail','commercial')
left join way_tags w_name on w.id = w_name.way_id and w_name.k like 'name%'
left join relation_members rm on rm.member_id = w.id and rm.member_type = 'W'
left join ResidentialArea ra on ra.area_id = 'OS' || lpad(rm.relation_id::text,11,'0') || 'CAR'
join extra_config_graph cfg on 1=1
where ra.area_id is null
group by cfg.graph_uri, w.id, w_name.v, w_name.k
) tmp
join extra_comuni on ST_Intersects(extra_comuni.boundary, tmp.boundary);

update CommercialArea
set area_name = coalesce(area_shops.area_name, area_shops.shop_names)
from (
select c.area_id, c.area_name, nullif(array_to_string(array_agg(distinct wname.v),', '),'') shop_names
from CommercialArea c
join ways w on ST_Intersects(ST_GeomFromText(c.geometry,4326), w.linestring)
join way_tags wname on w.id = wname.way_id and wname.k = 'name' 
join way_tags wbuilding on w.id = wbuilding.way_id and wbuilding.k = 'building' 
group by c.area_id, c.area_name
) area_shops
where CommercialArea.area_id = area_shops.area_id;

update CommercialArea
set linked_hamlet = linked_hamlets.hamlet_id, area_name = coalesce(linked_hamlets.area_name, linked_hamlets.hamlet_name)
from (
select c.area_id, c.area_name, nullif(array_to_string(array_agg(distinct h.hamlet_id), '|'),'') hamlet_id, nullif(array_to_string(array_agg(distinct h.hamlet_name), ', '),'') hamlet_name
from CommercialArea c
left join Hamlet h
on ST_Intersects(ST_GeomFromText(c.geometry,4326), ST_SetSRID(ST_MakePoint(h.long, h.lat),4326))
group by c.area_id, c.area_name
) linked_hamlets
where CommercialArea.area_id = linked_hamlets.area_id;

-- Street numbers from building names
-------------------------------------

drop table if exists extra_streetnumbers_on_building_names;

create table extra_streetnumbers_on_building_names as
select * from ( 
	select 
		'OS' || lpad(ways.id::text,11,'0') || 'BN' cn_id, 
		housenumber.v extend_number, 
		substring(housenumber.v FROM '[0-9]+') number,
		substring(housenumber.v FROM '[a-zA-Z]+') exponent,
		COALESCE(long_roads.road_id,short_roads.road_id) road_id,
		CASE 
			WHEN municipalities.m_name = any ('{Firenze,Genova,Savona}') and housenumber.v ilike '%r%' THEN 'Rosso'
			WHEN municipalities.m_name = any ('{Firenze,Genova,Savona}') and not housenumber.v ilike '%r%' THEN 'Nero'
			ELSE 'Privo colore'
		END as class_code,
		'OS' || lpad(nodes.id::text,11,'0') || 'BE' en_id,  
		'Accesso esterno diretto'::text entry_type,
		ST_X(nodes.geom) long,
		ST_Y(nodes.geom) lat,
		CASE 
			WHEN motor.node_id is not null 
			THEN 'Accesso carrabile' 
			ELSE 'Accesso non carrabile' 
		END as porte_cochere, 
		CASE 
			WHEN long_roads.road_id is null 
			THEN 'OS' || lpad(short_roads.a_global_way_id::text,11,'0') || 'RE/' || short_roads.a_local_way_id 
			ELSE 'OS' || lpad(long_roads.a_global_way_id::text,11,'0') || 'RE/' || long_roads.a_local_way_id 
		END as re_id,
		'Open Street Map'::text node_source,
		'--'::text native_node_ref,
		dense_rank() over (partition by ways.id, nodes.id order by ST_Distance(nodes.geom, COALESCE(long_roads.a_way_route,nodes.geom)), long_roads.road_id) as long_roads_way_rank,
		dense_rank() over (partition by ways.id, nodes.id order by ST_Distance(nodes.geom, COALESCE(short_roads.a_way_route,nodes.geom)), short_roads.road_id) as short_roads_way_rank,
		dense_rank() over (partition by ways.id order by coalesce(entrance.v,'ZZZ'), coalesce(motor.v,'ZZZ'), ST_Distance(nodes.geom, COALESCE(short_roads.a_way_route, long_roads.a_way_route )), way_nodes.sequence_id) as node_rank
	from ways
		join way_tags building on ways.id=building.way_id and building.k = 'building'
		join way_tags housenumber on ways.id = housenumber.way_id and housenumber.k = 'name' and housenumber.v ~ '^[0-9]{1,4}[a-zA-Z]{0,1}$'
		join way_nodes on ways.id = way_nodes.way_id and way_nodes.sequence_id = 0
		join nodes on way_nodes.node_id = nodes.id
		join extra_civicnum_municipalities municipalities on ST_Covers(municipalities.geom, nodes.geom)
		left join node_tags entrance on nodes.id = entrance.node_id and entrance.k in ('entrance','building','barrier')
		left join node_tags motor on nodes.id = motor.node_id and motor.k in ('motorcycle','motorcar')
		left join extra_tmp_1 long_roads on municipalities.relation_id = long_roads.municipality_relation_id and ST_Distance(long_roads.a_way_route,nodes.geom,false) < 100
		left join extra_tmp_2 short_roads on municipalities.relation_id = short_roads.municipality_relation_id and ST_Distance(short_roads.a_way_route,nodes.geom,false) < 100
		where COALESCE(long_roads.road_id,short_roads.road_id,'--') <> '--'
) q where long_roads_way_rank = 1 and short_roads_way_rank = 1 and node_rank = 1;

drop table if exists BuildingNameStreetNumberRoad;

Create Table BuildingNameStreetNumberRoad As
select cfg.graph_uri,extra_streetnumbers_on_building_names.*
  from extra_streetnumbers_on_building_names
  join extra_config_graph cfg on 1=1
  join extra_config_civic_num on 1=1
  where civic_num_source = 'Open Street Map'
;
