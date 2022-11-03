psql -d pgsimple_prt -f ./script.sql
psql -d pgsimple_prt -c "grant select on all tables in schema public to pgsimple_prt_reader;"
cd ~/Sparqlify
./sparqlify.sh -m ~/triples/portugal/346204/install/20190418/script.sml -h 192.168.0.110 -d pgsimple_prt -U pgsimple_prt_reader -W pgsimple_prt_reader -o ntriples --dump > ~/triples/portugal/346204/install/20190418/dirty.n3
cd ~/triples/portugal/346204/install/20190418
tail -n +3 dirty.n3 > quite_clean.n3
sort quite_clean.n3 | uniq > santiago_de_compostela.n3
rm dirty.n3
rm quite_clean.n3