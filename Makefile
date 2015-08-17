help:         ## Show this help.
		@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

download:     ## download all links to ./music
	cat links | xargs -n 1 bin/yout2ogg

add:           ##make add url="http://youtube..."
add:           ##to add link to ./links
	bin/youtplaylist ${url} >> links
