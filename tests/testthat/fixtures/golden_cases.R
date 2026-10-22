# Cases for the golden comparison between the old code in
# nps_water_vulnerability (before the split) and wavacore.
#
# Used by make_golden.R, which writes golden/<id>.rds from the old code, and by
# test-golden.R, which checks that wavacore returns the identical object.
# `args` must work with both the old and the new function, so it can't use
# arguments added in wavacore (such as get_wsd()'s `path`).
# `needs`: "data" = the shared WaVA data folder, "internet" = a live download.
# `downloads`: what an "internet" case fetches, named in its skip reason.

golden_cases <- list(
  list(id = "get_wsd_defaults",
       fun = "get_wsd",
       args = list(),
       needs = "data"),
  list(id = "get_wsd_flat_all_states",
       fun = "get_wsd",
       args = list(conus = FALSE, sf = FALSE),
       needs = "data"),
  list(id = "get_wsd_four_parks",
       fun = "get_wsd",
       args = list(park = c("GLAC", "MORA", "ROMO", "ZION")),
       needs = "data"),
  # fill_empty_coords downloads the park system and the state boundaries
  list(id = "get_wsd_rapid",
       fun = "get_wsd",
       args = list(rapid = TRUE),
       needs = c("data", "internet"),
       downloads = "NPS park boundaries (NPS Data Store) and US state boundaries (tigris)"),
  list(id = "get_wsd_fill_all_states",
       fun = "get_wsd",
       args = list(fill_empty_coords = TRUE, conus = FALSE),
       needs = c("data", "internet"),
       downloads = "NPS park boundaries (NPS Data Store) and US state boundaries (tigris)"),
  list(id = "getParkSystem",
       fun = "getParkSystem",
       args = list(),
       needs = "internet",
       downloads = "NPS park boundaries (NPS Data Store)"),
  list(id = "getParkBoundary_two_parks",
       fun = "getParkBoundary",
       args = list(park = c("ROMO", "ZION")),
       needs = "internet",
       downloads = "NPS park boundaries (NPS Data Store)"),
  list(id = "getUnitVisitation_api",
       fun = "getUnitVisitation",
       args = list(units = c("ROMO", "ZION"), startYear = 2015, endYear = 2020),
       needs = "internet",
       downloads = "visitation from the NPS STATS API (irmaservices.nps.gov)"),
  list(id = "getUnitVisitation_allStats",
       fun = "getUnitVisitation",
       args = list(units = c("ROMO", "ZION"), startYear = 2015, endYear = 2020,
                   allStats = TRUE),
       needs = "internet",
       downloads = "the full NPS visitation dataset (irmaservices.nps.gov)")
)
