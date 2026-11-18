#!/bin/bash
# App Store preview assembly for Hushlight (HL-037).
#
#   ./scripts/make-store-preview.sh <edit-file> <out.mp4>
#
# An edit file is a few lines:
#   appearance dark|light
#   seg  <recording.mov> <in-seconds> <out-seconds>   # in edit order; joined by a dissolve
#   card <id> <start> <end>                            # preview/card-<id>.png, output seconds
# Paths are relative to the edit file. The recordings are `simctl io recordVideo` captures
# of the 6.9" simulator (1320×2868, variable frame rate); they never enter git — only the
# edit and the finished preview's provenance do.
#
# The picture is the footage, full-bleed, with text cards fading in and out over it — and
# nothing else. It used to be the screenshot frame come to life (room, device rect, bezel
# ring), and App Review round 2 (2026-09-09) rejected exactly that under Guideline 2.3.4:
# a preview must show the app as it will appear on the device, and device frames are the
# named exclusion; text overlays are the named allowance. Output is exactly what App Store Connect
# accepts for the 6.9" slot — 886×1920, 30 fps, H.264 High 4.0 at ~11 Mbps, stereo AAC
# (silent), 15–30 s — and the script refuses to write anything outside that window.
set -euo pipefail
cd "$(dirname "$0")/.."

EDIT=${1:?edit file}
OUT=${2:?output .mp4}
STORE=docs/design/hushlight/store
LAYOUT=$STORE/preview/layout.json
XFADE=0.5           # seconds of dissolve between segments
CARD_FADE=0.5       # seconds a card takes to arrive and to leave

edit_dir=$(cd "$(dirname "$EDIT")" && pwd)
read -r SW SH < <(python3 -c "import json;s=json.load(open('$LAYOUT'))['canvas'];print(s['width'],s['height'])")
python3 -c "import json,sys; sys.exit(0 if json.load(open('$LAYOUT')).get('fullBleed') else 1)" \
    || { echo "make-store-preview: $LAYOUT is from the framed era — regenerate it with make-store-frames.swift" >&2; exit 1; }

appearance=dark
segs=()   # "path in out"
cards=()  # "id start end"
while read -r kind a b c _; do
    case "$kind" in
        appearance) appearance=$a ;;
        seg)  segs+=("$edit_dir/$a $b $c") ;;
        card) cards+=("$a $b $c") ;;
        ""|\#*) ;;
        *) echo "make-store-preview: unknown line '$kind'" >&2; exit 1 ;;
    esac
done < <(sed 's/#.*//' "$EDIT")   # trailing comments allowed
[ ${#segs[@]} -gt 0 ] || { echo "make-store-preview: no segments" >&2; exit 1; }

# Inputs: the recordings, then one input per card. (The room and bezel inputs went with
# the framed design — see the header.)
inputs=()
filter=""
total=0
i=0
for s in "${segs[@]}"; do
    read -r path in out <<<"$s"
    [ -f "$path" ] || { echo "make-store-preview: missing $path" >&2; exit 1; }
    inputs+=(-i "$path")
    len=$(python3 -c "print($out-$in)")
    # simctl recordVideo is variable-frame-rate and emits nothing while the screen is
    # still, so a segment can end short of its nominal length; xfade then runs out of
    # first-input frames and freezes on the second's first frame. Clone the last frame
    # out past the end and cut the segment to exactly its length.
    filter+="[$i:v]trim=start=$in:end=$out,setpts=PTS-STARTPTS,fps=30,tpad=stop_mode=clone:stop_duration=2,trim=duration=$len,setpts=PTS-STARTPTS,scale=$SW:-2:flags=lanczos,crop=$SW:$SH:0:0,setsar=1,format=yuv420p[s$i];"
    lens[$i]=$len
    total=$(python3 -c "print($total+$len)")
    i=$((i+1))
done
n=$i
# Dissolves overlap, so the piece is shorter than the sum of its parts.
total=$(python3 -c "print(round($total - $XFADE*($n-1), 3))")
python3 -c "import sys; t=$total; sys.exit(0 if 15<=t<=30 else 1)" \
    || { echo "make-store-preview: ${total}s is outside Apple's 15–30 s window" >&2; exit 1; }

# Chain the segments with xfade.
if [ "$n" -eq 1 ]; then
    filter+="[s0]copy[foot];"
else
    prev="[s0]"; acc=${lens[0]}
    for ((k=1; k<n; k++)); do
        off=$(python3 -c "print(round($acc - $XFADE*$k, 3))")
        label="[x$k]"; [ "$k" -eq $((n-1)) ] && label="[foot]"
        filter+="$prev[s$k]xfade=transition=fade:duration=$XFADE:offset=$off$label;"
        prev="[x$k]"; acc=$(python3 -c "print($acc+${lens[$k]})")
    done
fi

# Full-bleed: the footage is the picture. The 1320×2868 capture scales to 886×1926 and the
# six spare rows come off the bottom bleed, so the aspect is exact rather than 0.3% off.
filter+="[foot]format=yuv420p[v1];"

# Cards: each arrives and leaves on an alpha fade, and is only composited while it is up.
stage="[v1]"; idx=$n; c=0
for card in "${cards[@]}"; do
    read -r id start end <<<"$card"
    png=$STORE/preview/card-$id.png
    [ -f "$png" ] || { echo "make-store-preview: missing $png" >&2; exit 1; }
    inputs+=(-loop 1 -framerate 30 -t "$total" -i "$png")
    outst=$(python3 -c "print(round($end-$CARD_FADE,3))")
    filter+="[$idx:v]format=rgba,fade=t=in:st=$start:d=$CARD_FADE:alpha=1,fade=t=out:st=$outst:d=$CARD_FADE:alpha=1[c$c];"
    filter+="$stage[c$c]overlay=0:0:format=yuv420:enable='between(t,$start,$end)'[k$c];"
    stage="[k$c]"; idx=$((idx+1)); c=$((c+1))
done
filter+="${stage}format=yuv420p[vout]"

mkdir -p "$(dirname "$OUT")"
ffmpeg -loglevel error -y "${inputs[@]}" \
    -f lavfi -t "$total" -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
    -filter_complex "$filter" -map "[vout]" -map "$idx:a" \
    -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 \
    -b:v 11M -minrate 9M -maxrate 12M -bufsize 24M -preset slow \
    -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -movflags +faststart -t "$total" "$OUT"

# Say what was made, in the terms the upload form checks.
ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,codec_name,profile,level,r_frame_rate:format=duration,bit_rate \
    -of default=noprint_wrappers=1 "$OUT" | sed 's/^/make-store-preview:   /'
echo "make-store-preview: $OUT (${total}s)"
