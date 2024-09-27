#!/bin/bash

source shconfigs.sh

# take $asset name as arg
# $model fallbacks to $asset
asset="$1"
model="$2"
if [[ $# == 0 ]]; then
	read -re -p "Asset name? " asset model
fi
model=${model:-$asset}

# rip the asset and dump into $AR_DIR
echo "LOG: Ripping binary '$WORK_DIR/$asset' ..."
[[ -d "$WORK_DIR/${model}_" ]] && echo "Directory named '$model/' already exists!" && exit 1
"$AR_APP" "$WORK_DIR/$asset" -q | tail -n 1
[[ ! -f "$WORK_DIR/$asset" ]] && exit 1

# prepare the asset directory
mkdir "$WORK_DIR/${model}_/"
cp "$WORK_DIR/$asset" "$WORK_DIR/${model}_/"
rm -f "$WORK_DIR/$model"
echo "LOG: Moved asset to directory '$WORK_DIR/${model}_/'"

WORK_DIR+="/${model}_"

# detect ripped model filename
matches=( "$model" "illust_$model" )
for file in "${matches[@]}"; do
	[[ -f "$AR_SRC/TextAsset/$file.atlas.txt" ]] && found=true && break
done
[[ -z "$found" ]] && echo "No specified model detected! Exiting ..." && exit 1
echo "LOG: Detected model: '$file'"

# fetch files from dump
# '*' globbing expands in context of array

index=(
	"$AR_SRC/TextAsset/$file.atlas.txt"
	"$AR_SRC/TextAsset/$file"*".skel.bytes"
	"$AR_SRC/Texture2D/$file"*".png"
)
# push $index_add from configs into fetch index
call_index_add
for i in "${index_add[@]}"; do
	index+=( "$AR_SRC/$i" )
	echo "LOG: Fetching extra '$i'"
done

for data in "${index[@]}"; do
	mv "$data" "$WORK_DIR/$(
		basename "$data" |                  # base filename
		sed -E 's/\.(txt|bytes|rgba4444)//' # strip bad extensions
	)"
done

skel=( "$WORK_DIR/$file"*".skel" )
atlas="$WORK_DIR/$file.atlas"
texture="$WORK_DIR/$file.png"

# detect texture folder from $skel binary
UNPACK_DIR=$(
	head -c 80 "$skel" |    # file headers
	tail -c +60 |           # byte index 60
	grep -oE -m 1 -e '^\w+' # <pngFolder>
)
echo "LOG: Detected image path: './$UNPACK_DIR/'"
UNPACK_DIR="$WORK_DIR/$UNPACK_DIR/"

# unpack with Spine 4.1.26 using `PMA` atlas setting
function UPMA-spine {
	SV="$SV4"
	pma_atlas="$WORK_DIR/$file.pma.atlas"
	pma_delete="rm $pma_atlas"
	{
		head -n 6 "$atlas"
		echo "pma: true"
		tail -n +7 "$atlas"
	} > "$pma_atlas"
	atlas="$pma_atlas"
}

# unpack with older Spine using FFmpeg-generated UPMA texture
function UPMA-ffmpeg {
	SV="$SV3"
	pma_texture="$WORK_DIR/$file.pma.png"
	pma_delete="mv $pma_texture $texture"
	mv "$texture" "$pma_texture"
	echo "LOG: Unpremultiplying texture with FFmpeg ..."

	local vf="geq="
	vf+="r='min( r(X,Y)/alpha(X,Y) * 255, 255 )':"
	vf+="g='min( g(X,Y)/alpha(X,Y) * 255, 255 )':"
	vf+="b='min( b(X,Y)/alpha(X,Y) * 255, 255 )':"
	vf+="a='alpha(X,Y)'"

	ffmpeg -loglevel error -i "$pma_texture" -vf "$vf" -y "$texture"
	[[ -f "$texture" ]] && echo "LOG: Unpremultiplication success!" || exit 1
}

# select UPMA function
SV="$SV3"
if [[ "$UPMA" == 1 ]]; then
	[[ -n "$SV4" ]] && UPMA-spine || UPMA-ffmpeg
fi

# unpack
echo "LOG: Unpacking texture into '$UNPACK_DIR' ..."
"$SPINE" -u "$SV" -i "$WORK_DIR" -o "$UNPACK_DIR" -c "$atlas" 1> /dev/null

if [[ -d "$UNPACK_DIR" ]]; then
	echo "LOG: Unpacking success!"
else
	echo "Something went wrong! Check '~/Spine/spine.log' for error trace"
	exit 1
fi

# delete temp UPMA file
$pma_delete
