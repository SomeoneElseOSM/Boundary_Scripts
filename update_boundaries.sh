# -----------------------------------------------------------------------------
# update_boundaries.sh
# -----------------------------------------------------------------------------
#
# The local user account we are using
#
local_user=renderaccount
#
# First things first - is another copy of the script already running?
#
cd /home/${local_user}/data
if test -e update_boundaries.running
then
    echo update_boundaries.running exists so exiting
    exit
else
    touch update_boundaries.running
fi
# -----------------------------------------------------------------------------
# This script does not languages-for-a-specific-region processing.
# ----------------------------------------------------------------------------
# What's the file that we are interested in?
#
file_prefix1=europe
file_page1=http://download.geofabrik.de/${file_prefix1}.html
file_url1=http://download.geofabrik.de/${file_prefix1}-latest.osm.pbf
#
#file_prefix1=british-isles
#file_prefix1=great-britain
#file_page1=http://download.geofabrik.de/europe/${file_prefix1}.html
#file_url1=http://download.geofabrik.de/europe/${file_prefix1}-latest.osm.pbf
#
#file_prefix1=england
#file_prefix1=scotland
#file_prefix1=wales
#file_page1=http://download.geofabrik.de/europe/great-britain/${file_prefix1}.html
#file_url1=http://download.geofabrik.de/europe/great-britain/${file_prefix1}-latest.osm.pbf
#
#file_prefix1=bedfordshire
#file_prefix1=berkshire
#file_prefix1=bristol
#file_prefix1=buckinghamshire
#file_prefix1=cambridgeshire
#file_prefix1=cheshire
#file_prefix1=cornwall
#file_prefix1=cumbria
#file_prefix1=derbyshire
#file_prefix1=devon
#file_prefix1=dorset
#file_prefix1=east-sussex
#file_prefix1=east-yorkshire-with-hull
#file_prefix1=essex
#file_prefix1=gloucestershire
#file_prefix1=greater-london
#file_prefix1=greater-manchester
#file_prefix1=hampshire
#file_prefix1=herefordshire
#file_prefix1=hertfordshire
#file_prefix1=isle-of-wight
#file_prefix1=kent
#file_prefix1=lancashire
#file_prefix1=leicestershire
#file_prefix1=lincolnshire
#file_prefix1=merseyside
#file_prefix1=norfolk
#file_prefix1=northamptonshire
#file_prefix1=north-yorkshire
#file_prefix1=northamptonshire
#file_prefix1=northumberland
#file_prefix1=nottinghamshire
#file_prefix1=oxfordshire
#file_prefix1=rutland
#file_prefix1=shropshire
#file_prefix1=somerset
#file_prefix1=south-yorkshire
#file_prefix1=staffordshire
#file_prefix1=suffolk
#file_prefix1=surrey
#file_prefix1=tyne-and-wear
#file_prefix1=warwickshire
#file_prefix1=west-midlands
#file_prefix1=west-sussex
#file_prefix1=west-yorkshire
#file_prefix1=wiltshire
#file_prefix1=worcestershire
#file_page1=http://download.geofabrik.de/europe/great-britain/england/${file_prefix1}.html
#file_url1=http://download.geofabrik.de/europe/great-britain/england/${file_prefix1}-latest.osm.pbf
#
#file_prefix1=new-york
#file_page1=http://download.geofabrik.de/north-america/us/${file_prefix1}.html
#file_url1=http://download.geofabrik.de/north-america/us/${file_prefix1}-latest.osm.pbf
#
# Remove the openstreetmap-tiles-update-expire entry from the crontab.
# Note that this matches a comment on the crontab line.
#
crontab -u $local_user -l > local_user_crontab_safe.$$
grep -v "\#CONTROLLED BY update_render.sh" local_user_crontab_safe.$$ > local_user_crontab_new.$$
crontab -u $local_user local_user_crontab_new.$$
rm local_user_crontab_new.$$
#
# How much disk space are we currently using?
#
df
#
# When was the first target file last modified?
#
cd /home/${local_user}/data
wget $file_page1 -O file_page1.$$
grep " and contains all OSM data up to " file_page1.$$ | sed "s/.*and contains all OSM data up to //" | sed "s/. File size.*//" > last_modified1.$$
#
file_extension1=`cat last_modified1.$$`
#
if test -e ${file_prefix1}_${file_extension1}.osm.pbf
then
    echo "File1 already downloaded"
else
    wget $file_url1 -O ${file_prefix1}_${file_extension1}.osm.pbf
fi
#
# Stop rendering to free up memory
#
/etc/init.d/renderd stop
/etc/init.d/apache2 stop
#
# Filter some objects out with osmium, leaving only admin_level
#
osmium tags-filter ${file_prefix1}_${file_extension1}.osm.pbf nwr/admin_level    --overwrite  -o ${file_prefix1}_${file_extension1}_admin.osm.pbf
#
# Filter place and waterway tags out with osmconvert/osmfilter/osmconvert
#
osmconvert ${file_prefix1}_${file_extension1}_admin.osm.pbf -o=${file_prefix1}_${file_extension1}_admin.o5m
osmfilter ${file_prefix1}_${file_extension1}_admin.o5m --drop-tags="barrier= building= highway= landuse= office= place= waterway=" -o=${file_prefix1}_${file_extension1}_admin_noplace.o5m
osmconvert ${file_prefix1}_${file_extension1}_admin_noplace.o5m -o=${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
#
chmod 755 ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
#
# Run osm2pgsql, loading the "gis2" database.
#
sudo -u ${local_user} osm2pgsql --create --slim -G --hstore -d gis2 -C 11000 --number-processes 6 -S /home/${local_user}/src/openstreetmap-carto/openstreetmap-carto.style --multi-geometry --tag-transform-script /home/${local_user}/src/openstreetmap-carto/openstreetmap-carto.lua ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
#
# Remove already generated tiles
#
rm -rf /var/lib/mod_tile/ajt2/??
rm -rf /var/lib/mod_tile/ajt2/?
#
# Tidy temporary files
#
rm ${file_prefix1}_${file_extension1}_admin.osm.pbf ${file_prefix1}_${file_extension1}_admin.o5m ${file_prefix1}_${file_extension1}_admin_noplace.o5m ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
#
# Restart renderd
#
/etc/init.d/renderd restart
/etc/init.d/apache2 restart
#
# Reinstate the crontab
#
crontab -u $local_user local_user_crontab_safe.$$
# 
# And final tidying up
#
#date | mail -s "Boundary database reload complete on `hostname`" ${local_user}
rm file_page1.$$ last_modified1.$$ 
rm update_boundaries.running
#
