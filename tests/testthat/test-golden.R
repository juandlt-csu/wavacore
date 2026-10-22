# Compare wavacore with golden outputs saved from the old code in
# nps_water_vulnerability (see fixtures/README.md). A failure means wavacore no
# longer returns exactly what the old code did. Report it; don't regenerate the
# golden file or loosen the comparison to make it pass.
#
# Every skip names the case and what is missing. A service that is down is not
# a skip: its error is reported as is.

source(test_path("fixtures", "golden_cases.R"), local = TRUE)

golden_dir <- test_path("fixtures", "golden")

# No golden files at all (e.g. under R CMD check, or a fresh clone): one skip
# for the whole file instead of one per case.
if (length(list.files(golden_dir, pattern = "\\.rds$")) == 0) {
  skip(paste0("no golden files in ", golden_dir, "; run ",
              "tests/testthat/fixtures/make_golden.R (see fixtures/README.md)"))
}

data_folder_reason <- function(id) {
  paste0(id, ": no Water_Supply_Systems folder in the data folder \"",
         wava_data_dir(), "\" (", data_dir_source(), ")")
}

for (case in golden_cases) {
  test_that(paste("golden:", case$id, "matches the old code"), {
    golden_file <- file.path(golden_dir, paste0(case$id, ".rds"))
    skip_if_not(file.exists(golden_file),
                paste0(case$id, ": golden file missing: ", golden_file,
                       "; run tests/testthat/fixtures/make_golden.R"))
    if ("data" %in% case$needs) {
      skip_if_not(dir.exists(wava_data_path("Water_Supply_Systems")),
                  data_folder_reason(case$id))
    }
    if ("internet" %in% case$needs) {
      skip_on_cran()
      skip_if_not(curl::has_internet(),
                  paste0(case$id, ": offline; this case downloads ",
                         case$downloads))
    }

    actual <- do.call(case$fun, case$args)

    expect_identical(actual, readRDS(golden_file))
  })
}
