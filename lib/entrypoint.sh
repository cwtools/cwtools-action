#!/bin/sh

set -e

export CW_CHECKNAME="CWTools"

if [ -z "$GITHUB_SHA" ]; then
      export CW_CI_ENV="github"
      export CW_EVENT=$GITHUB_EVENT_PATH
      export CW_TOKEN=$GITHUB_TOKEN
      export CW_WORKSPACE=$GITHUB_WORKSPACE
      export CW_SHA=$GITHUB_SHA
else
      export CW_CI_ENV="gitlab"
      export CW_WORKSPACE=$CI_PROJECT_DIR
      export CW_SHA=$CI_PROJECT_DIR
fi

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
if [ $CW_CI_ENV = "github" ]; then
  export PATH="$PATH:$HOME/.dotnet/tools"
elif [ $CW_CI_ENV = "gitlab" ]; then
  export PATH="$PATH:/root/.dotnet/tools"
  mkdir /action
  mkdir /action/lib
  wget https://raw.githubusercontent.com/tboby/cwtools-action/reviewdog-gitlab/lib/entrypoint.sh -O /action/lib/entrypoint.sh
  wget https://raw.githubusercontent.com/tboby/cwtools-action/reviewdog-gitlab/lib/cwtools.rb -O /action/lib/cwtools.rb
  apt-get update && apt-get -y install ruby bash git wget p7zip
  wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b /usr/local/bin/
fi

cd /
mkdir -p /src
if [ "$INPUT_RULES" = "" ]; then
  git clone https://github.com/cwtools/cwtools-$INPUT_GAME-config.git /src/cwtools-$INPUT_GAME-config
else
  git clone $INPUT_RULES /src/cwtools-$INPUT_GAME-config
fi

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
  echo "If git fails here, it is most likely because the selected game ($INPUT_GAME) is not yet supported in the 'cwtools/cwtools-cache-files'. In that case, use CWTools.CLI to generate a full cache of selected game and set it with the cache parameter. Consult README for more information."
  git clone --depth=1  --single-branch --branch $INPUT_GAME https://github.com/cwtools/cwtools-cache-files.git cwtools-cache-files
  mv -v cwtools-cache-files/$CWB_GAME.cwv.bz2 .
else
  echo "Using full game cache from '$CW_WORKSPACE/$INPUT_CACHE'..."
  mv -v $CW_WORKSPACE/$INPUT_CACHE .

  if [ ! -f "$CWB_GAME.cwb.bz2" ]; then
      echo "$CWB_GAME.cwb.bz2 does not exist!"
      exit 1
  fi
fi
ruby /action/lib/cwtools.rb
if [ $CW_CI_ENV = "gitlab" ]; then
  cp errors.txt $CW_WORKSPACE/errors.txt
  cd $CW_WORKSPACE
  cat errors.txt | reviewdog -efm="%f:%l:%c:%m" -name="$CW_CHECKNAME" -reporter=gitlab-mr-discussion
fi