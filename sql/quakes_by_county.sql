drop view if exists earthquakes_by_county;
create view earthquakes_by_county as select
  counties.rowid,
  counties.county_name as county,
  states.name as state,
  counties.geometry,
  count(*) as count
from
  counties
  join states on counties.state_fips = states.state_fips,
  earthquakes
where
  contains(counties.geometry, earthquakes.geometry)
  and earthquakes.rowid in (
    select
      rowid
    from
      SpatialIndex
    where
      f_table_name = 'earthquakes'
      and search_frame = counties.geometry
  )
group by
  counties.rowid;