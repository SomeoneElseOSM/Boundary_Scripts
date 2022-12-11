# Boundary_Scripts
Load a database "gis6" with boundary data (not shown by default in the SomeoneElse-style style).

## Process
The "update_boundaries.sh" script is similar to "[update_render.sh](https://github.com/SomeoneElseOSM/SomeoneElse-style/blob/master/update_render.sh)", 
except that it uses "osmium tags-filter" and "osm-tags-transform" to trim only "admin_level" data 
from an input .pbf file.  It loads that into a database "gis6", 
which is made available as an overlay map layer.

