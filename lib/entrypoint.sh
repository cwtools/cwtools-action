#!/bin/sh

set -e

dotnet tool install --global CWTools.CLI
export PATH="$PATH:/github/home/.dotnet/tools"

cd /
mkdir -p /src
git clone --depth=1 https://github.com/tboby/cwtools-hoi4-config.git /src/cwtools-hoi4-config

cd /src/cwtools-hoi4-config
git fetch
git pull

cd /
mv $GITHUB_WORKSPACE/hoi4.cwb.7z .
p7zip -d hoi4.cwb.7z

cwtools --game hoi4 --directory "$GITHUB_WORKSPACE" --cachefile "/hoi4.cwb" --rulespath "/src/cwtools-hoi4-config/Config" validate --reporttype json --scope mods --outputfile output.json all

mkdir -p -v $GITHUB_WORKSPACE/artifact
cp -v output.json $GITHUB_WORKSPACE/artifact
ruby /action/lib/cwtools.rb