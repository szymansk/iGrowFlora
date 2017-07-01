#!/bin/sh

mqtt subscribe -h localhost -p 1883 -t 'controller/timer' --t 'controller/volume' -q 1 -t 'valve/opened' -t 'valve/closed' -l 'mqtt' -v