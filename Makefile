download:
	cat links | xargs -n 1 bin/yout2ogg

add:
	bin/youtplaylist ${url} >> links
