
FILES=r-sf-mapping-geo-analysis/countries.geojson \
	r-sf-mapping-geo-analysis/seismic.geojson \
	r-sf-mapping-geo-analysis/sf_test_addresses.tsv

install:
	pipenv sync

quakes.db: $(FILES)
	pipenv run geojson-to-sqlite $@ countries r-sf-mapping-geo-analysis/countries.geojson --spatialite
	pipenv run geojson-to-sqlite $@ seismic r-sf-mapping-geo-analysis/seismic.geojson --spatialite
	pipenv run sqlite-utils insert $@ addresses r-sf-mapping-geo-analysis/sf_test_addresses.tsv --csv
	pipenv run sqlite-utils create-spatial-index $@ seismic geometry

geocode: quakes.db
	pipenv run geocode-sqlite nominatim quakes.db addresses \
		-l '{address}, San Francisco, CA' \
		--user-agent 'Chris Amico/chrisamico.com'

innout: quakes.db alltheplaces/innout.geojson
	pipenv run geojson-to-sqlite quakes.db innout alltheplaces/innout.geojson --spatialite
	pipenv run sqlite-utils create-spatial-index quakes.db innout geometry

run:
	# this will fail if no databases exist
	pipenv run datasette serve *.db -m metadata.yml --load-extension spatialite

publish:
	pipenv run datasette publish fly *.db \
		--app nicar22-seismic-datasette \
		--spatialite \
		-m metadata.yml \
		--install datasette-geojson-map \
		--install sqlite-colorbrewer

open:
	flyctl --app nicar22-seismic-datasette open

clean:
	rm -f quakes.db quakes.db-*
