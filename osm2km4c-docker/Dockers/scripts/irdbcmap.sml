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

/*******************************
*********** Province ***********
*******************************/

/********** Province URI **********/

Create View ProvinceURI As

Construct {
Graph ?graph_uri {
	?s a km4c:Province ; a km4c:NamedArea
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

/********** Province.Geometry *****************/

Create View ProvinceGeometry As

Construct {
Graph ?graph_uri {
?s geo:geometry ?geometry .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?geometry = typedLiteral(?geometry, "http://www.openlinksw.com/schemas/virtrdf#Geometry")

From [[
select * from ProvinceGeometry
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
?s a km4c:Municipality; a km4c:NamedArea
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

/********** Municipality.Geometry *****************/

Create View MunicipalityGeometry As

Construct {
Graph ?graph_uri {
?s geo:geometry ?geometry .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?geometry = typedLiteral(?geometry, "http://www.openlinksw.com/schemas/virtrdf#Geometry")

From [[
select * from MunicipalityGeometry
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
?hamlet a km4c:NamedPoint . 
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
?element km4c:highwayType ?highway_type .
?road km4c:containsElement ?element .
}}

With 
?graph_uri = uri(?graph_uri)
?element = uri(concat("http://www.disit.org/km4city/resource/", ?road_element_id))
?elementid = plainLiteral(?road_element_id)
?highway_type = plainLiteral(?road_element_type)
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
?e km4c:highwayType ?ht .
?s km4c:containsElement ?e
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?e = uri(concat("http://www.disit.org/km4city/resource/", ?eid))
?ei = plainLiteral(?eid)
?ht = plainLiteral(?road_element_type)

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

Create view RoadElementRoundabout As

Construct {
Graph ?graph_uri {
?s km4c:elementType ?elementType 
}}

With 
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?elementType = plainLiteral(?element_type)

From [[
select * from RoadElementRoundabout
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

/********** AdministrativeRoad **********/

Create view AdministrativeRoad As

Construct {
Graph ?graph_uri {
?ar_uri a km4c:AdministrativeRoad . 
?ar_uri dct:identifier ?ar_id .
?ar_uri km4c:adRoadName ?ar_name .
?ar_uri dct:alternative ?ar_alternative .
?ar_uri km4c:adminClass ?ar_admin_class .
?ar_uri km4c:ownerAuthority ?municipality_uri
}}

With 
?graph_uri = uri(?graph_uri)
?ar_uri = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?ar_id = plainLiteral(?id)
?ar_name = plainLiteral(?ad_road_name)
?ar_alternative = plainLiteral(?alternative)
?ar_admin_class = plainLiteral(?admin_class)
?municipality_uri = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id)) 

From [[
select distinct graph_uri, id, ad_road_name, alternative, admin_class, municipality_id from AdministrativeRoad
]]

Create View AdministrativeRoadNameGeneric As

Construct {
Graph ?graph_uri {
?ar km4c:adRoadNameGeneric ?arng
}}

With
?graph_uri = uri(?graph_uri)
?ar = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?arng = plainLiteral(?ad_road_name_generic)

From [[
select * from AdministrativeRoadNameGeneric
]]

Create View AdministrativeRoadNameSpecific As

Construct {
Graph ?graph_uri {
?ar km4c:adRoadNameSpecific ?arns
}}

With
?graph_uri = uri(?graph_uri)
?ar = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?arns = plainLiteral(?ad_road_name_specific)

From [[
select * from AdministrativeRoadNameSpecific
]]

Create view AdministrativeRoadElement As

Construct {
Graph ?graph_uri {
?ar_uri km4c:hasRoadElement ?re_uri .
?re_uri km4c:formingAdminRoad ?ar_uri
}}

With 
?graph_uri = uri(?graph_uri)
?ar_uri = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?re_uri = uri(concat("http://www.disit.org/km4city/resource/", ?eid))

From [[
select * from AdministrativeRoad
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

Create View NodeStreetNumberRoadRT As 

Construct {
Graph ?graph_uri {
?ne km4c:nearTo ?ref
}}

With 
?graph_uri = uri(?graph_uri)
?ne = uri(concat("http://www.disit.org/km4city/resource/", ?en_id))
?ref = uri(concat("http://www.disit.org/km4city/resource/", ?native_node_ref))

From [[
select graph_uri, en_id, 'OS' || lpad(native_node_ref::text,11,'0') || 'NO' native_node_ref from NodeStreetNumberRoad
where node_source = 'Regione Toscana'
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

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** legati con la Road **********
*********** attraverso l'indirizzo ******
*********** indicato sulla way **********
*********** (building outline) **********
****************************************/

Create view WayStreetNumberRoad As

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
select * from WayStreetNumberRoad
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

/*****************************
*********** Region ***********
******************************/

/********** Region URI **********/

Create View RegionURI As

Construct {
Graph ?graph_uri {
	?s a km4c:Region; a km4c:NamedArea
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))

From [[
select * from RegionURI
]]

/********** Region.Identifier **********/

Create View RegionIdentifier As

Construct { 
Graph ?graph_uri {
?s dct:identifier ?identifier
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?identifier = plainLiteral(?id)

From [[
select * from RegionIdentifier
]]

/********** Region.Name **********/

Create View RegionName As

Construct {
Graph ?graph_uri {
?s foaf:name ?name .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?name = plainLiteral(?p_name)

From [[
select * from RegionName
]]

/********** Region.Alternative **********/

Create View RegionAlternative As

Construct {
Graph ?graph_uri {
?s dct:alternative ?alternative .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?alternative = plainLiteral(?alternative)

From [[
select * from RegionAlternative
]]

/********** Region.Geometry *****************/

Create View RegionGeometry As

Construct {
Graph ?graph_uri {
?s geo:geometry ?geometry .
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?geometry = typedLiteral(?geometry, "http://www.openlinksw.com/schemas/virtrdf#Geometry")

From [[
select * from RegionGeometry
]]

/********** Region.hasProvince **********/

Create View RegionHasProvince As

Construct {
Graph ?graph_uri {
?s km4c:hasProvince ?has_province
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?id))
?has_province = uri(concat("http://www.disit.org/km4city/resource/",?has_province))

From [[
select * from RegionHasProvince
]]

/********** Province.isInRegion **********/

Create View ProvinceIsInRegion As

Construct {
Graph ?graph_uri {
?s km4c:isInRegion ?region
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?has_province))
?region = uri(concat("http://www.disit.org/km4city/resource/",?id))

From [[
select * from RegionHasProvince
]]

/***************************************
*********** TurnRestrictions ***********
****************************************/




Create View TurnRestrictions As

Construct {
Graph ?graph_uri {
	?s a km4c:TurnRestriction;
           a km4c:Restriction;
	   km4c:where ?from;
	   km4c:toward ?to;
	   km4c:node ?node_uri;
	   km4c:restriction ?restriction .
	km4c:TurnRestriction rdfs:subClassOf km4c:Restriction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri, "/restriction/turn/", ?to_uri))
?from = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri))
?to = uri(concat("http://www.disit.org/km4city/resource/", ?to_uri))
?node_uri = uri(concat("http://www.disit.org/km4city/resource/", ?node_uri))
?restriction = plainLiteral(?restriction)

From [[
select * from turn_restrictions
]]




Create View TurnRestrictionsDayOn As

Construct {
Graph ?graph_uri {
	?s km4c:day_on ?day_on
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri, "/restriction/turn/", ?to_uri))
?day_on = plainLiteral(?day_on)

From [[
select * from turn_restrictions where day_on is not null
]]

Create View TurnRestrictionsDayOff As

Construct {
Graph ?graph_uri {
	?s km4c:day_off ?day_off
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri, "/restriction/turn/", ?to_uri))
?day_off = plainLiteral(?day_off)

From [[
select * from turn_restrictions where day_off is not null
]]

Create View TurnRestrictionsHourOn As

Construct {
Graph ?graph_uri {
	?s km4c:hour_on ?hour_on
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri, "/restriction/turn/", ?to_uri))
?hour_on = plainLiteral(?hour_on)

From [[
select * from turn_restrictions where hour_on is not null
]]

Create View TurnRestrictionsHourOff As

Construct {
Graph ?graph_uri {
	?s km4c:hour_off ?hour_off
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri, "/restriction/turn/", ?to_uri))
?hour_off = plainLiteral(?hour_off)

From [[
select * from turn_restrictions where hour_off is not null
]]

Create View TurnRestrictionsHourOff As

Construct {
Graph ?graph_uri {
	?s km4c:except ?except
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?from_uri, "/restriction/turn/", ?to_uri))
?except = plainLiteral(?exceptions)

From [[
select * from turn_restrictions where exceptions is not null
]]

/*****************************
*** Access Restrictions ******
*****************************/

Create View AccessRestrictions As

Construct {
Graph ?graph_uri {
	?s a km4c:AccessRestriction;
	   a km4c:Restriction;
           km4c:where ?where;
	   km4c:access ?access .
	km4c:AccessRestriction rdfs:subClassOf km4c:Restriction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?s_who), "/", fn:urlEncode(?s_direction), "/", fn:urlEncode(?s_condition)))
?where = uri(concat("http://www.disit.org/km4city/resource/", ?p_where))
?access = plainLiteral(?p_access)

From [[
select *, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_access
union
select *, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_access
union
select *, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_access
union
select *, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_oneway
union
select *, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_oneway
union
select *, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_oneway
]]

Create View AccessRestrictionsWho As

Construct {
Graph ?graph_uri {
	?s km4c:who ?who
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?p_who), "/", fn:urlEncode(?s_direction), "/", fn:urlEncode(?s_condition)))
?who = plainLiteral(?p_who)
From [[
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_access where p_who is not null
union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_access where p_who is not null
union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_access where p_who is not null
union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_oneway where p_who is not null
union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_oneway where p_who is not null
union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_oneway where p_who is not null
]]

Create View AccessRestrictionsDirection As

Construct {
Graph ?graph_uri {
	?s km4c:direction ?direction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?s_who), "/", fn:urlEncode(?p_direction), "/", fn:urlEncode(?s_condition)))
?direction = plainLiteral(?p_direction)
From [[
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from node_access where p_direction is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from way_access where p_direction is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from relation_access where p_direction is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from node_oneway where p_direction is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from way_oneway where p_direction is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from relation_oneway where p_direction is not null
]]

Create View AccessRestrictionsCondition As

Construct {
Graph ?graph_uri {
	?s km4c:condition ?condition
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?s_who), "/", fn:urlEncode(?s_direction), "/", fn:urlEncode(?p_condition)))
?condition = plainLiteral(?p_condition)
From [[
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from node_access where p_condition is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from way_access where p_condition is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from relation_access where p_condition is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from node_oneway where p_condition is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from way_oneway where p_condition is not null
union
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from relation_oneway where p_condition is not null
]]

/***************************
*** MaxMinRestrictions *****
***************************/

Create View MaxMinRestrictions As

Construct {
Graph ?graph_uri {
	?s a km4c:MaxMinRestriction;
           a km4c:Restriction;
	   km4c:where ?where;
	   km4c:what ?what;
	   km4c:limit ?limit .
	km4c:MaxMinRestriction rdfs:subClassOf km4c:Restriction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/maxmin/", fn:urlEncode(?p_what), "/" , fn:urlEncode(?s_direction), "/", fn:urlEncode(?s_condition))) 
?where = uri(concat("http://www.disit.org/km4city/resource/", ?p_where))
?what = plainLiteral(?p_what)
?limit = plainLiteral(?p_limit)

From [[
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxweight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxaxleload union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxheight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxwidth union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxlength union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxdraught union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_minspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from node_maxstay union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxweight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxaxleload union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxheight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxwidth union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxlength union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxdraught union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_minspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from way_maxstay union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxweight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxaxleload union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxheight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxwidth union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxlength union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxdraught union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_minspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from relation_maxstay
]]

Create View MaxMinRestrictionsDirection As

Construct {
Graph ?graph_uri {
	?s km4c:direction ?direction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/maxmin/", fn:urlEncode(?p_what), "/" , fn:urlEncode(?p_direction), "/", fn:urlEncode(?s_condition))) 
?direction = plainLiteral(?p_direction)

From [[
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxweight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxaxleload where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxheight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxwidth where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxlength where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxdraught where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_minspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from node_maxstay where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxweight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxaxleload where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxheight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxwidth where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxlength where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxdraught where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_minspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from way_maxstay where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxweight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxaxleload where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxheight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxwidth where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxlength where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxdraught where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_minspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from relation_maxstay where p_direction is not null 
]]

Create View MaxMinRestrictionsCondition As

Construct {
Graph ?graph_uri {
	?s km4c:condition ?condition
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/maxmin/", fn:urlEncode(?p_what), "/" , fn:urlEncode(?s_direction), "/", fn:urlEncode(?p_condition))) 
?condition = plainLiteral(?p_condition)

From [[
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxweight where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxaxleload where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxheight where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxwidth where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxlength where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxdraught where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxspeed where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_minspeed where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from node_maxstay where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxweight where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxaxleload where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxheight where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxwidth where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxlength where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxdraught where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxspeed where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_minspeed where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from way_maxstay where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxweight where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxaxleload where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxheight where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxwidth where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxlength where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxdraught where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxspeed where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_minspeed where p_condition is not null union
select *, coalesce(p_direction, 'unconditioned') s_direction from relation_maxstay where p_condition is not null
]]

/****************************
**** Lanes ******************
****************************/

/*** Lane ******************/

Create View LanesURI As

Construct {
Graph ?graph_uri {
        ?lane a km4c:Lane ;
		km4c:where ?lanes ;
		km4c:position ?pos .
	?lanes km4c:lanesDetails ?lanes_details .
	?lanes_details a rdf:Seq .
	?lanes_details ?rdf_nnn ?lane
}}

With
?graph_uri = uri(?graph_uri)
?lanes = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction))) 
?lane = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/", ?pos)) 
?pos = typedLiteral(?pos,"http://www.w3.org/2001/XMLSchema#integer")
?lanes_details = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/details"))
?rdf_nnn = uri(concat("http://www.w3.org/1999/02/22-rdf-syntax-ns#",?rdf_nnn))

From [[
select distinct graph_uri, p_where, s_direction, pos, '_' || pos rdf_nnn from (
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_turn union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_access union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxweight union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxaxleload union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxheight union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxwidth union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxlength union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxdraught union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxspeed union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_minspeed union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxstay
) uris_tbl
]]

/*** Lanes Where *************/

Create View LanesWhere As

Construct {
Graph ?graph_uri {
	?lanes a km4c:Lanes ;
       	       km4c:where ?where .
	?where km4c:lanes ?lanes .
}}

With
?graph_uri = uri(?graph_uri)
?where = uri(concat("http://www.disit.org/km4city/resource/", ?p_where)) 
?lanes = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction))) 

From [[
select distinct graph_uri, p_where, s_direction from (
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_count union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_turn union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_access union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxweight union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxaxleload union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxheight union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxwidth union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxlength union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxdraught union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxspeed union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_minspeed union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction from lanes_maxstay
) uris_tbl
]]

/*** Lanes.direction *************/

Create View LanesDirection As

Construct {
Graph ?graph_uri {
	?lanes km4c:direction ?direction
}}

With
?graph_uri = uri(?graph_uri)
?lanes = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?p_direction))) 
?direction = plainLiteral(?p_direction)

From [[
select distinct graph_uri, p_where, p_direction from (
select graph_uri, p_where, p_direction from lanes_count where not p_direction is null union
select graph_uri, p_where, p_direction from lanes_turn where not p_direction is null union
select graph_uri, p_where, p_direction from lanes_access where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxweight where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxaxleload where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxheight where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxwidth where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxlength where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxdraught where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxspeed where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_minspeed where not p_direction is null union
select graph_uri, p_where, p_direction s_direction from lanes_maxstay where not p_direction is null
) lanes_direction_tbl
]]

/*** Turns ***/
Create View Turns As

Construct {
Graph ?graph_uri {
	?lane km4c:turn ?turn 
}}

With
?graph_uri = uri(?graph_uri)
?lane = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?p_pos)) 
?turn = plainLiteral(?turn)

From [[
select distinct graph_uri, p_where, coalesce(p_direction, 'alldirections') s_direction, pos p_pos, turn from lanes_turn
]]

/*** Lanes Restrictions Bag URIs ***/

Create View LanesRestrictionsBagURIs As

Construct {
Graph ?graph_uri {
	?lane_restrictions a rdf:Bag .
	?lane km4c:restrictions ?lane_restrictions
}}

With
?graph_uri = uri(?graph_uri)
?lane = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?pos)) 
?lane_restrictions = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?pos, "/restrictions")) 
From [[
select distinct graph_uri, p_where, s_direction, pos from (
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_access union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxweight union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxaxleload union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxheight union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxwidth union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxlength union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxdraught union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxspeed union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_minspeed union
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, pos from lanes_maxstay
) uris
]]

/*** Lanes Access Restrictions ***/

Create View LanesAccessRestrictions As

Construct {
Graph ?graph_uri {
	?restriction a km4c:AccessRestriction ;
		     a km4c:Restriction;
		     km4c:where ?where;
		     km4c:access ?access .
        ?lane_restr_bag ?rdf_nnn ?restriction .
	km4c:AccessRestriction rdfs:subClassOf km4c:Restriction
}}

With
?graph_uri = uri(?graph_uri)
?restriction = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?s_who), "/", fn:urlEncode(?s_direction), "/", fn:urlEncode(?s_condition), "/lanes/" , ?pos))
?where = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?pos)) 
?access = plainLiteral(?p_access)
?lane_restr_bag = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?pos, "/restrictions")) 
?rdf_nnn = uri(concat("http://www.w3.org/1999/02/22-rdf-syntax-ns#",?rdf_nnn))

From [[
select graph_uri, p_where, coalesce(p_who,'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition, pos, restriction p_access, '_' || rank() over (partition by p_where, coalesce(p_direction, 'alldirections'), pos order by coalesce(p_who,'everybody'), coalesce(p_condition, 'unconditioned'), restriction) rdf_nnn from lanes_access 
]]

Create View LanesAccessRestrictionsWho As

Construct {
Graph ?graph_uri {
	?s km4c:who ?who
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?p_who), "/", fn:urlEncode(?s_direction), "/", fn:urlEncode(?s_condition), "/lanes/" , ?pos))
?who = plainLiteral(?p_who)
From [[
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_access where p_who is not null
]]

Create View LanesAccessRestrictionsDirection As

Construct {
Graph ?graph_uri {
	?s km4c:direction ?direction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?s_who), "/", fn:urlEncode(?p_direction), "/", fn:urlEncode(?s_condition), "/lanes/" , ?pos))
?direction = plainLiteral(?p_direction)
From [[
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_condition, 'unconditioned') s_condition from lanes_access where p_direction is not null
]]

Create View LanesAccessRestrictionCondition As

Construct {
Graph ?graph_uri {
	?s km4c:condition ?condition
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/access/", fn:urlEncode(?s_who), "/", fn:urlEncode(?s_direction), "/", fn:urlEncode(?p_condition), "/lanes/" , ?pos))
?condition = plainLiteral(?p_condition)
From [[
select *, coalesce(p_who, 'everybody') s_who, coalesce(p_direction, 'alldirections') s_direction from lanes_access where p_condition is not null
]]

/***** Lanes Max Min Restrictions ************/

Create View LanesMaxMinRestrictions As

Construct {
Graph ?graph_uri {
	?s a km4c:MaxMinRestriction;
           a km4c:Restriction;
	   km4c:where ?where;
	   km4c:what ?what;
	   km4c:limit ?limit .
	?lane_restr_bag ?rdf_nnn ?s .
	km4c:MaxMinRestriction rdfs:subClassOf km4c:Restriction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/maxmin/", fn:urlEncode(?p_what), "/" , fn:urlEncode(?s_direction), "/", fn:urlEncode(?s_condition), "/lanes/", ?pos)) 
?where = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?pos)) 
?what = plainLiteral(?p_what)
?limit = plainLiteral(?p_limit)
?lane_restr_bag = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/" , ?pos, "/restrictions")) 
?rdf_nnn = uri(concat("http://www.w3.org/1999/02/22-rdf-syntax-ns#",?rdf_nnn))

From [[
select lanes_maxmin_tbl.*, '_' || ( access_count_tbl.access_count + rank() over (partition by lanes_maxmin_tbl.p_where, lanes_maxmin_tbl.s_direction, lanes_maxmin_tbl.pos order by p_what, s_condition, p_limit) ) rdf_nnn from (
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxweight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxaxleload union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxheight union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxwidth union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxlength union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxdraught union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_minspeed union
select *, coalesce(p_direction, 'alldirections') s_direction, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxstay 
) lanes_maxmin_tbl 
join 
(
	select p_where, coalesce(p_direction, 'alldirections') s_direction, pos, count(1) access_count from lanes_access 
	group by p_where, coalesce(p_direction, 'alldirections'), pos
) access_count_tbl
on  lanes_maxmin_tbl.p_where = access_count_tbl.p_where and lanes_maxmin_tbl.s_direction = access_count_tbl.s_direction and lanes_maxmin_tbl.pos = access_count_tbl.pos
]]

Create View LanesMaxMinRestrictionsDirection As

Construct {
Graph ?graph_uri {
	?s km4c:direction ?direction
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/maxmin/", fn:urlEncode(?p_what), "/" , fn:urlEncode(?p_direction), "/", fn:urlEncode(?s_condition), "/lanes/", ?pos)) 
?direction = plainLiteral(?p_direction)

From [[
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxweight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxaxleload where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxheight where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxwidth where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxlength where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxdraught where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_minspeed where p_direction is not null union
select *, coalesce(p_condition, 'unconditioned') s_condition from lanes_maxstay where p_direction is not null
]]

Create View LanesMaxMinRestrictionsCondition As

Construct {
Graph ?graph_uri {
	?s km4c:condition ?condition
}}

With
?graph_uri = uri(?graph_uri)
?s = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/restriction/maxmin/", fn:urlEncode(?p_what), "/" , fn:urlEncode(?s_direction), "/", fn:urlEncode(?p_condition), "/lanes/", ?pos)) 
?condition = plainLiteral(?p_condition)

From [[
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxweight where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxaxleload where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxheight where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxwidth where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxlength where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxdraught where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxspeed where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_minspeed where p_condition is not null union
select *, coalesce(p_direction, 'alldirections') s_direction from lanes_maxstay where p_condition is not null 
]]

/****** Lanes.lanesCount URI *****/

Create View LanesCountURI As

Construct {
Graph ?graph_uri {
	?lanes km4c:lanesCount ?lanesCount .
	?lanesCount a km4c:LanesCount ;
	            ?means ?count
	
}}

With
?graph_uri = uri(?graph_uri)
?lanesCount = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction), "/count" )) 
?lanes = uri(concat("http://www.disit.org/km4city/resource/", ?p_where, "/lanes/", fn:urlEncode(?s_direction))) 
?means = uri(concat("http://www.disit.org/km4city/schema#",?p_who))
?count = typedLiteral(?lanes_count,"http://www.w3.org/2001/XMLSchema#decimal")
From [[
select graph_uri, p_where, coalesce(p_direction,'alldirections') s_direction, coalesce(p_who,'undesignated') p_who, lanes_count from lanes_count
]]

/************************************************
******** Numeri civici senza strada *************
************************************************/


Create view NodeStreetNumberPlace As

Construct {
Graph ?graph_uri {
?cn a km4c:StreetNumber .
?cn dct:identifier ?identifier .
?cn km4c:extendNumber ?extend_number .
?cn km4c:number ?number .
?cn km4c:exponent ?exponent .
?cn km4c:classCode ?classCode .
?cn km4c:place ?place .
?cn km4c:hasExternalAccess ?ne .
?ne a km4c:Entry .
?ne dct:identifier ?ne_identifier .
?ne km4c:entryType ?entryType .
?ne geo:long ?long .
?ne geo:lat ?lat .
?ne km4c:porteCochere ?porteCochere .
}}

With 
?graph_uri = uri(?graph_uri)
?cn = uri(concat("http://www.disit.org/km4city/resource/", ?cn_id))
?identifier = plainLiteral(?cn_id)
?extend_number = plainLiteral(?extend_number)
?number = plainLiteral(?number)
?exponent = plainLiteral(?exponent)
?place = plainLiteral(?place)
?classCode = plainLiteral(?class_code)
?ne = uri(concat("http://www.disit.org/km4city/resource/", ?en_id))
?ne_identifier = plainLiteral(?en_id)
?entryType = plainLiteral(?entry_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?porteCochere = plainLiteral(?porte_cochere)

From [[
select * from NodeStreetNumberPlace
]]

Create view WayStreetNumberPlace As

Construct {
Graph ?graph_uri {
?cn a km4c:StreetNumber .
?cn dct:identifier ?identifier .
?cn km4c:extendNumber ?extend_number .
?cn km4c:number ?number .
?cn km4c:exponent ?exponent .
?cn km4c:classCode ?classCode .
?cn km4c:place ?place .
?cn km4c:hasExternalAccess ?ne .
?ne a km4c:Entry .
?ne dct:identifier ?ne_identifier .
?ne km4c:entryType ?entryType .
?ne geo:long ?long .
?ne geo:lat ?lat .
?ne km4c:porteCochere ?porteCochere .
}}

With 
?graph_uri = uri(?graph_uri)
?cn = uri(concat("http://www.disit.org/km4city/resource/", ?cn_id))
?identifier = plainLiteral(?cn_id)
?extend_number = plainLiteral(?extend_number)
?number = plainLiteral(?number)
?exponent = plainLiteral(?exponent)
?place = plainLiteral(?place)
?classCode = plainLiteral(?class_code)
?ne = uri(concat("http://www.disit.org/km4city/resource/", ?en_id))
?ne_identifier = plainLiteral(?en_id)
?entryType = plainLiteral(?entry_type)
?long = typedLiteral(?long, "http://www.w3.org/2001/XMLSchema#float")
?lat = typedLiteral(?lat, "http://www.w3.org/2001/XMLSchema#float")
?porteCochere = plainLiteral(?porte_cochere)

From [[
select * from WayStreetNumberPlace
]]

/************************************************
******** NamedArea ******************************
************************************************/

/******* ResidentialArea ***********************/

Create View ResidentialArea As
Construct {
Graph ?graph_uri {
	?area_id a km4c:ResidentialArea ; 
		a ?area_type ;
		dct:identifier ?area_dct_id ; 
		km4c:inMunicipalityOf ?municipality;
		foaf:name ?area_name;
		geo:geometry ?geometry		
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?area_dct_id = plainLiteral(?area_id)
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id))
?area_name = plainLiteral(?area_name)
?geometry = typedLiteral(?geometry, "http://www.openlinksw.com/schemas/virtrdf#Geometry")
?area_type = uri(?area_type)
From [[
select distinct graph_uri, area_id, municipality_id, coalesce(area_name,'Unnamed Residential Area') area_name, case when area_name is null then 'http://www.disit.org/km4city/schema#UnnamedArea' else 'http://www.disit.org/km4city/schema#NamedArea' end area_type, geometry from ResidentialArea where name_language is null 
]]

Create View ResidentialAreaLocalizedNames As
Construct {
Graph ?graph_uri {
	?area_id foaf:name ?area_name		
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?area_name = plainLiteral(?area_name,?name_language)
From [[
select distinct graph_uri, area_id, coalesce(area_name,'Unnamed Residential Area') area_name, name_language from ResidentialArea where name_language is not null
]]

Create View ResidentialAreaLinkedHamlets As
Construct {
Graph ?graph_uri {
	?area_id rdfs:seeAlso ?linked_hamlet .
	?linked_hamlet rdfs:seeAlso ?area_id
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?linked_hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?linked_hamlet))
From [[
select distinct graph_uri, area_id, regexp_split_to_table(linked_hamlet,'\|') linked_hamlet from ResidentialArea where linked_hamlet is not null
]]

/******* CommercialArea ***********************/

Create View CommercialArea As
Construct {
Graph ?graph_uri {
	?area_id a km4c:CommercialArea ; 
		a ?area_type ;
		dct:identifier ?area_dct_id ; 
		km4c:inMunicipalityOf ?municipality;
		foaf:name ?area_name;
		geo:geometry ?geometry		
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?area_dct_id = plainLiteral(?area_id)
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id))
?area_name = plainLiteral(?area_name)
?geometry = typedLiteral(?geometry, "http://www.openlinksw.com/schemas/virtrdf#Geometry")
?area_type = uri(?area_type)
From [[
select distinct graph_uri, area_id, municipality_id, coalesce(area_name,'Unnamed Commercial Area') area_name, case when area_name is null then 'http://www.disit.org/km4city/schema#UnnamedArea' else 'http://www.disit.org/km4city/schema#NamedArea' end area_type, geometry from CommercialArea where name_language is null
]]

Create View CommercialAreaLocalizedNames As
Construct {
Graph ?graph_uri {
	?area_id foaf:name ?area_name		
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?area_name = plainLiteral(?area_name,?name_language)
From [[
select distinct graph_uri, area_id, coalesce(area_name,'Unnamed Commercial Area') area_name, name_language from CommercialArea where name_language is not null
]]

Create View CommercialAreaLinkedHamlets As
Construct {
Graph ?graph_uri {
	?area_id rdfs:seeAlso ?linked_hamlet .
	?linked_hamlet rdfs:seeAlso ?area_id
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?linked_hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?linked_hamlet))
From [[
select distinct graph_uri, area_id, regexp_split_to_table(linked_hamlet,'\|') linked_hamlet from CommercialArea where linked_hamlet is not null
]]

/******* IndustrialArea ***********************/

Create View IndustrialArea As
Construct {
Graph ?graph_uri {
	?area_id a km4c:IndustrialArea ; 
		a ?area_type ;
		dct:identifier ?area_dct_id ;
		km4c:inMunicipalityOf ?municipality;
		foaf:name ?area_name;
		geo:geometry ?geometry		
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?area_dct_id = plainLiteral(?area_id)
?municipality = uri(concat("http://www.disit.org/km4city/resource/", ?municipality_id))
?area_name = plainLiteral(?area_name)
?geometry = typedLiteral(?geometry, "http://www.openlinksw.com/schemas/virtrdf#Geometry")
?area_type = uri(?area_type)
From [[
select distinct graph_uri, area_id, municipality_id, coalesce(area_name,'Unnamed Industrial Area') area_name, case when area_name is null then 'http://www.disit.org/km4city/schema#UnnamedArea' else 'http://www.disit.org/km4city/schema#NamedArea' end area_type, geometry from IndustrialArea where name_language is null
]]

Create View IndustrialAreaLocalizedNames As
Construct {
Graph ?graph_uri {
	?area_id foaf:name ?area_name		
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?area_name = plainLiteral(?area_name,?name_language)
From [[
select distinct graph_uri, area_id, coalesce(area_name,'Unnamed Industrial Area') area_name, name_language from IndustrialArea where name_language is not null
]]

Create View IndustrialAreaLinkedHamlets As
Construct {
Graph ?graph_uri {
	?area_id rdfs:seeAlso ?linked_hamlet .
	?linked_hamlet rdfs:seeAlso ?area_id
}}
With
?graph_uri = uri(?graph_uri)
?area_id = uri(concat("http://www.disit.org/km4city/resource/", ?area_id))
?linked_hamlet = uri(concat("http://www.disit.org/km4city/resource/", ?linked_hamlet))
From [[
select distinct graph_uri, area_id, regexp_split_to_table(linked_hamlet,'\|') linked_hamlet from IndustrialArea where linked_hamlet is not null
]]

/****************************************
*********** Istanziazione di ************
*********** StreetNumber e Entry ********
*********** dai building names **********
*********** legati con la Road **********
*********** attraverso la distanza ******
****************************************/

Create view BuildingNameStreetNumberRoad As

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
select * from BuildingNameStreetNumberRoad
]]
