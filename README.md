ghost-sitemap-generator
=======================

Sitemap Generator for Ghost blogging reading posts directly from database

INFO:
The script is actually working and it produces a working (and complete)
sitemap.xml file. 
I need to add checks and some improvements to consider this script dynamics and
usable everywhere.


Crontab Example
---------------

0 0 * * * /usr/bin/ruby generate_ghost_sitemap.rb blog.mornati.net daily 0.5 /path/to/ghost/sitemap.xml


