CWTOOLS_ACTION_BRANCH="gitlab-integration"
REVIEWDOG_BRANCH="master"

mkdir /action
mkdir /action/lib
wget https://raw.githubusercontent.com/cwtools/cwtools-action/$CWTOOLS_ACTION_BRANCH/lib/entrypoint.sh -O /action/lib/entrypoint.sh
wget https://raw.githubusercontent.com/cwtools/cwtools-action/$CWTOOLS_ACTION_BRANCH/lib/cwtools.rb -O /action/lib/cwtools.rb
apt-get update && apt-get -y install ruby bash git wget p7zip
wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/$REVIEWDOG_BRANCH/install.sh| sh -s -- -b /usr/local/bin/
chmod +x /action/lib/entrypoint.sh
/action/lib/entrypoint.sh