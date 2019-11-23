#!/bin/sh

set -e

case $INPUT_GAME in
  "hoi4") echo "Game selected as $INPUT_GAME" ;;
  "ck2") echo "Game selected as $INPUT_GAME" ;;
  "eu4") echo "Game selected as $INPUT_GAME" ;;
  "vic2") echo "Game selected as $INPUT_GAME" ;;
  "ir") echo "Game selected as $INPUT_GAME" ;;
  "stellaris") echo "Game selected as $INPUT_GAME" ;;
  *) echo "Wrong game, $INPUT_GAME is not valid" 1>&2 ; exit 1 # terminate and indicate error
esac

dotnet tool install --global -v m CWTools.CLI
export PATH="$PATH:/github/home/.dotnet/tools"

cd /
mkdir -p /src
git clone ${$INPUT_RULES} /src/cwtools-$INPUT_GAME-config

cd /src/cwtools-$INPUT_GAME-config
git fetch
git checkout $INPUT_RULESREF

CWB_GAME=$INPUT_GAME 
if [ "$INPUT_GAME" = "stellaris" ]; then
  CWB_GAME="stl"
fi

cd /
if [ "$INPUT_CACHE" = "" ]; then
  echo "Using metadata cache from 'cwtools/cwtools-cache-files'..."
  git clone --depth=1  --single-branch --branch $INPUT_GAME https://github.com/cwtools/cwtools-cache-files.git cwtools-cache-files
  mv -v cwtools-cache-files/$CWB_GAME.cwv.bz2 .
else
  echo "Using full game cache from '$GITHUB_WORKSPACE/$INPUT_CACHE'..."
  mv -v $GITHUB_WORKSPACE/$INPUT_CACHE .

  if [ ! -f "$CWB_GAME.cwb.bz2" ]; then
      echo "$CWB_GAME.cwb.bz2 does not exist!"
      exit 1
  fi
fi
ruby /action/lib/cwtools.rb