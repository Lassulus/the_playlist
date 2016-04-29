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

reversecheck: ## check for orphan files in directory
	ls music/* | xargs -n1 bin/checkMissingLink

addorphans: ## add orphan files to links
	ls music/* | xargs -n1 bin/checkMissingLink | sed 's,.*\(.\{11\}\)\.ogg,http://www.youtube.com/watch?v=\1,' | xargs -n1 youtplaylist >> links

checkmp3:        ## check for missing songs
checkmp3:        ## make download should be run first
	cat links | musicDir=./mp3 xargs -n1 bin/checkMissingmp3

play:         ## play the playlist without downloading
	mpv --loop=inf --shuffle --playlist links

copy:         ## make copy dest="/mnt/tmp/music"
copy:         ## to copy music to dest
	rsync -vrltD ./music/ ${dest}

convert2mp3:	## converts stuff from ./music to ./mp3
	ls music/* | target=./mp3 xargs -n1 bin/ogg2mp3
