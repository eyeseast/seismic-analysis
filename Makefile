
FILES=r-sf-mapping-geo-analysis/countries.geojson \
	r-sf-mapping-geo-analysis/seismic.geojson \
	r-sf-mapping-geo-analysis/sf_test_addresses.tsv

EARTHQUAKES=https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2022-01-01&minmagnitude=3

DB=quakes.db

install:
	pipenv sync

usgs/earthquakes.geojson:
	mkdir -p $(dir $@)
	wget -O $@ $(EARTHQUAKES)

processed/states_carto_2018.geojson:
	pipenv run censusmapdownloader states-carto

processed/counties_2020.geojson:
	pipenv run censusmapdownloader counties

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

states: processed/states_carto_2018.geojson
	pipenv run geojson-to-sqlite $(DB) states $^ --pk geoid --spatialite
	pipenv run sqlite-utils create-index $(DB) states state_fips --if-not-exists
	pipenv run sqlite-utils create-spatial-index $(DB) states geometry

counties: processed/counties_2020.geojson
	pipenv run geojson-to-sqlite $(DB) counties $^ --pk geoid --spatialite
	pipenv run sqlite-utils create-index $(DB) counties state_fips county_fips --if-not-exists
	pipenv run sqlite-utils create-spatial-index $(DB) counties geometry

earthquakes: quakes.db usgs/earthquakes.geojson
	pipenv run geojson-to-sqlite quakes.db earthquakes usgs/earthquakes.geojson --spatialite
	pipenv run sqlite-utils create-spatial-index quakes.db earthquakes geometry

earthquakes_by_county:
	sqlite3 $(DB) < sql/quakes_by_county.sql

run:
	# this will fail if no databases exist
	pipenv run datasette serve *.db \
		-m metadata.yml \
		--load-extension spatialite \
		--setting sql_time_limit_ms 5000

publish:
	pipenv run datasette publish fly *.db \
		--app nicar22-seismic-datasette \
		--spatialite \
		-m metadata.yml \
		--install datasette-geojson-map \
		--install sqlite-colorbrewer

open:
	flyctl --app nicar22-seismic-datasette open

# exports
exports/risk.geojson:
	mkdir -p $(dir $@)
	pipenv run datasette quakes.db --get /quakes/risk.geojson \
		-m metadata.yml \
		--load-extension spatialite > $@

exports/risk_innout.geojson:
	mkdir -p $(dir $@)
	pipenv run datasette quakes.db --get /quakes/risk_innout_indexed.geojson \
		-m metadata.yml \
		--load-extension spatialite > $@

exports: exports/risk.geojson exports/risk_innout.geojson

clean:
	rm -f quakes.db quakes.db-*
