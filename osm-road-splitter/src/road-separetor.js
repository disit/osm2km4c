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
   
function getMeterDistance(lat1, lon1, lat2, lon2) {
	const R = 6371e3; // metres
	const φ1 = (lat1 * Math.PI) / 180; // φ, λ in radians
	const φ2 = (lat2 * Math.PI) / 180;
	const Δφ = ((lat2 - lat1) * Math.PI) / 180;
	const Δλ = ((lon2 - lon1) * Math.PI) / 180;

	const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
	const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

	return R * c; // in metres
}

function radians(degree) {
    return (Math.PI * degree) / 180;
}

function getDestinationPoint(lat, lon, distance, bearing) {
    const R = 6371000; // Earth's radius in meters

    const lat1 = (lat * Math.PI) / 180;
    const lon1 = (lon * Math.PI) / 180;
    const angularDistance = distance / R;
    const bearingRad = (bearing * Math.PI) / 180;

    const lat2 = Math.asin(Math.sin(lat1) * Math.cos(angularDistance) + Math.cos(lat1) * Math.sin(angularDistance) * Math.cos(bearingRad));
    const lon2 = lon1 + Math.atan2(Math.sin(bearingRad) * Math.sin(angularDistance) * Math.cos(lat1), Math.cos(angularDistance) - Math.sin(lat1) * Math.sin(lat2));

    // Convert back to degrees
    const newLat = (lat2 * 180) / Math.PI;
    const newLon = (lon2 * 180) / Math.PI;

    return [newLat, newLon];
}

function getBearing(lat1, lon1, lat2, lon2) {
    const lat1Rad = (lat1 * Math.PI) / 180;
    const lon1Rad = (lon1 * Math.PI) / 180;
    const lat2Rad = (lat2 * Math.PI) / 180;
    const lon2Rad = (lon2 * Math.PI) / 180;

    const y = Math.sin(lon2Rad - lon1Rad) * Math.cos(lat2Rad);
    const x = Math.cos(lat1Rad) * Math.sin(lat2Rad) - Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(lon2Rad - lon1Rad);

    let bearing = Math.atan2(y, x);

    // Convert radians to degrees
    bearing = (bearing * 180) / Math.PI;

    // Normalize the bearing to the range [0, 360)
    bearing = (bearing + 360) % 360;

    return bearing;
}

function splitRoad(p1, p2, distance = 2.8) {
    const bearing = getBearing(p1[1], p1[0], p2[1], p2[0]);

    const p3 = getDestinationPoint(p1[1], p1[0], distance, bearing + 45);
    const p4 = getDestinationPoint(p2[1], p2[0], distance, bearing + 45);

    const p5 = getDestinationPoint(p1[1], p1[0], distance, bearing - 45);
    const p6 = getDestinationPoint(p2[1], p2[0], distance, bearing - 45);

    return [[p3, p4], [p5, p6]];
}

module.exports = {
    splitRoad
}