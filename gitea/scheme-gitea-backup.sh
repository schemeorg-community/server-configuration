#!/bin/sh
set -eu
uid="$(id -u prod-gitea)"
timestamp="$(date -u '+%Y%m%dT%H%MZ')"
dir="backup/$timestamp"
newdir="$dir.new"
sql="$newdir/postgres.sql"
cd ~prod-gitea
echo "Entering directory '$PWD'"
set -x
test -r .pgpass
docker-compose down
test ! -e "$dir"
mkdir "$newdir"
pg_dump --dbname gitea --username gitea --no-password --file "$sql"
docker-compose run --user "$uid" --workdir /"$newdir" \
    gitea \
    gitea dump -c /data/gitea/conf/app.ini
mv "$newdir" "$dir"
chmod -R 440 "$newdir"
