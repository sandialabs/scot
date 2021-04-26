#!/bin/bash
sudo apt install $(cat ./auto_pkgs.lst)
sudo apt install $(cat ./manual_pkgs.lst)
