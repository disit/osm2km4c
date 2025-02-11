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

const { fuseData } = require("./process/fuse-data");
const { onewayQuery, highwayQuery, waynodesQuery, countWaynodesQuery, roundAboutQuery, getWaysTagsQuery, roundaboutVersionQuery, relationsQuery, onewayYesQuery, relationMembersQuery, relationTagsQuery } = require("./queries");
const { splitRoad } = require("./road-separetor");
const fs = require('fs');
const path = require('path');
const colors = require('ansi-colors');
const { DBClient } = require("./db-instance");
const cliProgress = require('cli-progress');
const { version } = require("yargs");
const yaml = require('js-yaml');

const OSMDelta = 10000000;
var initaliDBConfig;
var finalDBConfig;

function aggregateWayNodes(waynodes) {
    const aggregatedWays = {};
    for (let node of waynodes) {
        let way_id = node.way_id;
        if (aggregatedWays.hasOwnProperty(way_id))
            aggregatedWays[way_id].push(node);
        else
            aggregatedWays[way_id] = [node];
    }
    for (let key of Object.keys(aggregatedWays)) {
        aggregatedWays[key].sort((a, b) => {
            let ris = parseInt(a.sequence_id) - parseInt(b.sequence_id);
            return ris;
        });
    }
    return aggregatedWays;
}

async function StartProcessData(args) {
    // reading config file
    console.log('Loading config.yml');
    const fileData = fs.readFileSync(path.join(__dirname, '../config.yml'));
    const config = yaml.load(fileData);
    if(process.env.INIDB_HOST)
        config.initialDatabase.host = process.env.INIDB_HOST
    if(process.env.INIDB_DATABASE)
        config.initialDatabase.database = process.env.INIDB_DATABASE
    if(process.env.INIDB_PORT)
        config.initialDatabase.port = process.env.INIDB_PORT
    if(process.env.INIDB_USER)
        config.initialDatabase.user = process.env.INIDB_USER
    if(process.env.INIDB_PASSWORD)
        config.initialDatabase.password = process.env.INIDB_PASSWORD

    if(process.env.DSTDB_HOST) {
        config.destinationType = 'db'
        config.destinationDatabase.host = process.env.DSTDB_HOST
    }
    if(process.env.DSTDB_DATABASE)
        config.destinationDatabase.database = process.env.DSTDB_DATABASE
    if(process.env.DSTDB_PORT)
        config.destinationDatabase.port = process.env.DSTDB_PORT
    if(process.env.DSTDB_USER)
        config.destinationDatabase.user = process.env.DSTDB_USER
    if(process.env.DSTDB_PASSWORD)
        config.destinationDatabase.password = process.env.DSTDB_PASSWORD

    initaliDBConfig = config.initialDatabase;
    const destinationType = config.destinationType;

    console.log('Testing inital database connection to ' + initaliDBConfig.host);
    const savePhasesResult = config.savePhasesResult;
    let dbInitial = new DBClient(initaliDBConfig);
    await dbInitial.connect();
    dbInitial.close();
    console.log('Done.');

    if (destinationType === 'db') {
        finalDBConfig = config.destinationDatabase;
        console.log('Testing destination database connection to '+finalDBConfig.host);
        let dbFinal = new DBClient(finalDBConfig);
        await dbFinal.connect();
        dbFinal.close();
        console.log('Done.');
    }

    const nrThread = args.t;
    const startPhase = args.p;

    var dataDir = path.join(__dirname, '../data');
    if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir);
    }
    var outDir = path.join(__dirname, '../out');
    if (!fs.existsSync(outDir)) {
        fs.mkdirSync(outDir);
    }
    let start=new Date();

    var highwayData;
    if (startPhase <= 1) {

        console.log(colors.yellow("Starting Phase 1: fuse highways and oneways "+start));
        highwayData = {
            name: "highway",
            id: "way_id",
            query: highwayQuery,
            action: "no-join",
        };
        const onewayData = {
            name: "oneway",
            id: "way_id",
            query: onewayQuery,
        };
        let dbInitial = new DBClient(initaliDBConfig);
        highwayData.result = await fuseData(dbInitial, highwayData, onewayData, nrThread);
        delete onewayData;
        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase1.json"), JSON.stringify(highwayData, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 1 Ended "+phaseEnd+" time:"+(phaseEnd-start)+"ms"));
    }

    var waynodes;
    if (startPhase <= 2) {
        let phaseStart = new Date();
        if (!highwayData)
            highwayData = JSON.parse(fs.readFileSync(path.join(dataDir, "phase1.json")));
        console.log(colors.yellow("Starting Phase 2: fuse waynodes and highways"));
        waynodes = {
            name: "waynodes",
            id: "way_id",
            query: waynodesQuery,
            countQuery: countWaynodesQuery,
            action: "join",
        };
        let dbInitial = new DBClient(initaliDBConfig);
        const result = await fuseData(dbInitial, waynodes, highwayData, nrThread);
        waynodes.result = [];
        for (let node of result) {
            const waynode = { ...node.waynodes, highway: node.highway.v };
            waynodes.result.push(waynode);
        }
        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase2.json"), JSON.stringify(waynodes, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 2 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    let aggregatedWays;
    if (startPhase <= 3) {
        let phaseStart = new Date();
        if (!waynodes)
            waynodes = JSON.parse(fs.readFileSync(path.join(dataDir, "phase2.json")));
        console.log(colors.yellow("Starting Phase 3: aggregate waynodes"));
        aggregatedWays = aggregateWayNodes(waynodes.result);
        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase3.json"), JSON.stringify(aggregatedWays, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 3 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    let waysToRemove;
    let roundaboutWays;
    if (startPhase <= 4) {
        let phaseStart = new Date();
        if (!aggregatedWays)
            aggregatedWays = JSON.parse(fs.readFileSync(path.join(dataDir, "phase3.json")));
        console.log(colors.yellow("Starting Phase 4: load round abouts and remove from aggregate ways"));

        const dbClient = new DBClient(initaliDBConfig);
        await dbClient.connect();
        roundaboutWays = await dbClient.getQuery(roundAboutQuery);
        for (let roundway of roundaboutWays)
            if (aggregatedWays.hasOwnProperty(roundway.way_id))
                delete aggregatedWays[roundway.way_id];

        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase4.json"), JSON.stringify({ aggregatedWays, roundaboutWays }, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 4 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    let invertedWays;
    if (startPhase <= 5) {
        let phaseStart = new Date();
        if (!aggregatedWays || !roundaboutWays) {
            const phase4Data = JSON.parse(fs.readFileSync(path.join(dataDir, "phase4.json")));
            aggregatedWays = phase4Data.aggregatedWays;
            roundaboutWays = phase4Data.roundaboutWays;
        }

        console.log(colors.yellow("Starting Phase 5: reverse index aggregate ways"));
        invertedWays = {};
        for (let key in aggregatedWays) {
            invertedWays[key] = [...aggregatedWays[key]];
            invertedWays[key].reverse();
        }

        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase5.json"), JSON.stringify({ aggregatedWays, invertedWays, roundaboutWays }, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 5 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    let invertedWaysTags;
    if (startPhase <= 6) {
        let phaseStart = new Date();
        if (!aggregatedWays || !invertedWays || !roundaboutWays) {
            const phase5Data = JSON.parse(fs.readFileSync(path.join(dataDir, "phase5.json")));
            aggregatedWays = phase5Data.aggregatedWays;
            invertedWays = phase5Data.invertedWays;
            roundaboutWays = phase5Data.roundaboutWays;
        }
        console.log(colors.yellow("Starting Phase 6: add tags to inverted ways"));
        const dbClient = new DBClient(initaliDBConfig);
        await dbClient.connect();
        const wayTags = await dbClient.getQuery(getWaysTagsQuery);
        invertedWaysTags = {};
        for (let wayTag of wayTags) {
            if (invertedWays.hasOwnProperty(wayTag.way_id)) {
                if (!invertedWaysTags.hasOwnProperty(wayTag.way_id))
                    invertedWaysTags[wayTag.way_id] = [];

                invertedWaysTags[wayTag.way_id].push(wayTag);
            }
        }

        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase6.json"), JSON.stringify({
                aggregatedWays, invertedWays, roundaboutWays, invertedWaysTags
            }, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 6 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    let invertedRelation;
    let relationsToCopy;
    let restrictions;
    if (startPhase <= 7) {
        let phaseStart = new Date();
        if (!aggregatedWays || !invertedWays || !roundaboutWays || !invertedWaysTags) {
            const phase6Data = JSON.parse(fs.readFileSync(path.join(dataDir, "phase6.json")));
            aggregatedWays = phase6Data.aggregatedWays;
            invertedWays = phase6Data.invertedWays;
            roundaboutWays = phase6Data.roundaboutWays;
            invertedWaysTags = phase6Data.invertedWaysTags;
        }
        console.log(colors.yellow("Starting Phase 7: load relations for restrictions"));

        const dbClient = new DBClient(initaliDBConfig);
        await dbClient.connect();
	//console.log(relationsQuery);
        const relations = await dbClient.getQuery(relationsQuery);
        dbClient.close();
        console.log("inverting relations");
        invertedRelation = {};
        let relationsToCopy = {};
        restrictions = {};
        platforms = {};
        for (let relation of relations) {
            if (relation.member_type === 'Way' && aggregatedWays.hasOwnProperty(relation.member_id)) {
                if (relation.k === 'restriction') {
                    if (!restrictions.hasOwnProperty(relation.id))
                        restrictions[relation.id] = [];
                } else if (!relation.member_role === 'platform') {
                    if (platforms.hasOwnProperty(relation.id))
                        platforms[relation.id] = [];
                    platforms[relation.id].push(relation);
                } else {
                    if (!relationsToCopy.hasOwnProperty(relation.id))
                        relationsToCopy[relation.id] = [];
                    relationsToCopy[relation.id].push(relation);
                }
            }
        }

        for (let relation of relations) {
            if (relation.k === 'restriction' && restrictions.hasOwnProperty(relation.id)) {
                restrictions[relation.id].push(relation);
            }
        }

        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase7.json"), JSON.stringify({
                aggregatedWays, invertedWays, roundaboutWays, invertedWaysTags, relationsToCopy, restrictions
            }, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 7 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    let restrictionToInvert;
    if (startPhase <= 8) {
        let phaseStart = new Date();
        if (!aggregatedWays || !invertedWays || !roundaboutWays || !invertedWaysTags || !relationsToCopy || !restrictions) {
            const phase7Data = JSON.parse(fs.readFileSync(path.join(dataDir, "phase7.json")));
            aggregatedWays = phase7Data.aggregatedWays;
            invertedWays = phase7Data.invertedWays;
            roundaboutWays = phase7Data.roundaboutWays;
            invertedWaysTags = phase7Data.invertedWaysTags;
            relationsToCopy = phase7Data.relationsToCopy;
            restrictions = phase7Data.restrictions;
        }
        console.log(colors.yellow("Starting Phase 8: invert restrictions"));

        let problematicRestrictions = {
            missingNode: [],
            cannotAttach: []
        };
        restrictionToInvert = {};
        for (let key in restrictions) {
            let restriction = restrictions[key];
            let nodeToConsider;
            let from;
            let to;
            for (let r of restriction) {
                if (r.member_type === 'Way') {
                    if (r.member_role === 'from')
                        from = r;
                    else if (r.member_role === 'to')
                        to = r;
                }
                if (r.member_type === 'Node') {
                    if (r.member_role === 'via')
                        nodeToConsider = r;
                }
            }

            if (!nodeToConsider) {
                problematicRestrictions.missingNode.push(key);
                continue;
            }

            if (from && aggregatedWays.hasOwnProperty(from.member_id)) {
                let itsOriginal = false;
                let itsInverted = false;

                const nodes = aggregatedWays[from.member_id];
                if (nodes[nodes.length - 1].id === nodeToConsider.member_id) {
                    itsOriginal = true
                }
                if (nodes[0].id === nodeToConsider.member_id) {
                    itsInverted = true
                }

                if ((!itsOriginal && itsInverted) || (itsOriginal && !itsInverted)) {
                    if (itsInverted) {
                        if (!restrictionToInvert.hasOwnProperty(from.member_id))
                            restrictionToInvert[from.member_id] = [];
                        restrictionToInvert[from.member_id].push(from);
                    }
                } else {
                    problematicRestrictions.cannotAttach.push(key);
                }
            }

            if (to && aggregatedWays.hasOwnProperty(to.member_id)) {
                let itsOriginal = false;
                let itsInverted = false;

                const nodes = aggregatedWays[to.member_id];
                if (nodes[0].id === nodeToConsider.member_id) {
                    itsOriginal = true
                }
                if (nodes[nodes.length - 1].id === nodeToConsider.member_id) {
                    itsInverted = true
                }

                if ((!itsOriginal && itsInverted) || (itsOriginal && !itsInverted)) {
                    if (itsInverted) {
                        if (!restrictionToInvert.hasOwnProperty(to.member_id))
                            restrictionToInvert[to.member_id] = [];
                        restrictionToInvert[to.member_id].push(to);
                    }
                } else {
                    problematicRestrictions.cannotAttach.push(key);
                }
            }
        }
        if (savePhasesResult)
            fs.writeFileSync(path.join(dataDir, "phase8.json"), JSON.stringify({
                aggregatedWays, invertedWays, roundaboutWays, invertedWaysTags, relationsToCopy, restrictionToInvert,
            }, null, 4));
        fs.writeFileSync(path.join(dataDir, "problematic_restriction.json"), JSON.stringify({
            problematicRestrictions
        }, null, 4));
        let phaseEnd = new Date();
        console.log(colors.green("Phase 8 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }

    if (startPhase <= 9) {
        let phaseStart = new Date();
        if (!aggregatedWays || !invertedWays || !roundaboutWays || !invertedWaysTags || !relationsToCopy || !restrictionToInvert) {
            const phase8Data = JSON.parse(fs.readFileSync(path.join(dataDir, "phase8.json")));
            aggregatedWays = phase8Data.aggregatedWays;
            invertedWays = phase8Data.invertedWays;
            roundaboutWays = phase8Data.roundaboutWays;
            invertedWaysTags = phase8Data.invertedWaysTags;
            relationsToCopy = phase8Data.relationsToCopy;
            restrictionToInvert = phase8Data.restrictionToInvert;
        }

        console.log(colors.yellow("Starting Phase 9: output"));
        if (fs.existsSync(path.join(outDir, "output.sql")))
            fs.rmSync(path.join(outDir, "output.sql"));
        // creazione query
        let sqlText = '';
        let numOfChanges = 1;
        let nowDate = new Date(Date.now());
        nowDate = nowDate.toISOString();
        // aggiunta del changeset record
        if (destinationType === 'sql') {
            // dichiarazioni variabili della transazione
            sqlText += 'DO $$\n';
            sqlText += 'DECLARE\n';
            sqlText += '\tID_USER BIGINT;\n';
            sqlText += '\tID_CHANGESET BIGINT;\n';
            sqlText += '\tID_INVERTED BIGINT;\n';
            sqlText += '\tID_RELATION BIGINT;\n';
            sqlText += 'BEGIN\n';
        }
        let finalClient;
        if (destinationType === 'db') {
            finalClient = new DBClient(finalDBConfig);
            await finalClient.connect();
        }

        // creating fake users
        const fdb = destinationType === 'db';
        sqlText += `\tINSERT INTO users (email, display_name, pass_crypt, creation_time) VALUES ('snap4city_${nowDate}.com', 'snap4city_${nowDate}', 'pass', '2024-01-18T10:35:33.653Z') RETURNING id${!fdb ? " INTO ID_USER" : ""};\n`;
        let fakeId;
        if (fdb) {
            const fakeUser = await finalClient.getQuery(sqlText, true);
            fakeId = fakeUser[0].id;
            console.log('new fake user created with id', fakeId);
            sqlText = "";
        }

        // creating changeset
        sqlText += '\tINSERT INTO changesets (user_id, created_at, min_lat, max_lat, min_lon, max_lon, closed_at, num_changes)'
            + ` VALUES (${fdb ? fakeId : "ID_USER"}, '${nowDate}', -900000000, 900000000, -1800000000, 1800000000, '${nowDate}', ${numOfChanges}) RETURNING id${!fdb ? " INTO ID_CHANGESET" : ""};\n`;
        sqlText += '\n';
        let changeset_id;
        if (fdb) {
            const changeset = await finalClient.getQuery(sqlText, true);
            changeset_id = changeset[0].id;
            console.log('new changeset created with id', changeset_id);
            sqlText = "";
        }

        const dbClient = new DBClient(initaliDBConfig);
        await dbClient.connect();

        const relationsMembersData = await dbClient.getQuery(relationMembersQuery);
        const relationsTagsData = await dbClient.getQuery(relationTagsQuery);

        const relationsMembers = {};
        for (let member of relationsMembersData) {
            if (!relationsMembers.hasOwnProperty(member.relation_id))
                relationsMembers[member.relation_id] = [];
            relationsMembers[member.relation_id].push(member);
        }
        const relationsTags = {};
        for (let tag of relationsTagsData) {
            if (!relationsTags.hasOwnProperty(tag.relation_id))
                relationsTags[tag.relation_id] = [];
            relationsTags[tag.relation_id].push(tag);
        }

        changeset_id = fdb ? changeset_id : "ID_CHANGESET";
        // inserimento tag one way per le rotonde
        for (let roundaboutWay of roundaboutWays) {
            // current
            sqlText += '\tINSERT INTO current_way_tags (way_id, k, v) VALUES ' +
                `(${roundaboutWay.way_id}, 'oneway', 'yes');\n`;
            // historic 
            let roundVersion = await dbClient.getQuery(`select version from current_ways where id = ${roundaboutWay.way_id}`)
            roundVersion = roundVersion[0].version;
            roundVersion = parseInt(roundVersion)
            sqlText += '\tINSERT INTO ways (way_id, changeset_id, timestamp, version, visible) VALUES ' +
                `(${roundaboutWay.way_id}, ${changeset_id}, '${nowDate}', ${roundVersion + 1}, true);\n`;
            sqlText += '\tINSERT INTO way_tags (way_id, k, v, version) VALUES ' +
                `(${roundaboutWay.way_id}, 'oneway', 'yes', ${roundVersion + 1});\n`;
            const roundTags = await dbClient.getQuery(`select * from way_tags where way_id = ${roundaboutWay.way_id} and version = ${roundVersion}`);
            for (let tag of roundTags) {
                sqlText += '\tINSERT INTO way_tags (way_id, k, v, version) VALUES ' +
                    `(${roundaboutWay.way_id}, '${tag.k}', '${tag.v.replaceAll("'", "''")}', ${roundVersion + 1});\n`;
            }
            const roundNodes = await dbClient.getQuery(`select * from way_nodes where way_id = ${roundaboutWay.way_id} and version = ${roundVersion}`);
            for (let node of roundNodes) {
                sqlText += '\tINSERT INTO way_nodes (way_id, node_id, version, sequence_id) VALUES ' +
                    `(${roundaboutWay.way_id}, '${node.node_id}', ${roundVersion + 1}, ${node.sequence_id});\n`;
            }
        }
        async function updateDb(message) {
            if (fdb) {
                await finalClient.getQuery(sqlText);
                console.log(message);
                sqlText = "";
            }
        }
        await updateDb(`${roundaboutWays.length} roundabout ways updated with the tag oneway`);

        const wayRelations = {};
        for (let key in relationsToCopy) {
            for (let relation of relationsToCopy[key]) {
                if (!wayRelations.hasOwnProperty(relation.member_id))
                    wayRelations[relation.member_id] = [];
                wayRelations[relation.member_id].push(relation);
            }
        }
        const wayRestrictrions = {};
        for (let key in restrictionToInvert) {
            for (let restriction of restrictionToInvert[key]) {
                if (!wayRestrictrions.hasOwnProperty(restriction.member_id))
                    wayRestrictrions[restriction.member_id] = [];
                wayRestrictrions[restriction.member_id].push(restriction);
            }
        }

        let bar;
        if (!fdb) {
            bar = new cliProgress.SingleBar({
                format: 'Writing sql file |' + colors.cyan('{bar}') + '| {percentage}% || {value}/{total} Chunks',
            }, cliProgress.Presets.shades_classic);
            bar.start(Object.keys(invertedWays).length, 1);
        }
        // inserimento delle strade invertite con le restrizione di inversione a u.
        for (let key in invertedWays) {
            if (fdb)
                console.log('processing way ', key);
            let invertedWay = invertedWays[key];
            let currentWayVersion = await dbClient.getQuery(`select version from current_ways where id = ${key}`)
            currentWayVersion = parseInt(currentWayVersion[0].version);

            // updating current way
            sqlText += `\tUPDATE current_ways SET (changeset_id, timestamp, version) = (${changeset_id}, '${nowDate}', ${currentWayVersion + 1}) WHERE id = ${key};\n`;
            sqlText += '\tINSERT INTO ways (way_id, changeset_id, timestamp, visible, version) VALUES ' +
                `(${key}, ${changeset_id}, '${nowDate}', true, ${currentWayVersion + 1});\n`;
            const currentTags = await dbClient.getQuery(`select * from way_tags where way_id = ${key} and version = ${currentWayVersion}`);
            let currentHasOneway = false
            for (let tag of currentTags) {
                if (tag.k === 'oneway')
                    currentHasOneway = true;
                else if (tag.k.includes('lanes'))
                    continue;
                else
                    sqlText += '\tINSERT INTO way_tags (way_id, k, v, version) VALUES ' +
                        `(${key}, '${tag.k}', '${tag.v.replaceAll("'", "''")}', ${currentWayVersion + 1});\n`;
            }
            
            const currentNodes = await dbClient.getQuery(`select * from way_nodes where way_id = ${key} and version = ${currentWayVersion}`);
            for (let node of currentNodes) {
                sqlText += '\tINSERT INTO way_nodes (way_id, node_id, version, sequence_id) VALUES ' +
                    `(${key}, '${node.node_id}', ${currentWayVersion + 1}, ${node.sequence_id});\n`;
            }
            await updateDb(`updated version for ${key}`);

            // inserting new way
            // current
            sqlText += '\tINSERT INTO current_ways (changeset_id, timestamp, visible, version) VALUES ' +
                `(${changeset_id}, '${nowDate}', true, 1) RETURNING id${!fdb ? " INTO ID_INVERTED" : ""};\n`;
            let invertedWay_id;
            if (fdb) {
                const invertedWay = await finalClient.getQuery(sqlText, true);
                invertedWay_id = invertedWay[0].id;
                console.log(`new inverted way created: ${key} -> ${invertedWay_id}`);
                sqlText = "";
            }
            invertedWay_id = fdb ? invertedWay_id : "ID_INVERTED";
            // historic
            sqlText += '\tINSERT INTO ways (way_id, changeset_id, timestamp, visible, version) VALUES ' +
                `(${invertedWay_id}, ${changeset_id}, '${nowDate}', true, 1);\n`;
            await updateDb(`created historic versioning for way ${invertedWay_id}`)

            // adding nodes
            let i = 1;
            for (let node of invertedWay) {
                // current
                sqlText += '\tINSERT INTO current_way_nodes (way_id, node_id, sequence_id) VALUES ' +
                    `(${invertedWay_id}, ${node.id}, ${i});\n`;
                // historic 
                sqlText += '\tINSERT INTO way_nodes (way_id, node_id, sequence_id, version) VALUES ' +
                    `(${invertedWay_id}, ${node.id}, ${i++}, 1);\n`;
            }
            await updateDb(`added ${invertedWay.length} nodes for ${invertedWay_id}`);

            // oneway tag
            // current
            sqlText += '\tINSERT INTO current_way_tags (way_id, k, v) VALUES ' +
                `(${invertedWay_id}, 'oneway', 'yes');\n`;
            if (currentHasOneway)
                sqlText += `\tUPDATE current_way_tags SET v = 'yes' WHERE way_id = ${key} AND k = 'oneway';\n`;
            else
                sqlText += '\tINSERT INTO current_way_tags (way_id, k, v) VALUES ' +
                    `(${key}, 'oneway', 'yes');\n`;
            // historic
            sqlText += '\tINSERT INTO way_tags (way_id, k, v, version) VALUES ' +
                `(${invertedWay_id}, 'oneway', 'yes', 1);\n`;
            sqlText += '\tINSERT INTO way_tags (way_id, k, v, version) VALUES ' +
                `(${key}, 'oneway', 'yes', ${currentWayVersion + 1});\n`;
            
            await updateDb('oneway setted to yes for both ways');

            let invertedWayTags = invertedWaysTags[key];
            let lanes;
            let lanesBackward;
            let lanesForward;
            for (let invertedWayTag of invertedWayTags) {
                switch (invertedWayTag.k) {
                    case "oneway":
                        break;
                    case "lanes":
                        lanes = parseInt(invertedWayTag.v)
                        break;
                    case "lanes:backward":
                        lanesBackward = parseInt(invertedWayTag.v)
                        break;
                    case "lanes:forward":
                        lanesForward = parseInt(invertedWayTag.v)
                        break;
                    default:
                        //current
                        sqlText += '\tINSERT INTO current_way_tags (way_id, k, v) VALUES ' +
                            `(${invertedWay_id}, '${invertedWayTag.k}', '${invertedWayTag.v.replaceAll("'", "''")}');\n`;
                        // historic
                        sqlText += '\tINSERT INTO way_tags (way_id, k, v, version) VALUES ' +
                            `(${invertedWay_id}, '${invertedWayTag.k}', '${invertedWayTag.v.replaceAll("'", "''")}', 1);\n`;
                        break;
                }
            }

            if (lanesBackward && lanesForward) {
                // current
                sqlText += `\tDELETE FROM current_way_tags WHERE way_id = ${key} and k = 'lanes:backward';\n`;
                sqlText += `\tDELETE FROM current_way_tags WHERE way_id = ${key} and k = 'lanes:forward';\n`;
                sqlText += `\tUPDATE current_way_tags SET v = ${lanesForward} WHERE way_id = ${key} and k = 'lanes';\n`;
                sqlText += `\tINSERT INTO current_way_tags (way_id, k, v) VALUES (${invertedWay_id}, 'lanes', '${lanesBackward}');\n`;
                // historic
                sqlText += `\tINSERT INTO way_tags (way_id, k, v, version) VALUES (${key}, 'lanes', '${lanesBackward}', ${currentWayVersion + 1});\n`;
                sqlText += `\tINSERT INTO way_tags (way_id, k, v, version) VALUES (${invertedWay_id}, 'lanes', '${lanesBackward}', 1);\n`;
            } else if (lanes) {
                // if (lanes % 2 != 0 && lanes != 1 && parseInt(invertedWay[0].latitude) > 430000000 && parseInt(invertedWay[0].latitude) < 440000000 &&
                //     parseInt(invertedWay[0].longitude) > 110000000 && parseInt(invertedWay[0].longitude) < 120000000)
                //     console.log(colors.red('Attention: lanes are odd in ' + key));
                lanes = lanes == 1 ? 1 : lanes / 2;
                sqlText += `\tUPDATE current_way_tags SET v = ${lanes} WHERE way_id = ${key} and k = 'lanes';\n`;
                sqlText += `\tINSERT INTO current_way_tags (way_id, k, v) VALUES (${invertedWay_id}, 'lanes', '${lanes}');\n`;
                // historic
                sqlText += `\tINSERT INTO way_tags (way_id, k, v, version) VALUES (${key}, 'lanes', '${lanes}', ${currentWayVersion + 1});\n`;
                sqlText += `\tINSERT INTO way_tags (way_id, k, v, version) VALUES (${invertedWay_id}, 'lanes', '${lanes}', 1);\n`;
            }
            await updateDb('lanes splitted');

            // relations to copy
            /* TEST: DO NOT COPY relations containing the inverted way
            if (wayRelations.hasOwnProperty(key))
                for (let relation of wayRelations[key]) {
                    const rkey = relation.relation_id;
                    sqlText += `\tINSERT INTO current_relations (changeset_id, timestamp, visible, version) VALUES ` +
                        `(${changeset_id}, '${nowDate}', true, 1) RETURNING id${!fdb ? " INTO ID_RELATION" : ""};\n`;
                    let relation_id;
                    if (fdb) {
                        const newRelation = await finalClient.getQuery(sqlText, true);
                        relation_id = newRelation[0].id;
                        console.log(`relation ${relation_id} created`);
                        sqlText = "";
                    }
                    relation_id = fdb ? relation_id : "ID_RELATION";
                    sqlText += `\tINSERT INTO relations (relation_id, changeset_id, timestamp, visible, version) VALUES ` +
                        `(${relation_id}, ${changeset_id}, '${nowDate}', true, 1);\n`;
                    await updateDb(`created historic versioning for relation ${relation_id} originated by ${rkey}`)

                    let i = 0;
                    for (let member of relationsMembers[rkey]) {
                        let member_id = member.member_id === key ? invertedWay_id : member.member_id;
                        sqlText += `\tINSERT INTO current_relation_members (relation_id, member_type, member_id, member_role, sequence_id) VALUES ` +
                            `(${relation_id}, '${member.member_type}', ${member_id}, '${member.member_role.replaceAll("'", "''")}', ${member.sequence_id});\n`;
                        sqlText += `\tINSERT INTO relation_members (relation_id, member_type, member_id, member_role, sequence_id, version) VALUES ` +
                            `(${relation_id}, '${member.member_type}', ${member_id}, '${member.member_role.replaceAll("'", "''")}', ${member.sequence_id}, 1);\n`;
                        i++;
                        if (i > 20000) {
                            if (fdb) {
                                updateDb('inserted chunk relations members');
                            } else {
                                fs.appendFileSync(path.join(outDir, "output.sql"), sqlText);
                                sqlText = "";
                            }
                            i = 0;
                        }
                    }
                    if (fdb)
                        await updateDb('inserted chunk relations members');

                    for (let tag of relationsTags[rkey]) {
                        sqlText += `\tINSERT INTO current_relation_tags (relation_id, k, v) VALUES ` +
                            `(${relation_id}, '${tag.k}', '${tag.v.replaceAll("'", "''")}');\n`;
                        sqlText += `\tINSERT INTO relation_tags (relation_id, k, v, version) VALUES ` +
                            `(${relation_id}, '${tag.k}', '${tag.v.replaceAll("'", "''")}', 1);\n`;
                    }
                    if (fdb) {
                        await updateDb(`added relation tags for ${relation_id}`);
                    } else {
                        fs.appendFileSync(path.join(outDir, "output.sql"), sqlText);
                        sqlText = "";
                    }
                }
            */
            if (!fdb) {
                fs.appendFileSync(path.join(outDir, "output.sql"), sqlText);
                sqlText = "";
            }

            if (wayRestrictrions.hasOwnProperty(key))
                for (let restriction of wayRestrictrions[key]) {
                    const rkey = restriction.relation_id;
                    let versionRestriction = await dbClient.getQuery(`select version from current_relations where id = ${rkey}`);
                    versionRestriction = parseInt(versionRestriction[0].version);
                    let newVersionRestriction = await finalClient.getQuery(`select version from current_relations where id = ${rkey}`);
                    newVersionRestriction = parseInt(newVersionRestriction[0].version);
                    if (versionRestriction + 1 == newVersionRestriction)
                        continue;

                    sqlText += `\tUPDATE current_relations SET (changeset_id, timestamp, visible, version) = ` +
                        `(${changeset_id}, '${nowDate}', true, ${versionRestriction + 1}) WHERE id = ${rkey};\n`;
                    sqlText += `\tINSERT INTO relations (relation_id, changeset_id, timestamp, visible, version) VALUES ` +
                        `(${rkey}, ${changeset_id}, '${nowDate}', true, ${versionRestriction + 1});\n`;

                    for (let member of relationsMembers[rkey]) {
                        let member_id = member.member_id === key ? invertedWay_id : member.member_id;
                        sqlText += `\tUPDATE current_relation_members SET member_id = ${member_id} WHERE relation_id = '${rkey}' AND sequence_id = ${restriction.sequence_id};\n`;
                        sqlText += `\tINSERT INTO relation_members (relation_id, member_type, member_id, member_role, sequence_id, version) VALUES ` +
                            `(${rkey}, '${member.member_type}', ${member_id}, '${member.member_role}', ${member.sequence_id}, ${versionRestriction + 1});\n`;
                    }

                    for (let tag of relationsTags[rkey]) {
                        sqlText += `\tINSERT INTO relation_tags (relation_id, k, v, version) VALUES ` +
                            `(${rkey}, '${tag.k}', '${tag.v.replaceAll("'", "''")}', ${versionRestriction + 1});\n`;
                    }
                }
            if (fdb) {
                await updateDb(`added restrictions for ${invertedWay_id}`);
            } else {
                fs.appendFileSync(path.join(outDir, "output.sql"), sqlText);
                sqlText = "";
                bar.increment();
            }
        }
        sqlText = "\tUPDATE public.current_ways SET version=(SELECT MAX(version) FROM public.ways WHERE way_id=id);\n";
        if (fdb) {
            await updateDb(`update ways to last version`);
        } else {
            fs.appendFileSync(path.join(outDir, "output.sql"), sqlText);
            sqlText = "";
            bar.increment();
        }
    dbClient.close();
        finalClient.close();
        if (!fdb) {
            bar.stop();
            sqlText += 'END $$;';
            fs.appendFileSync(path.join(outDir, "output.sql"), sqlText);
        }
        let phaseEnd = new Date();
        console.log(colors.green("Phase 9 Ended "+phaseEnd+" time:"+(phaseEnd-phaseStart)+"ms time from start:"+(phaseEnd-start)+"ms"));
    }
    console.log('Process ended.');
    process.exit();
}

const args = require('yargs')
    .usage('Usage: $0 [OPTIONS]')
    .option('phase', {
        alias: 'p',
        describe: 'phase to start',
        default: 1,
        type: 'number',
    })
    .option('threads', {
        alias: 't',
        describe: 'number of threads',
        type: 'number',
        default: 8
    })
    .help()
    .alias('help', 'h')
    .argv;

StartProcessData(args);
