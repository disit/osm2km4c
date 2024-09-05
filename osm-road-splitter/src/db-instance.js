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

const { Client } = require("pg");

class DBClient {
    _client;
    isConnected = false;
    constructor(config) {
        this._client = new Client({
            password: "openstreetmap",
            database: "openstreetmap",
            user: "openstreetmap",
            host: process.env.DATABASE_HOST || "localhost",
            port: 54321,
            ...config
        });
    }

    async connect() {
        await this._client.connect();
        this.isConnected = true;
    }

    async close() {
        await this._client.end();
    }

    async getQuery(query, redoIfFailing = false) {
        return new Promise(async (resolve, reject) => {
            this._client.query(query)
                .then((payload) => {
                    resolve(payload.rows);
                })
                .catch(async (error) => {
                    console.error(error)
                    console.error('query failing: ', query);
                    if (redoIfFailing) {
                        const result = await this.getQuery(query, redoIfFailing);
                        resolve(result);
                    }
                    reject();
                });
        });
    }
}

module.exports = {
    DBClient
}