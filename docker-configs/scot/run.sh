cd /opt/scot/pubdev
printf "Running npm install -g gulp" 
npm install -g gulp
printf "Running npm install"
npm install
printf "Running npm install --only=dev"
npm install --only=dev
printf "Running node-sass rebuild command: npm rebuild node-sass --force"
npm rebuild node-sass --force
printf "Running gulp"
gulp build-prod

/usr/local/bin/hypnotoad -f /opt/scot/script/Scot
