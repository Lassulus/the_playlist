help:         ## Show this help.
		@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

download:     ## download all links to ./music
	cat links | parallel -j5 -k "target=./music bin/yout2ogg"

add:           ##make add url="http://youtube..."
add:           ##to add link to ./links
	bin/youtplaylist ${url} >> links

check:        ## check for missing songs
check:        ## make download should be run first
	cat links | musicDir=./music xargs -n1 bin/checkMissing

play:         ## play the playlist without downloading
	mpv --loop=inf --shuffle --playlist links
