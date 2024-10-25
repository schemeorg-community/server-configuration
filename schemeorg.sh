#!/bin/sh
set -eu
R7RS=${R7RS:-chibi-scheme}
cd "$(dirname "$0")"
rm -rf schemeorg/
mkdir -p schemeorg
mkdir -p schemeorg/roles/make_production_gitea/files
mkdir -p schemeorg/roles/motd/files
mkdir -p schemeorg/roles/nginx/files
cp -p gitea/prod-gitea.service schemeorg/roles/make_production_gitea/files/
{ echo && cat motd.text && echo; } >schemeorg/roles/motd/files/motd
(cd schemeorg/roles/nginx/files && $R7RS ../../../../nginx.scm)
$R7RS schemeorg.scm >schemeorg/schemeorg.pose
cd schemeorg
echo "Entering directory '$PWD'"
set -x
sensible schemeorg.pose
ansible-playbook schemeorg.yaml "$@"
