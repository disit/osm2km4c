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
Prefix geo:<http://www.w3.org/2003/01/geo/wgs84_pos#>

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