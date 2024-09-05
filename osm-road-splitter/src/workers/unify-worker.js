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
const {increment, log, sendEndData} = require("./thread");

function unify(data1, data2) {
    var notFounded = [];
    let i = 0;
    for (let d1 of data1.data) {
        const id1 = data1.id;
        const v1 = d1[id1];
        let founded = false;
        for (let d2 of data2.data) {
            const id2 = data2.id;
            const v2 = d2[id2];
            if (v1 === v2) {
                const temp = d1
                data1.data[i] = {};
                data1.data[i][data1.name] = {...temp}
                data1.data[i][data2.name] = {...d2}
                founded = true;
                break;
            }
        }
        if (founded == false)
            notFounded.push(i);
        increment();
        i++;
    }
    var notFoundData = [];
    for (let i = 0; i < notFounded.length; i++) {
        const nf = data1.data.splice(notFounded[i] - i, 1);
        notFoundData.push(...nf);
    }
    return notFoundData;
}

parentPort.on('message', (message) => {
    var notFoundData = [];
    for (let i = 1; i < message.length; i++) {
        notFoundData.push(...unify(message[0], message[i]));
    }
    sendEndData([message[0].data, notFoundData]);
});