if [ -z "$INPUT_CWTOOLSACTIONREF" ] || [ "$INPUT_CWTOOLSACTIONREF" = "" ]; then
    INPUT_CWTOOLSACTIONREF="gitlab-integration"
fi

if [ -z "$INPUT_REVIEWDOGREF" ] || [ "$INPUT_REVIEWDOGREF" = "" ]; then
    INPUT_REVIEWDOGREF="master"
fi

mkdir /action
mkdir /action/lib
wget https://raw.githubusercontent.com/cwtools/cwtools-action/$INPUT_CWTOOLSACTIONREF/lib/entrypoint.sh -O /action/lib/entrypoint.sh
wget https://raw.githubusercontent.com/cwtools/cwtools-action/$INPUT_CWTOOLSACTIONREF/lib/cwtools.rb -O /action/lib/cwtools.rb
apt-get update && apt-get -y install ruby bash git wget p7zip
wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/$INPUT_REVIEWDOGREF/install.sh| sh -s -- -b /usr/local/bin/
chmod +x /action/lib/entrypoint.sh
/action/lib/entrypoint.sh