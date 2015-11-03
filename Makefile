jobs = 2

help:         ## Show this help.
		@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

download:     ## download all links to ./music
download:			## you can specify number of jobs with ex. jobs=4
	cat links | parallel -j${jobs} -k "target=./music bin/yout2ogg"

downloadmp3:  ## download all links to ./mp3 (as mp3)
downloadmp3:  ## you can specify number of jobs with ex. jobs=4
	cat links | parallel -j${jobs} -k "target=./mp3 bin/yout2mp3"

add:           ##make add url="http://youtube..."
add:           ##to add link to ./links
	bin/youtplaylist ${url} >> links

check:        ## check for missing songs
check:        ## make download should be run first
	cat links | musicDir=./music xargs -n1 bin/checkMissing

play:         ## play the playlist without downloading
	mpv --loop=inf --shuffle --playlist links

copy:         ## make copy dest="/mnt/tmp/music"
copy:         ## to copy music to dest
	rsync -vrltD ./music/ ${dest}
