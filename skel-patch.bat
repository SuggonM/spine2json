@echo off

set name=%~n1
set expCfg1=./jsons/spine-to-json.json
set expCfg2=./jsons/spine-to-skel.json
"C:/Program Files/Spine/Spine.com" -i ./assets/%name%.skel -o ./assets/ -e "%expCfg1%"
node app-patch %name%
"C:/Program Files/Spine/Spine.com" -i ./assets/%name%_j2p.json -o ./assets/ -e "%expCfg2%"
