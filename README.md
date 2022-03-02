# Mapping seismic risk in Datasette

This is a demo project showing how I use SpatiaLite with Datasette for quick spatial analysis, based on Peter Aldhous' [2022 NICAR session](https://paldhous.github.io/NICAR/2022/r-sf-mapping-geo-analysis.html). To see this done in R, follow [Peter's tutorial](https://paldhous.github.io/NICAR/2022/r-sf-mapping-geo-analysis.html).

## Libraries used

- [datasette](https://docs.datasette.io/en/stable/)
- [sqlite-utils](https://sqlite-utils.datasette.io/en/stable/)
- [geojson-to-sqlite](https://github.com/simonw/geojson-to-sqlite)
- [datasette-geojson](https://github.com/eyeseast/datasette-geojson)
- [datasette-geojson-map](https://github.com/eyeseast/datasette-geojson-map)
- [sqlite-colorbrewer](https://github.com/eyeseast/sqlite-colorbrewer)
- [geocode-sqlite](https://github.com/eyeseast/geocode-sqlite) will run a geocoder on every row in a table, saving the results to `latitude` and `longitude` columns.

Run `pipenv install` to create a virtual environment and get the latest version of everything. I also recommend installing [SpatiaLite](https://www.gaia-gis.it/fossil/libspatialite/index).

## Building locally

Run `make install` to load dependencies from `Pipfile.lock`. This should recreate the same environment every time.

Once that's done, run `make quakes.db` to create a SpatiaLite database and load in seismic risk data.

To geocode the `addresses` table, run `make geocode`, which will use OpenStreetMap's [nominatim](https://nominatim.org/) geocoder. This is fine for a 30-row table, but for larger datasets, consider a different geocoder.

## Running queries

Run the Datasette server using `make run` and open `http://localhost:8001`.
