cd /opt/scot/pubdev
printf "Running npm install -g gulp" 
npm install -g gulp
printf "Running npm install"
npm install
printf "Running npm install --only=dev"
npm install --only=dev
printf "Running gulp"
gulp docker-build-prod

/usr/local/bin/hypnotoad -f /opt/scot/script/Scot
