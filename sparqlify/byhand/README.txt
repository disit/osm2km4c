README
------

This folder contains change files that have been applied to our own RDB representation of the Open Street Map(s) over the time. The Km4City KB /could/ reflect this changes if triples generated after their application have already been loaded to Virtuoso. Changeset IDs, and element IDs, are critical, since conflicts on those could lead to an overall data corruption. So be carefull in setting them carefully, if one day you will produce your own OSC file. If one day you will make a clean installation of the PostgreSQL+PostGIS+(OSM data) in a new environment, do not forget to apply these changes after that you will have completed the loading of native OSM data on the RDB. Use osmosis for the purpose. Apply /all/ the changes in sequence. 

MS, 2018-10-19 