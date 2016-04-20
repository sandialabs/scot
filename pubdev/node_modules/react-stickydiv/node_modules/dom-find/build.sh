#!/bin/bash
./node_modules/.bin/babel findPosRelativeToViewport.es6 > findPosRelativeToViewport.js
./node_modules/.bin/babel findPos.es6 > findPos.js
./node_modules/.bin/babel getPageScroll.es6 > getPageScroll.js
./node_modules/.bin/babel index.es6 > index.js

