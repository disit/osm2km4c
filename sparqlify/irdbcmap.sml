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

/*******************************
*********** Province ***********
*******************************/

/********** Province URI **********/

Create View ProvinceURI As

Construct {
Graph ?graph_uri {
	?s a km4c:Province
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))

From [[
select * from ProvinceURI
]]

/********** Province.Identifier **********/

Create View ProvinceIdentifier As

Construct { 
Graph ?graph_uri {
?s dct:identifier ?identifier
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?identifier = plainLiteral(?id)

From [[
select * from ProvinceIdentifier
]]

/********** Province.Name **********/

Create View ProvinceName As

Construct {
Graph ?graph_uri {
?s foaf:name ?name .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?name = plainLiteral(?p_name)

From [[
select * from ProvinceName
]]

/********** Province.Alternative **********/

Create View ProvinceAlternative As

Construct {
Graph ?graph_uri {
?s dct:alternative ?alternative .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?alternative = plainLiteral(?alternative)

From [[
select * from ProvinceAlternative
]]

/********** Province.hasMunicipality **********/

Create View ProvinceHasMunicipality As

Construct {
Graph ?graph_uri {
?s km4c:hasMunicipality ?has_municipality
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?has_municipality = uri(concat("http://www.disit.org/km4city/resource/",?has_municipality))

From [[
select * from ProvinceHasMunicipality
]]

/***********************************
*********** Municipality ***********
***********************************/

/********** Municipality URI **********/

Create View MunicipalityURI As

Construct {
Graph ?graph_uri {
?s a km4c:Municipality
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))

From [[
select * from MunicipalityURI
]]

/********** Municipality.Identifier **********/

Create View MunicipalityIdentifier As

Construct {
Graph ?graph_uri {
?s dct:identifier ?identifier
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?identifier = plainLiteral(?id)

From [[
select * from MunicipalityIdentifier
]]

/********** Municipality.Name **********/

Create View MunicipalityName As

Construct {
Graph ?graph_uri {
?s foaf:name ?name .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?name = plainLiteral(?p_name)

From [[
select * from MunicipalityName
]]

/********** Municipality.Alternative **********/

Create View MunicipalityAlternative As

Construct {
Graph ?graph_uri {
?s dct:alternative ?alternative .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?alternative = plainLiteral(?alternative)

From [[
select * from MunicipalityAlternative
]]

/********** Municipality.isPartOfProvince **********/

Create View MunicipalityIsPartOfProvince As

Construct {
Graph ?graph_uri {
?s km4c:isPartOfProvince ?v
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?v = uri(concat("http://www.disit.org/km4city/resource/",?province_id))

From [[
select * from MunicipalityIsPartOfProvince
]]

/***************************
********** Hamlet **********
***************************/

Create view Hamlet As

Construct {
Graph ?graph_uri {
?hamlet a km4c:Hamlet .
?hamlet km4c:inMunicipalityOf ?municipality .
?hamlet foaf:name ?hamletName . 
?hamlet geo:lat ?lat .
?hamlet geo:long ?long 
}}

With 
?graph_uri = uri(?graph_uri)
?hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?hamlet_id ))
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id ))
?hamletName = plainLiteral(?hamlet_name)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")

From [[
select * from Hamlet
]]

/**************************
*********** Road **********
**************************/

/********** Road(RELATION) URI **********/

Create View RoadRelationURI As

Construct {
Graph ?graph_uri {
?s a km4c:Road
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))

From [[
select * from RoadRelationURI
]]

/********** Road(RELATION).Identifier **********/

Create View RoadRelationIdentifier As

Construct {
Graph ?graph_uri {
?s dct:identifier ?identifier
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?identifier = plainLiteral(?id)

From [[
select * from RoadRelationIdentifier
]]

/********** Road(RELATION).RoadType **********/

Create view RoadRelationType As

Construct {
Graph ?graph_uri {
?s km4c:roadType ?roadType
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?roadType = plainLiteral(?road_type)

From [[
select * from RoadRelationType
]]

/********** Road(RELATION).RoadName **********/

Create view RoadRelationName As

Construct {
Graph ?graph_uri {
?s km4c:roadName ?roadName
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?roadName = plainLiteral(?road_name)

From [[
select * from RoadRelationName
]]

/********** Road(RELATION).ExtendName **********/

Create view RoadRelationExtendName As

Construct {
Graph ?graph_uri {
?s km4c:extendName ?extendName
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?extendName = plainLiteral(?extend_name)

From [[
select * from RoadRelationExtendName
]]

/********** Road(RELATION).Alternative **********/

Create view RoadRelationAlternative As

Construct {
Graph ?graph_uri {
?s dct:alternative ?alternative
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?alternative = plainLiteral(?alternative)

From [[
select * from RoadRelationAlternative
]]

/*************************************************
*********** Generazione dei RoadElement **********
*********** a partire dalle Relation    **********
*********** che rappresentano toponimi  **********
*********** e legatura alla Road        **********
*************************************************/

Create view RoadRelationElementType As

Construct {
Graph ?graph_uri {
?element a km4c:RoadElement .
?element dct:identifier ?elementid .
?road km4c:containsElement ?element .
}}

With 
?graph_uri = uri(?graph_uri)
?element = uri(concat("http://www.disit.org/km4city/resource/", ?road_element_id))
?elementid = plainLiteral(?road_element_id)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))

From [[
select * from RoadRelationElementType
]]

/********** Road(RELATION).inMunicipalityOf  *********/

Create view RoadRelationInMunicipalityOf As

Construct {
Graph ?graph_uri {
?road km4c:inMunicipalityOf ?municipality 
}}

With
?graph_uri = uri(?graph_uri)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id))

From [[
select * from RoadRelationInMunicipalityOf
]]

/********** Road(RELATION).inHamletOf  ***************/

Create view RoadRelationInHamletOf As

Construct {
Graph ?graph_uri {
?road km4c:inHamletOf ?hamlet .
}}

With
?graph_uri = uri(?graph_uri)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?hamlet_id))

From [[
select * from RoadRelationInHamletOf
]]

/********** Road(WAY) URI **********************/
/********** Road(WAY).ContainsElement **********/

Create View RoadWayURI As

Construct {
Graph ?graph_uri {
?s a km4c:Road .
?e a km4c:RoadElement .
?e dct:identifier ?ei .
?s km4c:containsElement ?e
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?e = uri(concat("http://www.disit.org/km4city/resource/", ?eid))
?ei = plainLiteral(?eid)

From [[
select * from RoadWayURI
]]

/********** Road(WAY).Identifier **********/

Create View RoadWayIdentifier As

Construct {
Graph ?graph_uri {
?s dct:identifier ?identifier
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?identifier = plainLiteral(?id)

From [[
select * from RoadWayIdentifier
]]

/********** Road(WAY).RoadType **********/

Create view RoadWayType As

Construct {
Graph ?graph_uri {
?s km4c:roadType ?roadType
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?roadType = plainLiteral(?road_type)

From [[
select * from RoadWayType
]]

/********** Road(WAY).RoadName **********/

Create view RoadWayName As

Construct {
Graph ?graph_uri {
?s km4c:roadName ?roadName
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?roadName = plainLiteral(?road_name)

From [[
select * from RoadWayName
]]

/********** Road(WAY).ExtendName **********/

Create view RoadWayExtendName As

Construct {
Graph ?graph_uri {
?s km4c:extendName ?extendName
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?extendName = plainLiteral(?extend_name)

From [[
select * from RoadWayExtendName
]]

/********** Road(WAY).Alternative **********/

Create view RoadWayAlternative As

Construct {
Graph ?graph_uri {
?s dct:alternative ?alternative
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?alternative = plainLiteral(?alternative)

From [[
select * from RoadWayAlternative
]]

/********** Road(WAY).InMunicipalityOf **********/

Create view RoadWayInMunicipalityOf As

Construct {
Graph ?graph_uri {
?road km4c:inMunicipalityOf ?municipality .
}}

With
?graph_uri = uri(?graph_uri)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id))

From [[
select * from RoadWayInMunicipalityOf
]]

/********** Road(WAY).InHamletOf ****************/

Create view RoadWayInHamletOf As

Construct {
Graph ?graph_uri {
?road km4c:inHamletOf ?hamlet .
}}

With
?graph_uri = uri(?graph_uri)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?hamlet_id))

From [[
select * from RoadWayInHamletOf
]]


/**********************************
*********** RoadElement ***********
**********************************/

/********** RoadElement.ElementType **********/

Create view RoadElementType As

Construct {
Graph ?graph_uri {
?s km4c:elementType ?elementType 
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?elementType = plainLiteral(?element_type)

From [[
select * from RoadElementType
]]

/********** RoadElement.ElementClass **********/

Create view RoadElementClass As

Construct {
Graph ?graph_uri {
?s km4c:elementClass ?elementClass
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?elementClass = plainLiteral(?element_class)

From [[
select * from RoadElementClass
]]

/********** RoadElement.Composition **********/

Create view RoadElementComposition As

Construct {
Graph ?graph_uri {
?s km4c:composition ?composition
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?composition = plainLiteral(?composition)

From [[

select * from RoadElementComposition

]]

/********** RoadElement.elemLocation **********/

Create view RoadElementLocation As

Construct {
Graph ?graph_uri {
?s km4c:elemLocation ?elemLocation
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?elemLocation = plainLiteral(?elem_location)

From [[
select * from RoadElementLocation

]]

/********** RoadElement.Length **********/

Create view RoadElementLength As

Construct {
Graph ?graph_uri {
?s km4c:length ?length
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?length = plainLiteral(?length)

From [[
select * from RoadElementLength
]]

/********** RoadElement.Width **********/

Create view RoadElementWidth As

Construct {
Graph ?graph_uri {
?s km4c:width ?width
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?width = plainLiteral(?width)

From [[
select * from RoadElementWidth

]]

/********** RoadElement.OperatingStatus **********/

Create view RoadElementOperatingStatus As

Construct {
Graph ?graph_uri {
?s km4c:operatingStatus ?operatingStatus
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?operatingStatus = plainLiteral(?operating_status)

From [[

select * from RoadElementOperatingStatus

]]

/********** RoadElement.SpeedLimit **********/

Create view RoadElementSpeedLimit As

Construct {
Graph ?graph_uri {
?s km4c:speedLimit ?speedLimit
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?speedLimit = plainLiteral(?speed_limit)

From [[

select * from RoadElementSpeedLimit

]]

/********** RoadElement.TrafficDir **********/

Create view RoadElementTrafficDir As

Construct {
Graph ?graph_uri {
?s km4c:trafficDir ?trafficDir
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?trafficDir = plainLiteral(?traffic_dir)

From [[

select * from RoadElementTrafficDir

]]

/********** RoadElement.ManagingAuthority **********/

Create view RoadElementManagingAuthority As

Construct {
Graph ?graph_uri {
?s km4c:managingAuthority ?municipality . 
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?way_id))
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id))

From [[

select * from RoadElementManagingAuthority

]]

/********** RoadElement.InHamletOf *****************/

Create view RoadElementHamlet As

Construct {
Graph ?graph_uri {
?s km4c:inHamletOf ?hamlet
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?way_id))
?hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?hamlet_id))

From [[

select * from RoadElementHamlet

]]

/********** RoadElement.Route **********/

Create view RoadElementRoute As

Construct {
Graph ?graph_uri {
?s km4c:route ?route
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?route = typedLiteral(?route,"http://www.openlinksw.com/schemas/virtrdf#Geometry")

From [[

select * from RoadElementRoute

]]

/********** RoadElement.StartsAtNode **********/

Create view RoadElementStartsAtNode As

Construct {
Graph ?graph_uri {
?node a km4c:Node .
?node dct:identifier ?nodeid .
?node km4c:nodeType ?nodeType .
?node geo:lat ?lat .
?node geo:long ?long .
?element km4c:startsAtNode ?node .
}}

With 
?graph_uri = uri(?graph_uri)
?node = uri(concat("http://www.disit.org/km4city/resource/", ?start_node_id))
?nodeid = plainLiteral(?start_node_id)
?nodeType = plainLiteral(?node_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?element = uri(concat("http://www.disit.org/km4city/resource/", ?way_id))

From [[
select * from RoadElementStartsAtNode
 ]] 

/********** RoadElement.EndsAtNode **********/

Create view RoadElementEndsAtNode As

Construct {
Graph ?graph_uri {
?node a km4c:Node .
?node dct:identifier ?nodeid .
?node km4c:nodeType ?nodeType .
?node geo:lat ?lat .
?node geo:long ?long .
?element km4c:endsAtNode ?node .
}}

With 
?graph_uri = uri(?graph_uri)
?node = uri(concat("http://www.disit.org/km4city/resource/", ?end_node_id))
?nodeid = plainLiteral(?end_node_id)
?nodeType = plainLiteral(?node_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?element = uri(concat("http://www.disit.org/km4city/resource/", ?way_id))

From [[
select * from RoadElementEndsAtNode 
 ]] 

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso l'indirizzo ******
*********** indicato sul nodo ***********
****************************************/

Create view NodeStreetNumberRoad As

Construct {
Graph ?graph_uri {
?cn a km4c:StreetNumber .
?cn dct:identifier ?identifier .
?cn km4c:extendNumber ?extend_number .
?cn km4c:number ?number .
?cn km4c:exponent ?exponent .
?cn km4c:belongToRoad ?road .
?road km4c:hasStreetNumber ?cn .
?cn km4c:classCode ?classCode .
?cn km4c:hasExternalAccess ?ne .
?ne a km4c:Entry .
?ne dct:identifier ?ne_identifier .
?ne km4c:entryType ?entryType .
?ne geo:long ?long .
?ne geo:lat ?lat .
?ne km4c:porteCochere ?porteCochere .
?ne km4c:placedInElement ?re
}}

With 
?graph_uri = uri(?graph_uri)
?cn = uri(concat("http://www.disit.org/km4city/resource/", ?cn_id))
?identifier = plainLiteral(?cn_id)
?extend_number = plainLiteral(?extend_number)
?number = plainLiteral(?number)
?exponent = plainLiteral(?exponent)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?classCode = plainLiteral(?class_code)
?ne = uri(concat("http://www.disit.org/km4city/resource/", ?en_id))
?ne_identifier = plainLiteral(?en_id)
?entryType = plainLiteral(?entry_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?porteCochere = plainLiteral(?porte_cochere)
?re = uri(concat("http://www.disit.org/km4city/resource/", ?re_id))

From [[
select * from NodeStreetNumberRoad
]]

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso le Relation ******
*********** di tipo associateStreet *****
****************************************/

Create view RelationStreetNumberRoad As

Construct {
Graph ?graph_uri {
?cn a km4c:StreetNumber .
?cn dct:identifier ?identifier .
?cn km4c:extendNumber ?extend_number .
?cn km4c:number ?number .
?cn km4c:exponent ?exponent .
?cn km4c:belongToRoad ?road .
?road km4c:hasStreetNumber ?cn .
?cn km4c:classCode ?class_code .
?cn km4c:hasExternalAccess ?ne .
?ne a km4c:Entry .
?ne dct:identifier ?ne_identifier .
?ne km4c:entryType ?entryType .
?ne geo:long ?long .
?ne geo:lat ?lat .
?ne km4c:porteCochere ?porteCochere .
?ne km4c:placedInElement ?re
}}

With 
?graph_uri = uri(?graph_uri)
?cn = uri(concat("http://www.disit.org/km4city/resource/", ?cn_id))
?identifier = plainLiteral(?cn_id)
?extend_number = plainLiteral(?extend_number)
?number = plainLiteral(?number)
?exponent = plainLiteral(?exponent)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?class_code = plainLiteral(?class_code)
?ne = uri(concat("http://www.disit.org/km4city/resource/", ?en_id))
?ne_identifier = plainLiteral(?en_id)
?entryType = plainLiteral(?entry_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?porteCochere = plainLiteral(?porte_cochere)
?re = uri(concat("http://www.disit.org/km4city/resource/", ?re_id))

From [[
select * from RelationStreetNumberRoad
]]

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso il fatto che il **
*********** nodo è giunzione della Way **
****************************************/

Create view NodeStreetNumberRoad2 As

Construct {
Graph ?graph_uri {
?cn a km4c:StreetNumber .
?cn dct:identifier ?identifier .
?cn km4c:extendNumber ?extend_number .
?cn km4c:number ?number .
?cn km4c:exponent ?exponent .
?cn km4c:belongToRoad ?road .
?road km4c:hasStreetNumber ?cn .
?cn km4c:classCode ?classCode .
?cn km4c:hasExternalAccess ?ne .
?ne a km4c:Entry .
?ne dct:identifier ?ne_identifier .
?ne km4c:entryType ?entryType .
?ne geo:long ?long .
?ne geo:lat ?lat .
?ne km4c:porteCochere ?porteCochere .
?ne km4c:placedInElement ?re
}}

With 
?graph_uri = uri(?graph_uri)
?cn = uri(concat("http://www.disit.org/km4city/resource/", ?cn_id))
?identifier = plainLiteral(?cn_id)
?extend_number = plainLiteral(?extend_number)
?number = plainLiteral(?number)
?exponent = plainLiteral(?exponent)
?road = uri(concat("http://www.disit.org/km4city/resource/", ?road_id))
?classCode = plainLiteral(?class_code)
?ne = uri(concat("http://www.disit.org/km4city/resource/", ?en_id))
?ne_identifier = plainLiteral(?en_id)
?entryType = plainLiteral(?entry_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?porteCochere = plainLiteral(?porte_cochere)
?re = uri(concat("http://www.disit.org/km4city/resource/", ?re_id))

From [[
select * from NodeStreetNumberRoad2
]]

/********************************
*********** Milestone ***********
********************************/

Create view Milestone As

Construct {
Graph ?graph_uri {
?ml a km4c:Milestone .
?ml dct:identifier ?identifier .
?ml km4c:text ?distance.
?ml geo:long ?long .
?ml geo:lat ?lat .
?ml km4c:isInElement ?re
}}

With 
?graph_uri = uri(?graph_uri)
?ml = uri(concat("http://www.disit.org/km4city/resource/", ?ml_id))
?identifier = plainLiteral(?ml_id)
?distance = plainLiteral(?distance)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?re = uri(concat("http://www.disit.org/km4city/resource/", ?re_id))

From [[
select * from Milestone
]]

/********************************
*********** EntryRule ***********
********************************/

Create view EntryRule As

Construct {
Graph ?graph_uri {
?rl a km4c:EntryRule .
?rl dct:identifier ?identifier .
?rl km4c:restrictionType ?restrictionType .
?rl km4c:restrictionValue ?restrictionValue .
?rl km4c:hasRule ?re .
?re km4c:accessToElement ?rl
}}

With 
?graph_uri = uri(?graph_uri)
?rl = uri(concat("http://www.disit.org/km4city/resource/", ?rl_id))
?identifier = plainLiteral(?rl_id)
?re = uri(concat("http://www.disit.org/km4city/resource/", ?re_id))
?restrictionType = plainLiteral(?restriction_type)
?restrictionValue = plainLiteral(?restriction_value)

From [[
select * from EntryRule
]]

