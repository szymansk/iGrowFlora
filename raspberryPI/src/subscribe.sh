#!/bin/sh

mqtt subscribe -u pi -P vulam,. -h localhost -p 1883 -t 'controller/timer' --t 'controller/volume' -q 1 -t 'valve/opened' -t 'valve/closed' -l 'mqtt' -v