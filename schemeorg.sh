#!/bin/sh
set -eu
R7RS=${R7RS:-chibi-scheme}
cd "$(dirname "$0")"
test -e lander || git clone https://github.com/lispunion/lander.git
mkdir -p schemeorg
(cd lander && git describe --dirty --always) >schemeorg/lander-version.text
cd schemeorg
echo "Entering directory '$PWD'"
$R7RS ../lander/lander.scm <../schemeorg.scm
mkdir -p roles/configure_nginx/files
$R7RS ../nginx.scm >roles/configure_nginx/files/nginx.conf
mkdir -p roles/make_production_api/files
mkdir -p roles/make_staging_api/files
mkdir -p roles/set_server_basics/files
{ echo && cat ../motd.text && echo; } >roles/set_server_basics/files/motd
$R7RS ../services.scm
ansible-playbook schemeorg.yml "$@"
