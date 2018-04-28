#!/bin/sh

 #nohup mqtt subscribe -h localhost -p 1883 -t '#'  -v -u pi -P vulam,. & tail -f nohup.out


 mqtt publish -h localhost -p 1883 -t controller/volume -m '{"valve":"0", "volume":"500", "intervall":"100"}' -v -u pi -P vulam,.
 mqtt publish -h localhost -p 1883 -t controller/timer -m '{"valve":"1", "volume":"200", "intervall":"500"}' -v -u pi -P vulam,.
 mqtt publish -h localhost -p 1883 -t controller/timer -m '{"valve":"2", "volume":"200", "intervall":"1000"}' -v -u pi -P vulam,.
 mqtt publish -h localhost -p 1883 -t controller/timer -m '{"valve":"3", "volume":"200", "intervall":"5000"}' -v -u pi -P vulam,.
 