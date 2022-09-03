# -----------------------------------------------------------------------------
# update_boundaries.sh
# -----------------------------------------------------------------------------
#
# The local user account we are using
#
local_filesystem_user=ajtown
local_renderd_user=_renderd
local_database=gis6
#
# First things first - define some shared functions
#
final_tidy_up()
{
    rm last_modified1.$$
    rm update_boundaries.running
#   rm ${file_prefix1}_${file_extension1}_admin.osm.pbf ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
}

m_error_01()
{
    final_tidy_up
    date | mail -s "Database reload FAILED on `hostname`, previous database ${local_database} intact" ${local_filesystem_user}
    exit 1
}

m_error_02()
{
    final_tidy_up
    date | mail -s "Database reload FAILED on `hostname`, previous database ${local_database} lost" ${local_filesystem_user}
    exit 1
}

#
# Next, is another copy of the script already running?
#
cd /home/${local_filesystem_user}/data
if test -e update_boundaries.running
then
    echo update_boundaries.running exists so exiting
    exit
else
    touch update_boundaries.running
fi
# -----------------------------------------------------------------------------
# This script does not do languages-for-a-specific-region processing.
# (update_render.sh, on which it is based, does)
# There is therefor e.g. no "file_prefix2" below.
# ----------------------------------------------------------------------------
# What's the file that we are interested in?
#
#file_prefix1=europe
#file_page1=http://download.geofabrik.de/${file_prefix1}.html
#file_url1=http://download.geofabrik.de/${file_prefix1}-latest.osm.pbf
#
#file_prefix1=british-isles
file_prefix1=great-britain
#file_prefix1=ireland-and-northern-ireland
file_page1=http://download.geofabrik.de/europe/${file_prefix1}.html
file_url1=http://download.geofabrik.de/europe/${file_prefix1}-latest.osm.pbf
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
#file_prefix1=durham
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
# We create 1 new XML file
# The boundaries layer reads from gis6, and uses the openstreetmap-carto-AJT style
#
cd /home/${local_filesystem_user}/src/openstreetmap-carto-AJT
pwd
carto project6.mml > mapnik6.xml
#
# How much disk space are we currently using?
#
df
cd /home/${local_filesystem_user}/data
#
# When was the first target file last modified?
#
if [ "$1" = "current" ]
then
    echo "Using current data"
    ls -t | grep "${file_prefix1}_" | head -1 | sed "s/${file_prefix1}_//" | sed "s/.osm.pbf//" > last_modified1.$$
else
    wget $file_page1 -O file_page1.$$
    grep " and contains all OSM data up to " file_page1.$$ | sed "s/.*and contains all OSM data up to //" | sed "s/. File size.*//" > last_modified1.$$
    rm file_page1.$$
fi
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
# Optionally stop rendering to free up memory
# A restart on renderd is also an option to reduce memory use.
#
#/etc/init.d/renderd stop
#/etc/init.d/apache2 stop
#
# Filter some objects out with osmium, leaving only admin_level
#
osmium tags-filter ${file_prefix1}_${file_extension1}.osm.pbf nwr/admin_level    --overwrite  -o ${file_prefix1}_${file_extension1}_admin.osm.pbf
#
# Filter place and waterway etc. tags out with osmconvert/osmfilter/osmconvert
#
#osmconvert ${file_prefix1}_${file_extension1}_admin.osm.pbf -o=${file_prefix1}_${file_extension1}_admin.o5m
#osmfilter ${file_prefix1}_${file_extension1}_admin.o5m --drop-tags="barrier= building= highway= landuse= office= place= waterway=" -o=${file_prefix1}_${file_extension1}_admin_noplace.o5m
#osmconvert ${file_prefix1}_${file_extension1}_admin_noplace.o5m -o=${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
#
if /home/${local_filesystem_user}/src/osm-tags-transform/build/src/osm-tags-transform -c /home/${local_filesystem_user}/src/Boundary_Scripts/transform_droptags.lua ${file_prefix1}_${file_extension1}_admin.osm.pbf -O -o ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
then
    echo Drop tags transform OK
else
    echo Drop tags transform error
    m_error_01
fi
#
chmod 755 ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
#
# Run osm2pgsql, loading the "gis6" database.
#
if sudo -u ${local_renderd_user} osm2pgsql --create --slim -G --hstore -d ${local_database} -C 2500 --number-processes 2 -S /home/${local_filesystem_user}/src/openstreetmap-carto-AJT/openstreetmap-carto.style --multi-geometry --tag-transform-script /home/${local_filesystem_user}/src/openstreetmap-carto/openstreetmap-carto.lua ${file_prefix1}_${file_extension1}_admin_noplace.osm.pbf
then
    echo Database ${local_database} load OK
else
    echo Database ${local_database} load Error
    m_error_02
fi
#
date | mail -s "Boundary database ${local_database} reload complete on `hostname`" ${local_filesystem_user}
#
# Remove already generated tiles
#
rm -rf /var/cache/renderd/tiles/ajt6/??
rm -rf /var/cache/renderd/tiles/ajt6/?
#
# Restart renderd
#
/etc/init.d/renderd restart
/etc/init.d/apache2 restart
#
# And final tidying up
#
final_tidy_up
#
