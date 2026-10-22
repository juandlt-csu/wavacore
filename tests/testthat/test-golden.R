# Compare wavacore with golden outputs saved from the old code in
# nps_water_vulnerability (see fixtures/README.md). A failure means wavacore no
# longer returns exactly what the old code did. Report it; don't regenerate the
# golden file or loosen the comparison to make it pass.

source(test_path("fixtures", "golden_cases.R"), local = TRUE)

for (case in golden_cases) {
  test_that(paste("golden:", case$id, "matches the old code"), {
    golden_file <- test_path("fixtures", "golden", paste0(case$id, ".rds"))
    skip_if_not(file.exists(golden_file),
                "golden file not generated (see fixtures/README.md)")
    if ("data" %in% case$needs) {
      skip_if_not(dir.exists(wava_data_path("Water_Supply_Systems")),
                  "shared WaVA data folder not available")
    }
    if ("internet" %in% case$needs) {
      skip_if_offline()
    }

    actual <- do.call(case$fun, case$args)

    expect_identical(actual, readRDS(golden_file))
  })
}
