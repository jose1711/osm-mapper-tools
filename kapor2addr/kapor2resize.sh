#!/bin/bash
# resizes kapor2 window
# needs to be run twice on my dual-monitor setup with gnome
size=6000
xdotool search --name "Java OpenStreetMap Editor" windowsize $size $size
sleep 3
winID=$(xdotool search --name "KAPOR$")
xdotool search --name "KAPOR" windowsize $size $size
# give some time to stabilize
xdotool windowactivate $winID
sleep 3
xdotool mousemove --window $winID 10 -15
xte "mousedown 1"
\xmessage -xrm 'Xmessage*borderWidth:0' -xrm 'Xmessage*Foreground:red' -xrm 'Xmessage.form.message.Scroll:false' -fn "-urw-*-*-r-*--0-200-0-0-p-*-*-*" -timeout 2 -center -buttons "" "pohni mysou ku lavemu hornemu rohu"
sleep 2
xte "mousemove 150 100"
xte "mouseup 1"
sleep 2
xdotool search --name "KAPOR$" windowsize $size $size
