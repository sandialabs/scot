#!/bin/bash

URL="https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat"

cd /opt/scot/etc
wget $URL

