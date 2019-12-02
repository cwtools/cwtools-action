#!/bin/sh

set -e

export CW_CHECKNAME="CWTools"

if [ -n "$GITHUB_SHA" ]; then
  export CW_CI_ENV="github"
  export CW_EVENT=$GITHUB_EVENT_PATH
  export CW_TOKEN=$GITHUB_TOKEN
  export CW_WORKSPACE=$GITHUB_WORKSPACE
  export CW_SHA=$GITHUB_SHA
elif [ -n "$CI_PROJECT_DIR" ]; then
  export CW_CI_ENV="gitlab"
  export CW_TOKEN=$CI_JOB_TOKEN
  export CW_WORKSPACE=$CI_PROJECT_DIR
  if [ -z "$INPUT_MODPATH" ] || [ "$INPUT_MODPATH" = "" ]; then
      export INPUT_MODPATH=''
  fi
  if [ -z "$INPUT_CACHE" ] || [ "$INPUT_CACHE" = "" ]; then
      export INPUT_CACHE=''
  fi
  if [ -z "$INPUT_LOCLANGUAGES" ] || [ "$INPUT_LOCLANGUAGES" = "" ]; then
      export INPUT_LOCLANGUAGES='english'
  fi
  if [ -z "$INPUT_RULES" ] || [ "$INPUT_RULES" = "" ]; then
      export INPUT_RULES=''
  fi
  if [ -z "$INPUT_RULESREF" ] || [ "$INPUT_RULESREF" = "" ]; then
      export INPUT_RULESREF='master'
  fi
  if [ -z "$INPUT_CHANGEDFILESONLY" ] || [ "$INPUT_CHANGEDFILESONLY" = "" ]; then
      export INPUT_CHANGEDFILESONLY='1' # this is disabled for gitlab anyway
  fi
  if [ -z "$INPUT_SUPPRESSEDOFFENCECATEGORIES" ] || [ "$INPUT_SUPPRESSEDOFFENCECATEGORIES" = "" ]; then
      export INPUT_SUPPRESSEDOFFENCECATEGORIES='{"failure":[], "warning":[], "notice":[]}'
  fi
  if [ -z "$INPUT_CWTOOLSCLIVERSION" ] || [ "$INPUT_CWTOOLSCLIVERSION" = "" ]; then
      export INPUT_CWTOOLSCLIVERSION=''
  fi
fi

echo "CI Enviroment detected as $CW_CI_ENV..."

case $INPUT_GAME in
  "hoi4") echo "Game selected as $INPUT_GAME..." ;;
  "ck2") echo "Game selected as $INPUT_GAME..." ;;
  "eu4") echo "Game selected as $INPUT_GAME..." ;;
  "vic2") echo "Game selected as $INPUT_GAME..." ;;
  "ir") echo "Game selected as $INPUT_GAME..." ;;
  "stellaris") echo "Game selected as $INPUT_GAME..." ;;
  *) echo "Wrong game, $INPUT_GAME is not valid!" 1>&2 ; exit 1 # terminate and indicate error
esac

if [ -z "$INPUT_CWTOOLSCLIVERSION" ] || [ "$INPUT_CWTOOLSCLIVERSION" = "" ]; then
  dotnet tool install --global -v m CWTools.CLI
else
  dotnet tool install --global -v m CWTools.CLI --version $INPUT_CWTOOLSCLIVERSION
fi

if [ $CW_CI_ENV = "github" ]; then
  export PATH="$PATH:$HOME/.dotnet/tools"
elif [ $CW_CI_ENV = "gitlab" ]; then
  export PATH="$PATH:/root/.dotnet/tools"
fi

cd /
mkdir -p /src
if [ -z "$INPUT_RULES" ] || [ "$INPUT_RULES" = "" ]; then
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
if [ -z "$INPUT_CACHE" ] || [ "$INPUT_CACHE" = "" ]; then
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
  cd $CW_WORKSPACE
  if [ -f errors.txt ]; then
    echo "Running reviewdog on $PWD/errors.txt..."
    export GIT_TRACE=1
    if cat errors.txt | reviewdog -efm="%ZZZZZ%E%f:%l:%c:%t:%E%m" "%+C%m" -name="$CW_CHECKNAME" -reporter=gitlab-mr-discussion | grep -m 1 -q ":E:"; then
      echo "At least one error in annotated files! Exiting with a non-zero error code..."
      exit 1
    fi
  else
    echo "errors.txt doesn't exist in $CW_WORKSPACE!"
    exit 1
  fi
fi
