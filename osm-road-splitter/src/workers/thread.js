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
   
const { workerData, parentPort } = require("worker_threads");

data = workerData.data;        
id = workerData.nrThread;

function log(message) {
    parentPort.postMessage({
        action: 'log',
        id,
        data: message
    })
}

function sendEndData(data) {
    parentPort.postMessage({
        action: 'end',
        id,
        data
    })
}

function increment() {
    parentPort.postMessage({
        action: 'increment',
        id,
    })
}

module.exports = {
    data,
    id,
    increment,
    log,
    sendEndData,
};