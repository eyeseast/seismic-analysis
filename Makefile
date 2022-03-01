
FILES=r-sf-mapping-geo-analysis/countries.geojson \
	r-sf-mapping-geo-analysis/seismic.geojson \
	r-sf-mapping-geo-analysis/sf_test_addresses.tsv

quakes.db: $(FILES)
	pipenv run geojson-to-sqlite $@ countries r-sf-mapping-geo-analysis/countries.geojson --spatialite
	pipenv run geojson-to-sqlite $@ seismic r-sf-mapping-geo-analysis/seismic.geojson --spatialite
	pipenv run sqlite-utils insert $@ addresses r-sf-mapping-geo-analysis/sf_test_addresses.tsv --csv

geocode: quakes.db
	pipenv run geocode-sqlite nominatim quakes.db addresses \
		-l '{address}, San Francisco, CA' \
		--user-agent 'Chris Amico/chrisamico.com'

run:
	# this will fail if no databases exist
	pipenv run datasette serve *.db -m metadata.yml --load-extension spatialite

clean:
	rm -f quakes.db quakes.db-*
