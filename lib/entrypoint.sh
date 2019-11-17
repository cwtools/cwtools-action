#!/bin/sh

set -e

cd /src/cwtools-hoi4-config
git fetch
git pull

cd /opt/cwtools/
mv $GITHUB_WORKSPACE/hoi4.cwb.7z .
p7zip -d hoi4.cwb.7z

ruby /action/lib/cwtools.rb
