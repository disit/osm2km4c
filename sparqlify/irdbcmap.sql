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
   
/********************************************
************ TABELLE DI APPOGGIO ************
*********************************************/

-- Centroidi dei comuni di interesse

drop table if exists comuni_centroid_geom;

create table comuni_centroid_geom as
select com.relation_id, com.geom from (
select relation_id, ST_GeogFromText(ST_AsText(ST_Centroid(ST_Polygonize(linestring)))) geom, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) boundary from ( select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '8' 
join relation_tags catasto on relation_members.relation_id = catasto.relation_id and catasto.k = 'ref:catasto' -- taglio sugli italiani
order by relation_members.relation_id, relation_members.sequence_id
 ) com 
group by relation_id
) com join extra_config_boundaries boundaries on ST_Covers(boundaries.geom, com.geom) or boundaries.geom = com.boundary;

-- Confini dei comuni di interesse

drop table if exists comuni_border_geom ;

create table comuni_border_geom as
select com_border.* from 
(
select relation_id, 
ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom
from 
( 
select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring 
from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '8' 
join relation_tags catasto on relation_members.relation_id = catasto.relation_id and catasto.k = 'ref:catasto' -- taglio sugli italiani
order by relation_members.relation_id, relation_members.sequence_id
) com_border 
group by relation_id
) com_border
join comuni_centroid_geom com_centroid on com_border.relation_id = com_centroid.relation_id;

-- Centroidi delle province di interesse

drop table if exists province_centroid_geom ;

create table province_centroid_geom as
select prov.relation_id, prov.geom from (
select relation_id, ST_GeogFromText(ST_AsText(ST_Centroid(ST_Polygonize(linestring)))) geom, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) border from ( select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '6' 
order by relation_members.relation_id, relation_members.sequence_id
 ) prov 
group by relation_id
) prov join extra_config_boundaries boundaries on ST_Covers(boundaries.geom, prov.geom) or boundaries.geom = prov.border;


-- Confini delle province di interesse

drop table if exists province_border_geom ;

create table province_border_geom as
select provs_boundaries.* from (
select relation_id, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom from ( select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and admin_level.v = '6' 
left join relation_tags iso on relation_members.relation_id = iso.relation_id and iso.k = 'ISO3166-2'
where iso.relation_id is null or substring(iso.v,1,2) = 'IT'
order by relation_members.relation_id, relation_members.sequence_id
 ) provs group by relation_id
) provs_boundaries 
join province_centroid_geom provs_centroid on provs_boundaries.relation_id = provs_centroid.relation_id;

-- Corrispondenze tra comuni e province

drop table if exists extra_city_county ;

create table extra_city_county as
select comuni_centroid_geom.relation_id comune, province_short_name.v provincia
from comuni_centroid_geom, province_border_geom, relation_tags province_short_name
where ST_Covers(province_border_geom.geom,comuni_centroid_geom.geom)
and province_border_geom.relation_id = province_short_name.relation_id
and province_short_name.k = 'short_name';

-- Centroidi dei quartieri o frazioni di interesse

drop table if exists suburbs_centroid_geom ;

create table suburbs_centroid_geom as
select suburb.id, suburb.geom, suburb.suburb_type, suburb.suburb_name, comuni_border_geom.relation_id municipality_id
from 
(
-- suburb ways
select ways.id, ST_GeogFromText(ST_AsText(ST_Centroid(ST_GeomFromWKB(ST_AsBinary(ways.linestring))))) geom, 'W'::text suburb_type, way_suburb_name.v suburb_name from ways 
join way_tags boundary on ways.id = boundary.way_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join way_tags admin_level on ways.id = admin_level.way_id and admin_level.k = 'admin_level' and cast(admin_level.v as int) > 8 
join way_tags way_suburb_name on ways.id = way_suburb_name.way_id and way_suburb_name.k = 'name'
union
-- suburb relations
select rsuburbs.*, rel_suburb_name.v suburb_name from 
(
select relation_id id, ST_GeogFromText(ST_AsText(ST_Centroid(ST_Polygonize(linestring)))) geom, 'R'::text suburb_type from ( select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and cast(admin_level.v as int) > 8 
order by relation_members.relation_id, relation_members.sequence_id
 ) sub group by relation_id
) rsuburbs 
join relation_tags rel_suburb_name on rsuburbs.id = rel_suburb_name.relation_id and rel_suburb_name.k = 'name'
union
-- suburb nodes
select id, ST_GeogFromWKB(ST_AsBinary(geom)), 'N'::text suburb_type, nd_suburb_name.v suburb_name from nodes join node_tags on nodes.id = node_tags.node_id and node_tags.k = 'place' and node_tags.v = 'suburb' join node_tags nd_suburb_name on nodes.id = nd_suburb_name.node_id and nd_suburb_name.k = 'name'
) suburb
join comuni_border_geom on ST_Covers(comuni_border_geom.geom, suburb.geom)
;

drop table if exists suburbs_border_geom ;

create table suburbs_border_geom as
select suburb.id, suburb.geom from 
(
-- suburb ways
select ways.id, ST_GeogFromText(ST_AsText(ST_Polygonize(ST_GeomFromWKB(ST_AsBinary(ways.linestring))))) geom from ways 
join way_tags boundary on ways.id = boundary.way_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join way_tags admin_level on ways.id = admin_level.way_id and admin_level.k = 'admin_level' and cast(admin_level.v as int) > 8 
group by ways.id
union
-- suburb relations
select relation_id id, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom from ( select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
join relation_tags tag_type on relation_members.relation_id = tag_type.relation_id and tag_type.k = 'type' and tag_type.v = 'boundary'
join relation_tags boundary on relation_members.relation_id = boundary.relation_id and boundary.k = 'boundary' and boundary.v = 'administrative'
join relation_tags admin_level on relation_members.relation_id = admin_level.relation_id and admin_level.k = 'admin_level' and cast(admin_level.v as int) > 8 
order by relation_members.relation_id, relation_members.sequence_id
 ) sub group by relation_id
) suburb
join suburbs_centroid_geom on suburb.id = suburbs_centroid_geom.id
;

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
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.start_node)))) start_pt,
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.end_node)))) end_pt
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
-- ways that are roads
select extra_ways.global_id, extra_ways.local_id, 
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.start_node)))) start_pt,
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.end_node)))) end_pt
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
join comuni_border_geom comuni on ST_Covers(comuni.geom, highways.start_pt) or ST_Covers(comuni.geom, highways.end_pt)
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
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.start_node)))) start_pt,
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.end_node)))) end_pt
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
-- ways that are roads
select extra_ways.global_id global_way_id, extra_ways.local_id local_way_id, 
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.start_node)))) start_pt,
ST_GeogFromText(ST_AsText(ST_GeomFromWKB(ST_AsBinary(extra_ways.end_node)))) end_pt
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
join suburbs_border_geom st_end_suburb on ST_Covers(st_end_suburb.geom, highways.start_pt) and ST_Covers(st_end_suburb.geom, highways.end_pt)
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
    r_name.v road_extend_name,
    r_ways_routes.global_way_id a_global_way_id,
    r_ways_routes.local_way_id a_local_way_id,
    r_ways_routes.linestring a_way_route
    from relations r
    join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'route'
    left join relation_tags r_route on r.id = r_route.relation_id and r_route.k = 'route'
    left join relation_tags r_network on r.id = r_network.relation_id and r_network.k = 'network'
    join relation_members r_ways on r.id = r_ways.relation_id and r_ways.member_type = 'W'
    join ( select global_id global_way_id, local_id local_way_id, ST_MakeLine(start_node,end_node) linestring from extra_ways ) r_ways_routes on r_ways.member_id = r_ways_routes.global_way_id
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
    and rwt.v <> 'proposed';

drop table if exists extra_tmp_2 ;

create table extra_tmp_2 as 
    select distinct 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' road_id,  
    'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id,
    way_name.v road_extend_name,
    extra_ways.global_way_id a_global_way_id,
    extra_ways.local_way_id a_local_way_id,
    extra_ways.linestring a_way_route
    from ways 
    join way_tags wt on ways.id = wt.way_id
    join extra_toponym_city e on wt.way_id = e.global_way_id 
    join ( select global_id global_way_id, local_id local_way_id, ST_MakeLine(start_node,end_node) linestring from extra_ways ) extra_ways on e.global_way_id = extra_ways.global_way_id and e.local_way_id = extra_ways.local_way_id
    join way_tags way_name on wt.way_id = way_name.way_id and way_name.k='name'
    join relation_tags m_name on m_name.k = 'name' and m_name.v = e.city
    join relations m on m_name.relation_id = m.id
    join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
    join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
    join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
    where wt.k = 'highway' 
    and wt.v <> 'proposed';

drop table if exists extra_streetnumbers_on_nodes ;

create table extra_streetnumbers_on_nodes as
select * from (
select distinct 'OS' || lpad(nodes.id::text,11,'0') || 'NN' cn_id, 
       housenumber.v extend_number,
       substring(housenumber.v FROM '[0-9]+') number,
       substring(housenumber.v FROM '[a-zA-Z]+') exponent,
	COALESCE(long_roads.road_id,short_roads.road_id) road_id,
CASE 
WHEN city.v = any ('{Firenze,Genova,Savona}') and housenumber.v ilike '%r%' THEN 'Rosso'
WHEN city.v = any ('{Firenze,Genova,Savona}') and not housenumber.v ilike '%r%' THEN 'Nero'
ELSE 'Privo colore'
END as class_code,
'OS' || lpad(nodes.id::text,11,'0') || 'NE' en_id,  
'Accesso esterno diretto' entry_type,
ST_X(nodes.geom) long,
ST_Y(nodes.geom) lat,
CASE WHEN motorcycle.node_id is not null or motorcar.node_id is not null THEN 'Accesso carrabile' ELSE 'Accesso non carrabile' END as porte_cochere, 
CASE WHEN long_roads.road_id is null THEN 'OS' || lpad(short_roads.a_global_way_id::text,11,'0') || 'RE/' || short_roads.a_local_way_id ELSE 'OS' || lpad(long_roads.a_global_way_id::text,11,'0') || 'RE/' || long_roads.a_local_way_id END as re_id,
dense_rank() over (partition by nodes.id order by ST_Distance(nodes.geom, COALESCE(long_roads.a_way_route,nodes.geom))) as long_roads_way_rank,
dense_rank() over (partition by nodes.id order by ST_Distance(nodes.geom, COALESCE(short_roads.a_way_route,nodes.geom))) as short_roads_way_rank
from nodes
join node_tags housenumber on nodes.id = housenumber.node_id and housenumber.k = 'addr:housenumber'
join node_tags street on nodes.id = street.node_id and street.k = 'addr:street'
join node_tags city on nodes.id = city.node_id and city.k = 'addr:city'
left join node_tags motorcycle on nodes.id = motorcycle.node_id and motorcycle.k = 'motorcycle' and motorcycle.v = 'yes'
left join node_tags motorcar on nodes.id = motorcar.node_id and motorcar.k = 'motorcar' and motorcar.v = 'yes'
join 
(
select 'OS' || lpad(comuni_border_geom.relation_id::text,11,'0') || 'CO' id, relation_tags.v m_name, comuni_border_geom.geom
from comuni_border_geom
join relation_tags on comuni_border_geom.relation_id = relation_tags.relation_id and relation_tags.k = 'name' 
) municipalities on ST_Covers(municipalities.geom, nodes.geom)
left join extra_tmp_1 long_roads on municipalities.id = long_roads.municipality_id and street.v = long_roads.road_extend_name
left join extra_tmp_2 short_roads on municipalities.id = short_roads.municipality_id and street.v = short_roads.road_extend_name
where COALESCE(long_roads.road_id,short_roads.road_id,'--') <> '--'
) q where long_roads_way_rank = 1 and short_roads_way_rank = 1;
drop table if exists extra_streetnumbers_on_relations ;

create table extra_streetnumbers_on_relations as 
select * from (
select distinct 'OS' || lpad(streetNumbers.member_id::text,11,'0') || 'NN' cn_id,
       housenumber.v extend_number,
       substring(housenumber.v FROM '[0-9]+') number,
       substring(housenumber.v FROM '[a-zA-Z]+') exponent,
COALESCE(super_road.road_id, 'OS' || lpad(road.member_id::text,11,'0') || 'SR') road_id,
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
) q where road_element_rank = 1;

drop table if exists extra_streetnumbers_on_junctions ;

create table extra_streetnumbers_on_junctions as
select distinct 'OS' || lpad(nodes.id::text,11,'0') || 'NN' cn_id,
       housenumber.v extend_number,
       substring(housenumber.v FROM '[0-9]+') number,
       substring(housenumber.v FROM '[a-zA-Z]+') exponent,
       COALESCE(super_road.road_id, simple_road.road_id) road_id,
CASE 
WHEN e.city = any ('{Firenze,Genova,Savona}') and housenumber.v ilike '%r%' THEN 'Rosso'
WHEN e.city = any ('{Firenze,Genova,Savona}') and not housenumber.v ilike '%r%' THEN 'Nero'
ELSE 'Privo colore'
END as class_code,
'OS' || lpad(nodes.id::text,11,'0') || 'NE' en_id,  
'Accesso esterno diretto' entry_type,
ST_X(nodes.geom) long,
ST_Y(nodes.geom) lat,
CASE WHEN motorcycle.node_id is not null or motorcar.node_id is not null THEN 'Accesso carrabile' ELSE 'Accesso non carrabile' END as porte_cochere,
'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id re_id
from nodes 
join node_tags housenumber on nodes.id = housenumber.node_id and housenumber.k = 'addr:housenumber'
left join node_tags motorcycle on nodes.id = motorcycle.node_id and motorcycle.k = 'motorcycle' and motorcycle.v = 'yes'
left join node_tags motorcar on nodes.id = motorcar.node_id and motorcar.k = 'motorcar' and motorcar.v = 'yes'
join way_nodes junctions on nodes.id = junctions.node_id
join extra_ways on junctions.way_id = extra_ways.global_id and extra_ways.start_node = nodes.geom
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
where COALESCE(super_road.road_id, simple_road.road_id, '--') <> '--';

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
  join province_centroid_geom prov_of_interest on r.id = prov_of_interest.relation_id 
  join extra_config_graph cfg on 1=1;

/********** Province.Identifier **********/

drop table if exists ProvinceIdentifier ;

Create table ProvinceIdentifier As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'PR' id
  from relations r
  join relation_tags r_type on r.id = r_type.relation_id and r_type.k = 'type' and r_type.v = 'boundary'
  join relation_tags r_boundary on r.id = r_boundary.relation_id and r_boundary.k = 'boundary' and r_boundary.v = 'administrative'
  join relation_tags r_admin_level on r.id = r_admin_level.relation_id and r_admin_level.k = 'admin_level' and r_admin_level.v = '6'
  join province_centroid_geom prov_of_interest on r.id = prov_of_interest.relation_id 
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
  join province_centroid_geom prov_of_interest on r.id = prov_of_interest.relation_id 
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
  join province_centroid_geom prov_of_interest on r.id = prov_of_interest.relation_id 
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
  join province_centroid_geom prov_of_interest on r.id = prov_of_interest.relation_id 
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
  join comuni_centroid_geom com_of_interest on r.id = com_of_interest.relation_id 
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
  join comuni_centroid_geom com_of_interest on r.id = com_of_interest.relation_id 
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
  join comuni_centroid_geom com_of_interest on r.id = com_of_interest.relation_id 
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
  join comuni_centroid_geom com_of_interest on r.id = com_of_interest.relation_id 
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
  join comuni_centroid_geom com_of_interest on r.id = com_of_interest.relation_id 
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
select distinct graph_uri, 'OS' || lpad(m.id::text,11,'0') || 'CO' || '/' || regexp_replace(t.suburb,'[^a-zA-Z]', '', 'g') hamlet_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id,
       t.suburb hamlet_name,
	ST_X(suburbs_centroid_geom.geom::geometry) long, --
	ST_Y(suburbs_centroid_geom.geom::geometry) lat --
  from extra_toponym_city t 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
  join suburbs_centroid_geom on suburbs_centroid_geom.municipality_id = m.id and suburbs_centroid_geom.suburb_name = t.suburb --
  join extra_config_graph cfg on 1=1
  where not ((t.suburb = '') IS NOT FALSE)
;

insert into Hamlet(graph_uri, hamlet_id, municipality_id, hamlet_name, long, lat) 
select distinct graph_uri, 
'OS' || lpad(m.relation_id::text,11,'0') || 'CO' || '/' || regexp_replace(place_name.v,'[^a-zA-Z]', '', 'g') hamlet_id,
'OS' || lpad(m.relation_id::text,11,'0') || 'CO' municipality_id,
place_name.v hamlet_name,
ST_X(nodes.geom) long, 
ST_Y(nodes.geom) lat
from nodes
join node_tags place_suburb on nodes.id = place_suburb.node_id and place_suburb.k = 'place' and place_suburb.v = 'suburb'
join node_tags place_name on nodes.id = place_name.node_id and place_name.k = 'name'
join comuni_border_geom m on ST_Covers(m.geom, nodes.geom)
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
 group by graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR', r_name.v;  

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
;

/*************************************************
*********** Generazione dei RoadElement **********
*********** a partire dalle Relation    **********
*********** che rappresentano toponimi  **********
*********** e legatura alla Road        **********
*************************************************/

drop table if exists RoadRelationElementType ;

Create Table RoadRelationElementType As
select distinct graph_uri, 'OS' || lpad(extra_ways.global_id::text,11,'0') || 'RE/' || extra_ways.local_id road_element_id,
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
   and rwt.v <> 'proposed';

/********** Road(RELATION).inHamletOf  ***************/

drop table if exists RoadRelationInHamletOf ;

Create Table RoadRelationInHamletOf As
select distinct graph_uri, 'OS' || lpad(r.id::text,11,'0') || 'LR' road_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' || '/' || regexp_replace(t.suburb,'[^a-zA-Z]', '', 'g') hamlet_id
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
   AND not ((t.suburb = '') IS NOT FALSE);

/********** Road(WAY) URI **********************/
/********** Road(WAY).ContainsElement **********/

drop table if exists RoadWayURI ;

Create Table RoadWayURI As
select distinct graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id,
       'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id eid  
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

Create Table RoadWayType As
select graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id,  
       way_name.v extend_name,
       max(g.naming) road_type
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
  join extra_generic_namings g on way_name.v ILIKE g.naming || '%'
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
 group by graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR', way_name.v
;

/********** Road(WAY).RoadName **********/

drop table if exists RoadWayName ;

Create Table RoadWayName As
select graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' id,  
       way_name.v extend_name,
       trim(substring(way_name.v, 1+char_length(max(coalesce(g.naming,''))))) road_name
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
  left join extra_generic_namings g on way_name.v ILIKE g.naming || '%'
 where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and rm.member_id is null
 group by graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR', way_name.v
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
select distinct graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' road_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id
  from way_tags wt
  join extra_toponym_city t on wt.way_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
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
   and rm.member_id is null;

/********** Road(WAY).InHamletOf ****************/

drop table if exists RoadWayInHamletOf ;

Create Table RoadWayInHamletOf As
select distinct graph_uri, 'OS' || lpad(wt.way_id::text,11,'0') || 'SR' road_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' || '/' || regexp_replace(t.suburb,'[^a-zA-Z]', '', 'g') hamlet_id
  from way_tags wt
  join extra_toponym_city t on wt.way_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
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
       when way_tags.k = 'highway' and way_tags.v = any ('{motorway_link,trunk_link,primary_link,secondary_link,tertiary_link,escape,motorway_junction}')  then 100
       when ( way_tags.k = 'bridge' and way_tags.v = 'yes' ) or t.relation_id is not null then 1000
       end) as rate
from way_tags highway

join extra_toponym_city e on highway.way_id = e.global_way_id 
left join way_tags on highway.way_id = way_tags.way_id and way_tags.k <> 'highway'
left join relation_members m on highway.way_id = m.member_id and m.member_type = 'W'
left join relation_tags t on m.relation_id = t.relation_id and t.k = 'type' and t.v = 'bridge'
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
       case when l.way_id is not null then round(trim(replace(l.v, 'm',''))::float)::text else round(ST_Length(ways.linestring::geography))::text end as length
from way_tags highway
  join extra_config_graph cfg on 1=1
join extra_toponym_city e on highway.way_id = e.global_way_id 
left join way_tags l on highway.way_id = l.way_id and l.k = 'length' 
join ways on highway.way_id = ways.id 
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
when highway.v = 'construction' or coalesce(access.v,'--') = 'no' then 'tratto stradale chiuso in entrambe le direzioni'
when coalesce(oneway.v,'--') = any('{1,yes}') then 'tratto stradale aperto nella direzione positiva (da giunzione NOD_INI a giunzione NOD_FIN)'
when coalesce(oneway.v,'--') = '-1' then 'tratto stradale aperto nella direzione negativa (da giunzione NOD_FIN a giunzione NOD_INI)'
else 'tratto stradale aperto in entrambe le direzioni (default)'
end as traffic_dir
from way_tags highway
join extra_toponym_city e on highway.way_id = e.global_way_id 
  join extra_config_graph cfg on 1=1
left join way_tags access on highway.way_id = access.way_id and access.k = 'access'
left join way_tags oneway on highway.way_id = oneway.way_id and oneway.k = 'oneway'
where highway.k = 'highway'
and highway.v <> 'proposed'
;

/********** RoadElement.ManagingAuthority **********/

drop table if exists RoadElementManagingAuthority ;

Create Table RoadElementManagingAuthority As
select distinct graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id way_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' municipality_id
  from way_tags wt
  join extra_config_graph cfg on 1=1
  join extra_toponym_city t on wt.way_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
   where wt.k = 'highway' 
   and wt.v <> 'proposed'
;

/********** RoadElement.InHamletOf *****************/

drop table if exists RoadElementHamlet ;

Create Table RoadElementHamlet As
select distinct graph_uri, 'OS' || lpad(t.global_way_id::text,11,'0') || 'RE/' || t.local_way_id way_id,
       'OS' || lpad(m.id::text,11,'0') || 'CO' || '/' || regexp_replace(t.suburb,'[^a-zA-Z]', '', 'g') hamlet_id
  from way_tags wt
  join extra_config_graph cfg on 1=1
  join extra_toponym_city t on wt.way_id = t.global_way_id 
  join relation_tags m_name on m_name.k = 'name' and m_name.v = t.city
  join relations m on m_name.relation_id = m.id
  join relation_tags m_type on m.id = m_type.relation_id and m_type.k = 'type' and m_type.v = 'boundary'
  join relation_tags m_boundary on m.id = m_boundary.relation_id and m_boundary.k = 'boundary' and m_boundary.v = 'administrative'
  join relation_tags m_admin_level on m.id = m_admin_level.relation_id and m_admin_level.k = 'admin_level' and m_admin_level.v = '8'
   where wt.k = 'highway' 
   and wt.v <> 'proposed'
   and not ((t.suburb = '') IS NOT FALSE);

/********** RoadElement.Route **********/

drop table if exists RoadElementRoute ;

Create Table RoadElementRoute As
select distinct graph_uri, 'OS' || lpad(e.global_way_id::text,11,'0') || 'RE/' || e.local_way_id id, ST_MakeLine(extra_ways.start_node,extra_ways.end_node) route
from ways 
  join extra_config_graph cfg on 1=1
join extra_toponym_city e on ways.id = e.global_way_id 
join way_tags highway on ways.id = highway.way_id and highway.k = 'highway' and highway.v <> 'proposed'
join extra_ways on global_id = e.global_way_id and local_id = e.local_way_id
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
select * from extra_streetnumbers_on_nodes
  join extra_config_graph cfg on 1=1
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
select * from extra_streetnumbers_on_relations
  join extra_config_graph cfg on 1=1
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
select * from extra_streetnumbers_on_junctions
  join extra_config_graph cfg on 1=1
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
