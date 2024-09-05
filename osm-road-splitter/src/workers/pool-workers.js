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
   
const { Worker } = require("worker_threads");
const { MultiBarWorker } = require("./multibar-worker");

class PoolWorkers {
    nrThread;
    /** @type {[Worker]} */
    _workers = [];
    /** @type {MultiBarWorker} */
    multibar;

    constructor(nrThread = 8, printBar = true) {
        this.nrThread = nrThread;
        if (printBar) {

        }
    }

    cleanWorkers() {
        for (let worker of this._workers)
            worker.terminate();
    }

    setBar(bar) {
        this.bar = bar;
    }

    setMultiBar(multibar) {
        this.multibar = multibar;
    }

    createPool(url, data) {
        this.cleanWorkers();
        for (let i = 0; i < this.nrThread; i++) {
            this._workers.push(new Worker(url, {workerData: {
                data: data,
                nrThread: i,
            }} ));
        }
    }

    sendMessage(message, isDataSplitted = false) {
        let i = 0;
        for (let worker of this._workers) {
            if (isDataSplitted)
                worker.postMessage(message[i]);
            else
                worker.postMessage(message);
            i++;
        }
    }

    listenMessage(callback) {
        let i = 0;
        for (let worker of this._workers) {
            worker.on('message', (message) => {
                const {data, id} = message;
                switch (message.action) {
                    case 'log':
                        console.log(`[LOG][Worker ${id}] => `, data);
                        break;
                    case 'increment':
                        if (this.multibar) {
                            this.multibar.increment(parseInt(id));
                        }
                        break;
                    case 'end':
                        callback(data);
                        break;
                }
            });
            i++;
        }
    }

    listenError(callback) {
        for (let worker of this._workers)
            worker.on('error', (message) => callback(message));
    }

    terminate() {
        if (this.multibar)
            this.multibar.stop();
        for (let worker of this._workers)
            worker.terminate();
    }
}

module.exports = {PoolWorkers};