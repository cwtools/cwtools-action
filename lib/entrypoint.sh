#!/bin/sh

set -e

mkdir -p /src
git clone --depth=1 --single-branch --branch CLI https://github.com/tboby/cwtools.git /src/cwtools
cd /src/cwtools/CWToolsCLI
dotnet tool restore
dotnet paket restore
cd /
git clone --depth=1 https://github.com/tboby/cwtools-hoi4-config.git /src/cwtools-hoi4-config

cd /src/cwtools-hoi4-config
git fetch
git pull

cd /src/cwtools/CWToolsCLI
mv $GITHUB_WORKSPACE/hoi4.cwb.7z .
p7zip -d hoi4.cwb.7z

ruby /action/lib/cwtools.rb
