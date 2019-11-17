#!/bin/sh

set -e

cd /opt/cwtools/
mv $GITHUB_WORKSPACE/hoi4.cwb.7z .
p7zip -d hoi4.cwb.7z

ruby /action/lib/cwtools.rb $1
