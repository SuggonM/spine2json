#!/bin/bash

# app paths
SPINE="/mnt/c/Program Files/Spine/Spine.com"
AR_DIR="/mnt/c/Program Files/AssetRipper"
AR_APP="$AR_DIR/AssetRipper"
AR_SRC="$AR_DIR/Ripped/ExportedProject/Assets"

# spine configs
SCFG_FRAMES="./configs/spine-to-pngs.json"
SCFG_J2SKEL="./configs/spine-to-skel.json"

# scripts
PATCH_ATLAS="./scripts/patch-atlas-json.mjs"
PARSE_SKEL="./scripts/parse-spine-skel.mjs"
MAKE_FFMPEG="./scripts/make-enc.mjs"

# working/playground directory
# defaults to assets folder
WORK_DIR="./assets"

# set default spine verison
# SV3 is 3.x, SV4 is 4.x
# leave SV4 empty if v4.x not installed
SV3=3.8.87
SV4=4.1.24

# # # # # # # # # # # # # # #

### config toggles
### 1 == true, otherwise false
# _TSPINE, _XDIR, _EXTBG deprecated for better organization

# unpremultiply alpha; remove black edges from texture
UPMA=1
# running on WSL; append '.exe' to executables
WSL=1

# # # # # # # # # # # # # # #

### array of additional files to fetch from ripped asset dump

# usable variables: [ $asset, $model, $file ]
call_index_add() {
	index_add=(
		"Texture2D/bg_$asset.png"
	)
}

### scale factor to resize animated video resolution

# 1 == no resize
ANIM_SCALE=0.5

# # # # # # # # # # # # # # #

# functions and aliases for WSL compatibility
[[ "$WSL" == 1 ]] && WSL=".exe"
AR_APP+="$WSL"

function notfound {
	echo "$1 not installed or PATH unconfigured!"
	exit 127
}
function ffmpeg {
	command ffmpeg$WSL -version &> /dev/null || notfound "FFmpeg"
	command ffmpeg$WSL "$@"
}
function node {
	command node$WSL --version &> /dev/null || notfound "Node.js"
	command node$WSL "$@"
}
