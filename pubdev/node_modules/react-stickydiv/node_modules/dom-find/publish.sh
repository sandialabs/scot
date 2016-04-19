#!/bin/bash
sh build.sh
git commit -am "`npm view . version`" --allow-empty
git push --tags origin HEAD:master
npm version patch
npm publish
