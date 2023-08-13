#!/bin/sh
set -eu
R7RS=${R7RS:-chibi-scheme}
cd "$(dirname "$0")"
sensible -o schemeorg schemeorg.scm
cd schemeorg
echo "Entering directory '$PWD'"
mkdir -p roles/configure_nginx/files
$R7RS ../nginx.scm >roles/configure_nginx/files/nginx.conf
mkdir -p roles/make_production_api/files
mkdir -p roles/make_staging_api/files
mkdir -p roles/set_server_basics/files
{ echo && cat ../motd.text && echo; } >roles/set_server_basics/files/motd
$R7RS ../services.scm
ansible-playbook schemeorg.yaml "$@"
