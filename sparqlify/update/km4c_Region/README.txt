OSM2KM4C
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
along with this program.  If not, see <http://www.gnu.org/licenses/>. 

Mappatura OSM -> KM4C Ontology relativamente alle regioni
---------------------------------------------------------

Si propone di istanziare una nuova regione per ciascuna relation di OSM taggata con type = boundary, boundary = administrative, admin_level = 4.

Si propone di utilizzare per le istanze delle regioni in KM4C, il tipo km4c:Region.

Per ciascuna istanza di km4c:Region, si propone di valorizzare le seguenti proprietà:

dct:identifier
"OS" + ID OSM della relation con padding di zeri a sinistra fino a raggiungere le 11 cifre + "RG"

foaf:name
con la valorizzazione del tag name della relation che rappresenta la regione

dct:alternative
con la valorizzazione del tag short_name della relation che rappresenta la regione

km4c:hasProvince
si propone di generare un'istanza di questa proprietà per ciascuna delle province che appartengono alla regione, valorizzandola con la URI della provincia

Si propone infine di assegnare una URI formata dal prefisso km4c, a cui si concatena il dct:identifier.
