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
   
const { DBClient } = require("../db-instance");
const { PoolWorkers } = require("../workers/pool-workers");
const fs = require("fs");
const path = require("path");
const colors = require('ansi-colors');
const { MultiBarWorker } = require("../workers/multibar-worker");

const highwaySupported = ["unclassified","service","residential","primary","tertiary","tertiary_link","secondary","track","trunk_link","primary_link","motorway"];
// Phase 1 of the process: getting only supported highway type without the tag oneway = 'yes' 
/**
 * 
 * @param {any} data1 base data
 * 
 * ## data1 format
 * ```
 * data = {
 *      name: name of the field
 *      query: query to execute
 *      countQuery: if limit is set the count query is needed
 *      id: id to join
 *      save: 'join' | 'no-join' | 'all' [default: 'all']
 *      output: name of the file saved [default: data.name]
 * ]
 * ```
 * 
 * @param {any} data2 reference data
 * 
 ** ## data2 format
 * ```
 * data = {
 *      name: name of the field
 *      query: query to execute
 *      id: id to join
 * ]
 * ```
 * 
 * @param {number} nrThread number of thread for the process
 */
async function fuseData(dbClient, data1, data2, nrThread = 8, limit = -1) {
    return new Promise(async (resolve, reject) => {
        // const dbClient = new DBClient();
        await dbClient.connect();

        if (data1.result && data2.result)
            unifyData(data1, data2, nrThread, resolve);
        else {
            if (limit != -1) {
                if (!data2.result)
                    data2.result = await dbClient.getQuery(data2.query);
                const res = await dbClient.getQuery(data1.countQuery);
                const count = parseInt(res[0].count);
                const maxIter = Math.ceil(count / limit);
                let resultIsArray = data1.action == 'join' || data1.action == 'no-join';
                let result = resultIsArray ? [] : {};
                for (let i = 0; i < maxIter; i++) {
                    console.log(colors.yellow(`Processing subdata ${i + 1}/${maxIter}`))
                    const subquery = data1.query + ` LIMIT ${limit} OFFSET ${i * limit}`;
                    const subdata = await dbClient.getQuery(subquery);
                    data1.result = subdata;
                    const subresult = await unifyData(data1, data2, nrThread);
                    delete data1.result;
                    if (resultIsArray)
                        for (let sr of subresult)
                            result.push(sr)
                    else {
                        for (let sr of subresult["joined"])
                            result["joined"].push(sr);
                        for (let sr of subresult["not-joined"])
                            result["not-joined"].push(sr);
                    }
                    delete subresult;
                }
                resolve(result);
            } else {
                if (!data1.result)
                        dbClient.getQuery(data1.query).then(async (data) => {
                            data1.result = data;
                            const result = await unifyData(data1, data2, nrThread);
                            if (result)
                                resolve(result);
                        });
                if (!data2.result)
                    dbClient.getQuery(data2.query).then(async (data) => {
                        data2.result = data;
                        const result = await unifyData(data1, data2, nrThread);
                        if (result)
                            resolve(result);
                    });
            }
        }
    });
}

async function unifyData(data1, data2, nrThread) {
    if (!data1.result || !data2.result) 
        return;
    return new Promise((resolve, reject) => {
        const poolWorkers = new PoolWorkers(nrThread);
        poolWorkers.createPool('./src/workers/unify-worker.js');

        var result1Splitted = [];

        const multibar = new MultiBarWorker();

        console.log('data to process', data1.result.length);
        for (let i = 0; i < nrThread; i++) {
            const subresult = data1.result.splice(0, Math.ceil(data1.result.length / (nrThread - i)));
            multibar.addBar(subresult.length);
            result1Splitted.push(subresult);
        }
        poolWorkers.setMultiBar(multibar);

        var dataToSend = [];
        for (let i = 0; i < nrThread; i++) {
            dataToSend.push([
                {
                    data: result1Splitted[i], 
                    id: data1.id,
                    name: data1.name
                },
                {
                    data: data2.result, 
                    id: data2.id,
                    name: data2.name
                }
            ]);
        }
        poolWorkers.sendMessage(dataToSend, true);
        var resultData = [];
        var notFoundData = [];
        var i = 0;
        poolWorkers.listenMessage((result) => {
            i++;
            resultData.push(...result[0]);
            notFoundData.push(...result[1]);
            if (i == nrThread) {
                poolWorkers.terminate();

                var result; 
                switch (data1.action) {
                    case "join":
                        result = resultData;
                        break;
                    case "no-join":
                        result = notFoundData;
                        break;
                    case "all":
                    default:
                        result = {
                            "joined": resultData,
                            "not-joined": notFoundData,
                        }
                        break;
                }
                delete resultData;
                delete notFoundData;
                console.log(colors.green("Unify data process ended"));
                resolve(result);
            }
        });
    });
}

module.exports = {
    fuseData
}