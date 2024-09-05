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
   
const fs = require('fs')

const jsonFile = fs.readFileSync('kb_highway_type.json', { encoding: 'utf8', flag: 'r' });
const json = JSON.parse(jsonFile);

const roadTypes = [];

for (let road of json.results.bindings) {
    const value = road.highwaytype.value;

    let founded = false;
    for (let type of roadTypes)
        if (type === value) {
            founded = true;
            break;
        }
    if (founded == false)
        roadTypes.push(value);
}

fs.writeFileSync('road_types.json', JSON.stringify(roadTypes));
