/* OSM Road Splitter.
   Copyright (C) 2024 DISIT Lab http://www.disit.org - University of Florence

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
   
const onewayQuery = `
SELECT *
FROM current_way_tags
WHERE
k = 'oneway' AND v = 'yes'
`;

const onewayYesQuery = `
SELECT *
FROM current_way_tags
WHERE
k = 'oneway' AND v = 'no'
`;

const highwayQuery = `
SELECT *
FROM current_way_tags
WHERE
k = 'highway' AND
(
    v = 'unclassified' OR
    v = 'residential' OR
    v = 'primary' OR
    v = 'tertiary' OR
    v = 'tertiary_link' OR
    v = 'secondary' OR
    v = 'track' OR
    v = 'trunk_link' OR
    v = 'primary_link' OR
    v = 'motorway' 
) 
`;

const highwayQuery_BKC = `
SELECT *
FROM current_way_tags
WHERE
k = 'highway' AND
(
    v = 'unclassified' OR
    v = 'service' OR
    v = 'residential' OR
    v = 'primary' OR
    v = 'tertiary' OR
    v = 'tertiary_link' OR
    v = 'secondary' OR
    v = 'track' OR
    v = 'trunk_link' OR
    v = 'primary_link' OR
    v = 'motorway' 
) 
`;

const roundAboutQuery = `
select * from current_way_tags
where k = 'junction' and (v = 'roundabout' or v = 'circular') 
and way_id not in (
    select way_id 
    from current_way_tags
    where k = 'oneway' AND v = 'yes');
`;

const roundaboutVersionQuery = `
SELECT w.* FROM ways w, current_way_tags wt
where wt.k = 'junction' and (wt.v = 'roundabout' or wt.v = 'circular')
and w.way_id = wt.way_id
`;

const relationsQuery = `
SELECT *
FROM
current_relation_members m,
current_relation_tags t,
current_relations r
where r.id = m.relation_id
and r.id = t.relation_id;
`;

const relationMembersQuery = `
select * from current_relation_members;
`

const relationTagsQuery = `
select * from current_relation_tags;
`

const waynodesQuery = `
SELECT *
FROM
current_nodes n,
current_way_nodes wn
WHERE
wn.node_id = n.id
`

const countWaynodesQuery = `
SELECT count(*)
FROM
current_nodes n,
current_way_nodes wn
WHERE
wn.node_id = n.id
`

const getWaysTagsQuery = `
SELECT * 
FROM public.current_way_tags
`

module.exports = {
    onewayQuery,
    roundAboutQuery,
    highwayQuery,
    waynodesQuery,
    countWaynodesQuery,
    getWaysTagsQuery,
    roundaboutVersionQuery,
    relationsQuery,
    onewayYesQuery,
    relationMembersQuery,
    relationTagsQuery
}