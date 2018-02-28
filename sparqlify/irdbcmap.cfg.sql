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
select relation_id, ST_GeogFromText(ST_AsText(ST_Polygonize(linestring))) geom from ( 
	select relation_members.relation_id, ST_GeomFromWKB(ST_AsBinary(ways.linestring)) linestring 
	from relation_members join ways on ways.id = relation_members.member_id and relation_members.member_type='W' 
	where relation_members.relation_id in (276369) --> CA, TAGLIO SU ENTE TERRITORIALE DI INTERESSE, POSSO INSERIRE ANCHE UNA LISTA SEPARATA DA VIRGOLE
--         where relation_members.relation_id in (41976) --> GROSSETO
	order by relation_members.relation_id, relation_members.sequence_id
) boundaries 
group by relation_id;

-- Grafo

drop table if exists extra_config_graph ;

create table extra_config_graph (
id serial primary key,
graph_uri varchar(255)
);

insert into extra_config_graph(graph_uri) values ('http://www.disit.org/km4city/graph/OSM/CA'); 

-- Denominazioni urbanistiche generiche

drop table if exists extra_generic_namings ;

create table extra_generic_namings (
	id serial primary key,		
	naming varchar(255)		
);

INSERT INTO extra_generic_namings(naming) values ('accesso'); 
INSERT INTO extra_generic_namings(naming) values ('allea'); 
INSERT INTO extra_generic_namings(naming) values ('alinea'); 
INSERT INTO extra_generic_namings(naming) values ('alzaia'); 
INSERT INTO extra_generic_namings(naming) values ('androna'); 
INSERT INTO extra_generic_namings(naming) values ('angiporto'); 
INSERT INTO extra_generic_namings(naming) values ('arco'); 
INSERT INTO extra_generic_namings(naming) values ('archivolto'); 
INSERT INTO extra_generic_namings(naming) values ('arena'); 
INSERT INTO extra_generic_namings(naming) values ('bacino'); 
INSERT INTO extra_generic_namings(naming) values ('baluardo'); 
INSERT INTO extra_generic_namings(naming) values ('banchi'); 
INSERT INTO extra_generic_namings(naming) values ('banchina'); 
INSERT INTO extra_generic_namings(naming) values ('barbarìa'); 
INSERT INTO extra_generic_namings(naming) values ('bastione'); 
INSERT INTO extra_generic_namings(naming) values ('bastioni'); 
INSERT INTO extra_generic_namings(naming) values ('belvedere'); 
INSERT INTO extra_generic_namings(naming) values ('borgata'); 
INSERT INTO extra_generic_namings(naming) values ('borgo'); 
INSERT INTO extra_generic_namings(naming) values ('borgoloco'); 
INSERT INTO extra_generic_namings(naming) values ('cal'); 
INSERT INTO extra_generic_namings(naming) values ('calata'); 
INSERT INTO extra_generic_namings(naming) values ('calle'); 
INSERT INTO extra_generic_namings(naming) values ('calle larga'); 
INSERT INTO extra_generic_namings(naming) values ('calle lunga'); 
INSERT INTO extra_generic_namings(naming) values ('calle stretta'); 
INSERT INTO extra_generic_namings(naming) values ('callesèlla'); 
INSERT INTO extra_generic_namings(naming) values ('callesèllo'); 
INSERT INTO extra_generic_namings(naming) values ('callétta'); 
INSERT INTO extra_generic_namings(naming) values ('campiello'); 
INSERT INTO extra_generic_namings(naming) values ('campo'); 
INSERT INTO extra_generic_namings(naming) values ('canale'); 
INSERT INTO extra_generic_namings(naming) values ('cantone'); 
INSERT INTO extra_generic_namings(naming) values ('capo di piazza'); 
INSERT INTO extra_generic_namings(naming) values ('carraia'); 
INSERT INTO extra_generic_namings(naming) values ('carrara'); 
INSERT INTO extra_generic_namings(naming) values ('carrarone'); 
INSERT INTO extra_generic_namings(naming) values ('carro'); 
INSERT INTO extra_generic_namings(naming) values ('cascina'); 
INSERT INTO extra_generic_namings(naming) values ('case sparse'); 
INSERT INTO extra_generic_namings(naming) values ('cavalcavia'); 
INSERT INTO extra_generic_namings(naming) values ('cavone'); 
INSERT INTO extra_generic_namings(naming) values ('chiasso'); 
INSERT INTO extra_generic_namings(naming) values ('chiassetto'); 
INSERT INTO extra_generic_namings(naming) values ('chiassuola'); 
INSERT INTO extra_generic_namings(naming) values ('circonvallazione'); 
INSERT INTO extra_generic_namings(naming) values ('circumvallazione'); 
INSERT INTO extra_generic_namings(naming) values ('claustro'); 
INSERT INTO extra_generic_namings(naming) values ('clivio'); 
INSERT INTO extra_generic_namings(naming) values ('clivo'); 
INSERT INTO extra_generic_namings(naming) values ('complanare'); 
INSERT INTO extra_generic_namings(naming) values ('contrà'); 
INSERT INTO extra_generic_namings(naming) values ('contrada'); 
INSERT INTO extra_generic_namings(naming) values ('corsetto'); 
INSERT INTO extra_generic_namings(naming) values ('corsia'); 
INSERT INTO extra_generic_namings(naming) values ('corso'); 
INSERT INTO extra_generic_namings(naming) values ('corte'); 
INSERT INTO extra_generic_namings(naming) values ('cortesela'); 
INSERT INTO extra_generic_namings(naming) values ('corticella'); 
INSERT INTO extra_generic_namings(naming) values ('cortile'); 
INSERT INTO extra_generic_namings(naming) values ('cortile privato'); 
INSERT INTO extra_generic_namings(naming) values ('costa'); 
INSERT INTO extra_generic_namings(naming) values ('crocicchio'); 
INSERT INTO extra_generic_namings(naming) values ('crosa'); 
INSERT INTO extra_generic_namings(naming) values ('cupa'); 
INSERT INTO extra_generic_namings(naming) values ('cupa vicinale'); 
INSERT INTO extra_generic_namings(naming) values ('diramazione'); 
INSERT INTO extra_generic_namings(naming) values ('discesa'); 
INSERT INTO extra_generic_namings(naming) values ('distacco'); 
INSERT INTO extra_generic_namings(naming) values ('emiciclo'); 
INSERT INTO extra_generic_namings(naming) values ('erta'); 
INSERT INTO extra_generic_namings(naming) values ('estramurale'); 
INSERT INTO extra_generic_namings(naming) values ('fondaco'); 
INSERT INTO extra_generic_namings(naming) values ('fondamenta'); 
INSERT INTO extra_generic_namings(naming) values ('fondo'); 
INSERT INTO extra_generic_namings(naming) values ('fossa'); 
INSERT INTO extra_generic_namings(naming) values ('fossato'); 
INSERT INTO extra_generic_namings(naming) values ('frazione'); 
INSERT INTO extra_generic_namings(naming) values ('galleria'); 
INSERT INTO extra_generic_namings(naming) values ('gradinata'); 
INSERT INTO extra_generic_namings(naming) values ('gradini'); 
INSERT INTO extra_generic_namings(naming) values ('gradoni'); 
INSERT INTO extra_generic_namings(naming) values ('granviale'); 
INSERT INTO extra_generic_namings(naming) values ('isola'); 
INSERT INTO extra_generic_namings(naming) values ('larghetto'); 
INSERT INTO extra_generic_namings(naming) values ('largo'); 
INSERT INTO extra_generic_namings(naming) values ('laterale'); 
INSERT INTO extra_generic_namings(naming) values ('lido'); 
INSERT INTO extra_generic_namings(naming) values ('lista'); 
INSERT INTO extra_generic_namings(naming) values ('litoranea'); 
INSERT INTO extra_generic_namings(naming) values ('località'); 
INSERT INTO extra_generic_namings(naming) values ('lungadige'); 
INSERT INTO extra_generic_namings(naming) values ('lungarno'); 
INSERT INTO extra_generic_namings(naming) values ('lungo'); 
INSERT INTO extra_generic_namings(naming) values ('lungoadda'); 
INSERT INTO extra_generic_namings(naming) values ('lungoargine'); 
INSERT INTO extra_generic_namings(naming) values ('lungobisagno'); 
INSERT INTO extra_generic_namings(naming) values ('lungo Brenta'); 
INSERT INTO extra_generic_namings(naming) values ('lungobusento'); 
INSERT INTO extra_generic_namings(naming) values ('lungocalore'); 
INSERT INTO extra_generic_namings(naming) values ('lungo Castellano'); 
INSERT INTO extra_generic_namings(naming) values ('lungocrati'); 
INSERT INTO extra_generic_namings(naming) values ('lungocanale'); 
INSERT INTO extra_generic_namings(naming) values ('lungocurone'); 
INSERT INTO extra_generic_namings(naming) values ('lungodora'); 
INSERT INTO extra_generic_namings(naming) values ('lungofiume'); 
INSERT INTO extra_generic_namings(naming) values ('lungofoglia'); 
INSERT INTO extra_generic_namings(naming) values ('lungofrigido'); 
INSERT INTO extra_generic_namings(naming) values ('lungogesso'); 
INSERT INTO extra_generic_namings(naming) values ('lungoisarco'); 
INSERT INTO extra_generic_namings(naming) values ('lungoisonzo'); 
INSERT INTO extra_generic_namings(naming) values ('lungolago'); 
INSERT INTO extra_generic_namings(naming) values ('lungolario');  
INSERT INTO extra_generic_namings(naming) values ('lungolinea'); 
INSERT INTO extra_generic_namings(naming) values ('lungoliri'); 
INSERT INTO extra_generic_namings(naming) values ('lungomare');  
INSERT INTO extra_generic_namings(naming) values ('lungomazaro'); 
INSERT INTO extra_generic_namings(naming) values ('lungomolo'); 
INSERT INTO extra_generic_namings(naming) values ('lungonera'); 
INSERT INTO extra_generic_namings(naming) values ('lungoparco'); 
INSERT INTO extra_generic_namings(naming) values ('lungo Po'); 
INSERT INTO extra_generic_namings(naming) values ('lungoporto'); 
INSERT INTO extra_generic_namings(naming) values ('lungosabato'); 
INSERT INTO extra_generic_namings(naming) values ('lungosile'); 
INSERT INTO extra_generic_namings(naming) values ('lungostura'); 
INSERT INTO extra_generic_namings(naming) values ('lungotalvera'); 
INSERT INTO extra_generic_namings(naming) values ('lungotanaro'); 
INSERT INTO extra_generic_namings(naming) values ('lungotevere'); 
INSERT INTO extra_generic_namings(naming) values ('lungoticino'); 
INSERT INTO extra_generic_namings(naming) values ('lungotorrente'); 
INSERT INTO extra_generic_namings(naming) values ('lungotronto'); 
INSERT INTO extra_generic_namings(naming) values ('lungovelino'); 
INSERT INTO extra_generic_namings(naming) values ('masseria'); 
INSERT INTO extra_generic_namings(naming) values ('merceria'); 
INSERT INTO extra_generic_namings(naming) values ('molo'); 
INSERT INTO extra_generic_namings(naming) values ('mura'); 
INSERT INTO extra_generic_namings(naming) values ('murazzi del Po'); 
INSERT INTO extra_generic_namings(naming) values ('parallela'); 
INSERT INTO extra_generic_namings(naming) values ('passaggio'); 
INSERT INTO extra_generic_namings(naming) values ('passaggio privato'); 
INSERT INTO extra_generic_namings(naming) values ('passeggiata'); 
INSERT INTO extra_generic_namings(naming) values ('passeggio'); 
INSERT INTO extra_generic_namings(naming) values ('passo'); 
INSERT INTO extra_generic_namings(naming) values ('passo di piazza'); 
INSERT INTO extra_generic_namings(naming) values ('pendice'); 
INSERT INTO extra_generic_namings(naming) values ('pendino'); 
INSERT INTO extra_generic_namings(naming) values ('pendio'); 
INSERT INTO extra_generic_namings(naming) values ('penninata'); 
INSERT INTO extra_generic_namings(naming) values ('piaggia'); 
INSERT INTO extra_generic_namings(naming) values ('piazza'); 
INSERT INTO extra_generic_namings(naming) values ('piazza inferiore'); 
INSERT INTO extra_generic_namings(naming) values ('piazza privata'); 
INSERT INTO extra_generic_namings(naming) values ('piazzale'); 
INSERT INTO extra_generic_namings(naming) values ('piazzetta'); 
INSERT INTO extra_generic_namings(naming) values ('piazzetta privata'); 
INSERT INTO extra_generic_namings(naming) values ('piscina'); 
INSERT INTO extra_generic_namings(naming) values ('ponte'); 
INSERT INTO extra_generic_namings(naming) values ('portico'); 
INSERT INTO extra_generic_namings(naming) values ('porto'); 
INSERT INTO extra_generic_namings(naming) values ('prato'); 
INSERT INTO extra_generic_namings(naming) values ('prolungamento'); 
INSERT INTO extra_generic_namings(naming) values ('quadrato'); 
INSERT INTO extra_generic_namings(naming) values ('raggio'); 
INSERT INTO extra_generic_namings(naming) values ('ramo'); 
INSERT INTO extra_generic_namings(naming) values ('rampa'); 
INSERT INTO extra_generic_namings(naming) values ('rampa privata'); 
INSERT INTO extra_generic_namings(naming) values ('rampari'); 
INSERT INTO extra_generic_namings(naming) values ('rampe'); 
INSERT INTO extra_generic_namings(naming) values ('ratto'); 
INSERT INTO extra_generic_namings(naming) values ('regione'); 
INSERT INTO extra_generic_namings(naming) values ('rettifilo'); 
INSERT INTO extra_generic_namings(naming) values ('regaste'); 
INSERT INTO extra_generic_namings(naming) values ('riello'); 
INSERT INTO extra_generic_namings(naming) values ('rione'); 
INSERT INTO extra_generic_namings(naming) values ('rio'); 
INSERT INTO extra_generic_namings(naming) values ('rio terà'); 
INSERT INTO extra_generic_namings(naming) values ('ripa'); 
INSERT INTO extra_generic_namings(naming) values ('riva'); 
INSERT INTO extra_generic_namings(naming) values ('riviera'); 
INSERT INTO extra_generic_namings(naming) values ('rondò'); 
INSERT INTO extra_generic_namings(naming) values ('rotonda'); 
INSERT INTO extra_generic_namings(naming) values ('rua'); 
INSERT INTO extra_generic_namings(naming) values ('ruga'); 
INSERT INTO extra_generic_namings(naming) values ('rugheta'); 
INSERT INTO extra_generic_namings(naming) values ('sacca'); 
INSERT INTO extra_generic_namings(naming) values ('sagrato'); 
INSERT INTO extra_generic_namings(naming) values ('saia'); 
INSERT INTO extra_generic_namings(naming) values ('salita'); 
INSERT INTO extra_generic_namings(naming) values ('salita inferiore'); 
INSERT INTO extra_generic_namings(naming) values ('salita superiore'); 
INSERT INTO extra_generic_namings(naming) values ('salizada'); 
INSERT INTO extra_generic_namings(naming) values ('scalea'); 
INSERT INTO extra_generic_namings(naming) values ('scalette'); 
INSERT INTO extra_generic_namings(naming) values ('scalinata'); 
INSERT INTO extra_generic_namings(naming) values ('scalone'); 
INSERT INTO extra_generic_namings(naming) values ('scesa'); 
INSERT INTO extra_generic_namings(naming) values ('sdrucciolo'); 
INSERT INTO extra_generic_namings(naming) values ('selciato'); 
INSERT INTO extra_generic_namings(naming) values ('sentiero'); 
INSERT INTO extra_generic_namings(naming) values ('slargo'); 
INSERT INTO extra_generic_namings(naming) values ('sopportico'); 
INSERT INTO extra_generic_namings(naming) values ('sotoportego'); 
INSERT INTO extra_generic_namings(naming) values ('sottoportico'); 
INSERT INTO extra_generic_namings(naming) values ('spalto'); 
INSERT INTO extra_generic_namings(naming) values ('spiaggia'); 
INSERT INTO extra_generic_namings(naming) values ('spianata'); 
INSERT INTO extra_generic_namings(naming) values ('spiazzo'); 
INSERT INTO extra_generic_namings(naming) values ('strada'); 
INSERT INTO extra_generic_namings(naming) values ('strada accorciatoia'); 
INSERT INTO extra_generic_namings(naming) values ('strada alzaia'); 
INSERT INTO extra_generic_namings(naming) values ('strada antica'); 
INSERT INTO extra_generic_namings(naming) values ('strada arginale'); 
INSERT INTO extra_generic_namings(naming) values ('strada bassa'); 
INSERT INTO extra_generic_namings(naming) values ('strada cantoniera'); 
INSERT INTO extra_generic_namings(naming) values ('strada carrareccia'); 
INSERT INTO extra_generic_namings(naming) values ('strada consolare'); 
INSERT INTO extra_generic_namings(naming) values ('strada consortile'); 
INSERT INTO extra_generic_namings(naming) values ('strada consorziale'); 
INSERT INTO extra_generic_namings(naming) values ('strada di bonifica'); 
INSERT INTO extra_generic_namings(naming) values ('strada esterna'); 
INSERT INTO extra_generic_namings(naming) values ('strada inferiore'); 
INSERT INTO extra_generic_namings(naming) values ('strada intercomunale'); 
INSERT INTO extra_generic_namings(naming) values ('strada interna'); 
INSERT INTO extra_generic_namings(naming) values ('strada interpoderale'); 
INSERT INTO extra_generic_namings(naming) values ('strada litoranea'); 
INSERT INTO extra_generic_namings(naming) values ('strada militare'); 
INSERT INTO extra_generic_namings(naming) values ('strada nazionale'); 
INSERT INTO extra_generic_namings(naming) values ('strada panoramica'); 
INSERT INTO extra_generic_namings(naming) values ('strada pedonale'); 
INSERT INTO extra_generic_namings(naming) values ('strada perimetrale'); 
INSERT INTO extra_generic_namings(naming) values ('strada poderale'); 
INSERT INTO extra_generic_namings(naming) values ('strada privata'); 
INSERT INTO extra_generic_namings(naming) values ('strada provinciale'); 
INSERT INTO extra_generic_namings(naming) values ('strada regionale'); 
INSERT INTO extra_generic_namings(naming) values ('strada rotabile'); 
INSERT INTO extra_generic_namings(naming) values ('strada rurale'); 
INSERT INTO extra_generic_namings(naming) values ('strada traversante'); 
INSERT INTO extra_generic_namings(naming) values ('strada vicinale'); 
INSERT INTO extra_generic_namings(naming) values ('stradale'); 
INSERT INTO extra_generic_namings(naming) values ('stradella');  
INSERT INTO extra_generic_namings(naming) values ('stradello'); 
INSERT INTO extra_generic_namings(naming) values ('stradetta'); 
INSERT INTO extra_generic_namings(naming) values ('stradone'); 
INSERT INTO extra_generic_namings(naming) values ('stradoncello'); 
INSERT INTO extra_generic_namings(naming) values ('stretta'); 
INSERT INTO extra_generic_namings(naming) values ('stretto'); 
INSERT INTO extra_generic_namings(naming) values ('strettoia'); 
INSERT INTO extra_generic_namings(naming) values ('strettola'); 
INSERT INTO extra_generic_namings(naming) values ('svoto'); 
INSERT INTO extra_generic_namings(naming) values ('supportico'); 
INSERT INTO extra_generic_namings(naming) values ('terrazza'); 
INSERT INTO extra_generic_namings(naming) values ('tondo'); 
INSERT INTO extra_generic_namings(naming) values ('traversa'); 
INSERT INTO extra_generic_namings(naming) values ('traversa privata'); 
INSERT INTO extra_generic_namings(naming) values ('traversale'); 
INSERT INTO extra_generic_namings(naming) values ('trasversale'); 
INSERT INTO extra_generic_namings(naming) values ('tratturo'); 
INSERT INTO extra_generic_namings(naming) values ('trazzera'); 
INSERT INTO extra_generic_namings(naming) values ('tresanda'); 
INSERT INTO extra_generic_namings(naming) values ('tronco'); 
INSERT INTO extra_generic_namings(naming) values ('vanella');  
INSERT INTO extra_generic_namings(naming) values ('vallone');  
INSERT INTO extra_generic_namings(naming) values ('via');  
INSERT INTO extra_generic_namings(naming) values ('via accorciatoia');  
INSERT INTO extra_generic_namings(naming) values ('via al mare');  
INSERT INTO extra_generic_namings(naming) values ('via alta'); 
INSERT INTO extra_generic_namings(naming) values ('via alzaia');  
INSERT INTO extra_generic_namings(naming) values ('via antica'); 
INSERT INTO extra_generic_namings(naming) values ('via arginale'); 
INSERT INTO extra_generic_namings(naming) values ('via bassa'); 
INSERT INTO extra_generic_namings(naming) values ('via circolare'); 
INSERT INTO extra_generic_namings(naming) values ('via comunale'); 
INSERT INTO extra_generic_namings(naming) values ('via consolare'); 
INSERT INTO extra_generic_namings(naming) values ('via cupa'); 
INSERT INTO extra_generic_namings(naming) values ('via destra'); 
INSERT INTO extra_generic_namings(naming) values ('via erta'); 
INSERT INTO extra_generic_namings(naming) values ('via estramurale'); 
INSERT INTO extra_generic_namings(naming) values ('via inferiore'); 
INSERT INTO extra_generic_namings(naming) values ('via intercomunale'); 
INSERT INTO extra_generic_namings(naming) values ('via interna'); 
INSERT INTO extra_generic_namings(naming) values ('via laterale'); 
INSERT INTO extra_generic_namings(naming) values ('via lungomare'); 
INSERT INTO extra_generic_namings(naming) values ('via militare'); 
INSERT INTO extra_generic_namings(naming) values ('via nazionale'); 
INSERT INTO extra_generic_namings(naming) values ('via nuova'); 
INSERT INTO extra_generic_namings(naming) values ('via pedonale'); 
INSERT INTO extra_generic_namings(naming) values ('via privata'); 
INSERT INTO extra_generic_namings(naming) values ('via provinciale'); 
INSERT INTO extra_generic_namings(naming) values ('via regionale'); 
INSERT INTO extra_generic_namings(naming) values ('via rotabile'); 
INSERT INTO extra_generic_namings(naming) values ('via rurale'); 
INSERT INTO extra_generic_namings(naming) values ('via sinistra'); 
INSERT INTO extra_generic_namings(naming) values ('via stretta'); 
INSERT INTO extra_generic_namings(naming) values ('via superiore'); 
INSERT INTO extra_generic_namings(naming) values ('via trasversale'); 
INSERT INTO extra_generic_namings(naming) values ('via vecchia'); 
INSERT INTO extra_generic_namings(naming) values ('via vicinale'); 
INSERT INTO extra_generic_namings(naming) values ('vial'); 
INSERT INTO extra_generic_namings(naming) values ('viale'); 
INSERT INTO extra_generic_namings(naming) values ('viale lungomare'); 
INSERT INTO extra_generic_namings(naming) values ('viale privato'); 
INSERT INTO extra_generic_namings(naming) values ('vialetto'); 
INSERT INTO extra_generic_namings(naming) values ('vialone'); 
INSERT INTO extra_generic_namings(naming) values ('vicinale'); 
INSERT INTO extra_generic_namings(naming) values ('vicoletto'); 
INSERT INTO extra_generic_namings(naming) values ('vicoletto cieco'); 
INSERT INTO extra_generic_namings(naming) values ('vicolo'); 
INSERT INTO extra_generic_namings(naming) values ('vicolo chiuso'); 
INSERT INTO extra_generic_namings(naming) values ('vicolo cieco'); 
INSERT INTO extra_generic_namings(naming) values ('vico'); 
INSERT INTO extra_generic_namings(naming) values ('vico estramurale'); 
INSERT INTO extra_generic_namings(naming) values ('vico inferiore'); 
INSERT INTO extra_generic_namings(naming) values ('vico lungo'); 
INSERT INTO extra_generic_namings(naming) values ('vico nuovo'); 
INSERT INTO extra_generic_namings(naming) values ('vico privato'); 
INSERT INTO extra_generic_namings(naming) values ('vico rotto'); 
INSERT INTO extra_generic_namings(naming) values ('vico storto'); 
INSERT INTO extra_generic_namings(naming) values ('vico stretto'); 
INSERT INTO extra_generic_namings(naming) values ('vico superiore'); 
INSERT INTO extra_generic_namings(naming) values ('viella'); 
INSERT INTO extra_generic_namings(naming) values ('vietta'); 
INSERT INTO extra_generic_namings(naming) values ('villaggio'); 
INSERT INTO extra_generic_namings(naming) values ('viottolo'); 
INSERT INTO extra_generic_namings(naming) values ('viuzza'); 
INSERT INTO extra_generic_namings(naming) values ('viuzzo'); 
INSERT INTO extra_generic_namings(naming) values ('vocabolo'); 
INSERT INTO extra_generic_namings(naming) values ('volti'); 
INSERT INTO extra_generic_namings(naming) values ('voltone'); 
INSERT INTO extra_generic_namings(naming) values ('SS'); 
INSERT INTO extra_generic_namings(naming) values ('SR'); 
INSERT INTO extra_generic_namings(naming) values ('SP'); 
INSERT INTO extra_generic_namings(naming) values ('SC');
INSERT INTO extra_generic_namings(naming) values ('S.S.'); 
INSERT INTO extra_generic_namings(naming) values ('S.R.'); 
INSERT INTO extra_generic_namings(naming) values ('S.P.'); 
INSERT INTO extra_generic_namings(naming) values ('S.C.');
INSERT INTO extra_generic_namings(naming) values ('SS.'); 
INSERT INTO extra_generic_namings(naming) values ('SR.'); 
INSERT INTO extra_generic_namings(naming) values ('SP.'); 
INSERT INTO extra_generic_namings(naming) values ('SC.');
INSERT INTO extra_generic_namings(naming) values ('S. S.'); 
INSERT INTO extra_generic_namings(naming) values ('S. R.'); 
INSERT INTO extra_generic_namings(naming) values ('S. P.');
INSERT INTO extra_generic_namings(naming) values ('S. C.');
INSERT INTO extra_generic_namings(naming) values ('strada statale');
INSERT INTO extra_generic_namings(naming) values ('strada regionale');
INSERT INTO extra_generic_namings(naming) values ('strada provinciale');
INSERT INTO extra_generic_namings(naming) values ('strada comunale');

-- Esplosione delle way

drop table if exists extra_ways;

create table extra_ways as
select prev_waynode.way_id global_id, prev_waynode.sequence_id local_id, prev_node.geom start_node, next_node.geom end_node
from way_nodes prev_waynode 
join nodes prev_node on prev_waynode.node_id = prev_node.id
join way_nodes next_waynode on prev_waynode.way_id = next_waynode.way_id and prev_waynode.sequence_id = next_waynode.sequence_id-1
join nodes next_node on next_waynode.node_id = next_node.id;

create index on extra_ways (global_id);

