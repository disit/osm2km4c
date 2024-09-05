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
   
const fs = require('fs');

// Dati dei punti
// const pointAbove = { x: 100, y: 100 }; // Sostituisci con le coordinate dei punti sopra la retta
// const pointBelow = { x: 200, y: 200 }; // Sostituisci con le coordinate dei punti sotto la retta

// Funzione per trovare i punti di intersezione tra due rette
function findIntersection(m1, q1, m2, q2) {
  // Calcola le coordinate x e y del punto di intersezione
  const x = (q2 - q1) / (m1 - m2);
  const y = m1 * x + q1;
  return { x, y };
}

// Dati della retta data
const m = 2; // Pendenza della retta data
const q1 = 3; // Termine noto della retta data

// Distanza "x" dalle rette parallele
const x = 2;

// Calcola il coefficiente angolare per le rette parallele
const mParallel = -1 / m;

// Calcola il termine noto per le rette parallele sopra e sotto la retta data
const qAbove = q1 + x * Math.sqrt(1 + m ** 2);
const qBelow = q1 - x * Math.sqrt(1 + m ** 2);

// Trova i punti di intersezione sopra e sotto la retta data
const pointAbove = findIntersection(m, q1, mParallel, qAbove);
const pointBelow = findIntersection(m, q1, mParallel, qBelow);

console.log("Punto di intersezione sopra:", pointAbove);
console.log("Punto di intersezione sotto:", pointBelow);

import { plot} from 'nodeplotlib';

const trace1 = { x: [1, 2], y: [1, 2], type: 'scatter' };
const trace2 = { x: [3, 4], y: [9, 16], type: 'scatter' };
plot([trace1, trace2]);