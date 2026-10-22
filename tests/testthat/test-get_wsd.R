test_that("get_wsd() errors clearly when the database file is missing", {
  expect_error(get_wsd(path = tempfile(fileext = ".xlsx")),
               "WSD file not found")
})

test_that("get_wsd() returns water supplies with the expected columns", {
  wsd_file <- wava_data_path("Water_Supply_Systems",
                             "NPS_Water_Systems_Database_Joined.xlsx")
  testthat::skip_if_not(file.exists(wsd_file),
                        paste0("no water supply database at \"", wsd_file,
                               "\" (data folder: ", data_dir_source(), ")"))

  wsd <- get_wsd(rapid = TRUE)

  expect_s3_class(wsd, "sf")
  expect_gt(nrow(wsd), 0)
  expect_true(all(c("wsd_source_id", "park_unit", "source_type") %in% names(wsd)))
})
