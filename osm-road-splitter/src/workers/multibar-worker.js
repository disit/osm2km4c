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
   
const cliProgress = require('cli-progress');
const colors = require('ansi-colors');

class MultiBarWorker {
    /** @type {cliProgress.MultiBar} */
    multibar;
    /** @type {[cliProgress.SingleBar]} */
    bars = [];

    constructor() {
        this.multibar = new cliProgress.MultiBar({
            format: '{thread} \t|' + colors.cyan('{bar}') + '| {percentage}% \t|| {value}/{total} Chunks',
            barCompleteChar: '\u2588',
            barIncompleteChar: '\u2591',
            hideCursor: true
        });
    }

    addBar(maxValue) {
        const bar = this.multibar.create(maxValue, 0);
        bar.update(0, {thread: `[Thread ${this.bars.length}]`});
        this.bars.push(bar);
    }

    increment(numBar) {
        this.bars[numBar].increment();
    }

    stop() {
        this.multibar.stop();
    }
}

module.exports = {MultiBarWorker};