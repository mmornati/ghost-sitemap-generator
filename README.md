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
````bash
0 0 * * * /usr/bin/ruby /usr/bin/ruby /root/generate_ghost_sitemap.rb -s blog.mornati.net -p 0.5 -f daily -m localhost -u ghost -w mypasswd -b ghost -v -d /usr/share/nginx/ghost/sitemap.xml 
````

Allowed Parameters
------------------
````bash
[root@myserver ~]# ruby generate_ghost_sitemap.rb 
Missing options: site, priority, frequency, destfile, hostname, user, password, dbname
Usage: generate_ghost_sitemap.rb [options]
    -h, --help                       Display this screen
    -s, --site SITE                  Site base URL. EX: blog.mornati.net
    -f, --frequency FREQUENCY        Update Frenquency. One of: always,hourly,daily,weekly,monthly,yearly,never
    -p, --priority PRIORITY          Update priority. Values beetwen 0.0 et 1.0
    -d, --destfile DESTFILE          Sitemap destination file. Ex. /usr/share/server/sitemap.xml
    -t, --test                       Do not ping Google after sitemap generation
    -v, --verbose                    Verbose execution
    -m, --mysql HOSTNAME             MySQL hostname
    -u, --user USERNAME              MySQL Username
    -w, --password PASSWORD          MySQL Password
    -b, --dbname DBNAME              Database name
````
