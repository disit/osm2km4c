#!/bin/sh

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Started"

sleeptime=60
diskspacemargin=3
if ! [ -f "territories.pending" ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] territories.pending is found to be missing. I am going to initialize it to territories.list"
cp territories.list territories.pending
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
fi
if ! [ -d "tmp" ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Temporary folder is found to be missing. I am going to create it."
mkdir tmp
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
fi
mybasedir=$PWD

while [ 1 -eq 1 ] 
do

full_list_size=`wc -c < $mybasedir/territories.list`
pending_list_size=`wc -c < $mybasedir/territories.pending`
skip_rdb_update=0
if [ $pending_list_size -lt $full_list_size ]
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] I now go to sleep for $sleeptime seconds. After that, I will perform pending triplifications, before updating the RDB. Stop me now if you really have to. My PID is $$"
sleep $sleeptime
skip_rdb_update=1
else 
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] I now go to sleep for $sleeptime seconds. After that, I will update the RDB. Stop me now if you really have to. My PID is $$"
sleep $sleeptime
skip_rdb_update=0
fi

if [ $skip_rdb_update -eq 0 ] 
then

triplifynow=0
while [ $triplifynow -eq 0 ] 
do
oscd=`cat oscd.txt`
oscn=`cat oscn.txt`
noscd=$oscd
noscn=`expr "$oscn" + "1"`
if [ $noscn -eq 1000 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] No more OSC files found in geofabrick folder # $noscd"
noscd=`expr "$oscd" + "1"`
echo "[$dt] Switching to folder # $noscd"
noscn=0
fi
noscd=$(printf "%03d" $noscd)
noscn=$(printf "%03d" $noscn)
oscp="https://download.geofabrik.de/europe/italy-updates/000/"
slash="/"
oscs=".osc.gz"
osce=".osc"
oscu=$oscp$noscd$slash$noscn$oscs
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] I am going to attempt the retrieval of an OSC (OSM update) file at $oscu"
echo "[$dt] Do NOT stop me now!"
wget "$oscu"
if [ $? -eq 0 ]
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] OSC file retrieved from $oscu"
echo "[$dt] I now go to sleep for $sleeptime seconds. After that, I will apply the change to the RDB. Kill me now if you really have to. My PID is $$."
sleep $sleeptime
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am now going to apply the change to the RDB. Do NOT stop me now!"
gzip -d "$noscn$oscs"
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
/home/debian/osmosis/bin/osmosis --read-xml-change file="/home/debian/geofabrick/osc/italy/$noscn$osce" --write-pgsimp-change database="pgsimple_ita" user="pgsimple_ita_writer" password="u76bu89ntu"
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
echo "$noscn" > oscn.txt
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
rm "$noscn$osce"
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Done. I am now going to sleep for $sleeptime seconds. After that, I will look for further updates to be applied. Kill me now if you really have to. My PID is $$."
sleep $sleeptime
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am going to look for new updates to be applied to the RDB. You will have the chance to stop me again before they are actually applied. Do NOT stop me now!"
triplifynow=0
else
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] OSC file not found. RDB is up-to-date. I am now going to sleep for $sleeptime seconds. After that, I will update country boundaries. Kill me now if you really have to. My PID is $$."
sleep $sleeptime
triplifynow=1
fi
done

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am going to update country boundaries on the RDB. Do NOT stop me now!"
psql -d pgsimple_ita -f reshape-boundaries.sql
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
psql -d pgsimple_ita -c "grant select on all tables in schema public to pgsimple_ita_reader;"
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Done. I am now going to sleep for $sleeptime seconds. After that, I will determine available disk space on 192.168.0.20. Kill me now if you really have to. My PID is $$."
sleep $sleeptime

if [ -f "stop.asap" ]
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] File stop.asap found. I am going to stop myself."
rm stop.asap
exit 0
fi

fi

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am now going to determine available disk space on 192.168.0.20. Do NOT kill me now!"

while IFS='' read -r line || [ -n "$line" ]
do
filesystem=$(echo $line | cut -d ' ' -f 1)
blocks=$(echo $line | cut -d ' ' -f 2)
used=$(echo $line | cut -d ' ' -f 3)
avail=$(echo $line | cut -d ' ' -f 4)
usedperc=$(echo $line | cut -d ' ' -f 5)
mountedon=$(echo $line | cut -d ' ' -f 6)
if [ "$mountedon" = "/media/Triples" ]
then
diskspace=$avail
fi
if [ "$mountedon" = "/" ] && [ $avail -le 10000000000 ]
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Something very strange seems to be going on. I see not so much free disk space in my local disk. I am going to kill myself."
exit 1
fi
done << EOF
$(df -B1)
EOF

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Done. Available disk space on 192.168.0.20 is $diskspace bytes. I am now going to sleep for $sleeptime seconds. After that, I will start triplifications. Kill me now if you really have to. My PID is $$."
sleep $sleeptime

while IFS='' read -r line || [ -n "$line" ]
do
osmid=$(echo $line | cut -d ' ' -f 1)
territoryname=$(echo $line | cut -d ' ' -f 2)
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am now going to prepare triplification for $line. Do NOT stop me now!"
psql -d pgsimple_ita -v boundary=$osmid -f script.sql
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
psql -d pgsimple_ita -c "grant select on all tables in schema public to pgsimple_ita_reader;"
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Done. I am now going to sleep for $sleeptime seconds. After that, I will triplify $line. Kill me now if you really have to. My PID is $$."
sleep $sleeptime
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am now going to triplify $line. Do NOT stop me now!"
cd ~/Sparqlify
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
./sparqlify.sh -m $mybasedir/script.sml -h 192.168.0.110 -d pgsimple_ita -U pgsimple_ita_reader -W pgsimple_ita_reader -o ntriples --dump > $mybasedir/tmp/dirty.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
cd $mybasedir/tmp
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
tail -n +3 dirty.n3 > quite_clean.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
sort quite_clean.n3 | uniq > $territoryname.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
rm dirty.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
rm quite_clean.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Done. I am now going to sleep for $sleeptime seconds. After that, I will attempt to move triples to 192.168.0.20. Kill me now if you really have to. My PID is $$."
sleep $sleeptime
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. I am now going to attempt to move the new triples for $line to 192.168.0.20. Do NOT stop me now!"
newfilesize=$(wc -c < $territoryname.n3)
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
echo "[$dt] New triples file size is $newfilesize bytes. Do NOT stop me now!"
oldfilesize=$(wc -c < /media/Triples/OSM/$territoryname/$territoryname.n3)
if [ -z "$oldfilesize" ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] No old triples file $territoryname.n3 could be found in 192.168.0.20. Old file size is forced to zero bytes. Do NOT stop me now!"
oldfilesize=0
else
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Old triples file size in 192.168.0.20 was $oldfilesize bytes. Do NOT stop me now!"
fi
increaseofoccupancy=$(($newfilesize - $oldfilesize))
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Disk space occupancy delta is $increaseofoccupancy bytes. Do NOT stop me now!"
tripleincreaseofoccupancy=$(($increaseofoccupancy * $diskspacemargin))
if [ $tripleincreaseofoccupancy -le $diskspace ]
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Since the delta is negative, or the free disk space is more than $diskspacemargin times the positive delta of occupancy, I am going to move the file. Do NOT stop me now!" 
if [ $oldfilesize -ne 0 ] 
then
rm /media/Triples/OSM/$territoryname/$territoryname.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
fi
if ! [ -d "/media/Triples/OSM/$territoryname" ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Destination folder is found to be missing. I am going to create it."
mkdir /media/Triples/OSM/$territoryname
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
fi
mv $territoryname.n3 /media/Triples/OSM/$territoryname/$territoryname.n3
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
else
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Since the free disk space is less than $diskspacemargin times the positive delta of occupancy, I do not move the file, and keep it in my tmp folder." 
fi

cd $mybasedir
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi
echo "$(tail -n +2 territories.pending)" > territories.pending
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] The triplification of $line is now complete. I am now going to sleep for $sleeptime seconds. After that, I will step to next territory if any. Kill me now if you really have to. My PID is $$." 
sleep $sleeptime

if [ -f "stop.asap" ]
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] File stop.asap found. I am going to stop myself."
rm stop.asap
exit 0
fi
done << EOF
$(cat territories.pending)
EOF

dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] Too late. Triplification was found to be completed for all territories. I am now going to update the RDB through the geofabrick OSC files. Do NOT stop me now!"
cp territories.list territories.pending
if ! [ $? -eq 0 ] 
then
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "[$dt] An unexpected error occurred. I am going to kill myself."
exit 1
fi

done
