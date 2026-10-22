# Write the golden files for test-golden.R from the OLD code in
# nps_water_vulnerability, as it was before the split.
#
# Run from the wavacore repo root, in a fresh R session (not with wavacore
# loaded):
#   Rscript tests/testthat/fixtures/make_golden.R ../nps_water_vulnerability
#
# It sources the playground's setup.R, as the old workflow did (about 70
# packages plus every file in src/), then runs each case in golden_cases.R from
# the playground root, so the old code's relative `data/` paths resolve through
# the playground's data link. It writes one golden/<id>.rds per case and
# golden/golden_info.txt saying where they came from.
#
# Only regenerate the golden files on purpose (e.g. the source data changed and
# the team agreed); never to make a failing test pass.

old_commit <- "b62f366"   # nps_water_vulnerability upstream/main at the split

args <- commandArgs(trailingOnly = TRUE)
old_repo <- normalizePath(if (length(args) > 0) args[1] else "../nps_water_vulnerability",
                          mustWork = TRUE)
fixtures <- normalizePath(file.path("tests", "testthat", "fixtures"), mustWork = TRUE)
golden_dir <- file.path(fixtures, "golden")
dir.create(golden_dir, showWarnings = FALSE)

# the old code must be the frozen pre-split code
head <- system2("git", c("-C", shQuote(old_repo), "rev-parse", "HEAD"), stdout = TRUE)
dirty <- system2("git", c("-C", shQuote(old_repo), "status", "--porcelain", "--",
                          "src", "setup.R"), stdout = TRUE)
if (!startsWith(head, old_commit)) {
  stop("nps_water_vulnerability is at ", substr(head, 1, 7), ", not ", old_commit)
}
if (length(dirty) > 0) {
  stop("nps_water_vulnerability has uncommitted changes in src/ or setup.R")
}
if ("wavacore" %in% loadedNamespaces()) {
  stop("wavacore is loaded; run this in a fresh R session")
}

setwd(old_repo)
source("setup.R")

source(file.path(fixtures, "golden_cases.R"))

info <- c(
  paste("Written:", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
  paste("Old code: nps_water_vulnerability", substr(head, 1, 7), "via setup.R"),
  paste("Data folder:", normalizePath("data")),
  paste("R:", R.version.string),
  paste0("Packages: ", paste(sapply(c("sf", "dplyr", "tidyr", "readxl", "janitor",
                                      "tigris", "igraph", "httr", "jsonlite", "readr"),
                                    function(p) paste(p, packageVersion(p))),
                             collapse = ", ")),
  ""
)

for (case in golden_cases) {
  message("Running ", case$id)
  warns <- character()
  value <- withCallingHandlers(
    do.call(case$fun, case$args),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  saveRDS(value, file.path(golden_dir, paste0(case$id, ".rds")))
  info <- c(info, sprintf("%s: %s, %d rows, %d warning(s)%s",
                          case$id, class(value)[1], NROW(value), length(warns),
                          if (length(warns) > 0) paste0(": ", paste(unique(warns), collapse = " | ")) else ""))
}

writeLines(info, file.path(golden_dir, "golden_info.txt"))
message("Golden files written to ", golden_dir)
