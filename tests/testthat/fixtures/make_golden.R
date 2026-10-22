# Write the golden files for test-golden.R from the OLD code in
# nps_water_vulnerability, as it was before the split.
#
# Run from the wavacore repo root, in a fresh R session (not with wavacore
# loaded):
#   Rscript tests/testthat/fixtures/make_golden.R ../nps_water_vulnerability
#
# The baseline is pinned to one commit, `golden_commit` below: upstream/main of
# nps_water_vulnerability when wavacore was split out (2026-10-20). The golden
# files always come from that commit, whatever the playground clone is on, so
# later changes to the playground don't move the baseline. The script extracts
# that commit's setup.R and src/ into a temporary folder (`git archive`; the
# clone itself is not touched), links the playground's `data` folder into it,
# sources setup.R there as the old workflow did (about 70 packages plus every
# file in src/), and runs each case in golden_cases.R. It writes one
# golden/<id>.rds per case and golden/golden_info.txt saying where they came
# from.
#
# This baseline is for checking the move out of the playground. Once
# development has moved off the playground, it is no longer the reference.
#
# Only regenerate the golden files on purpose (e.g. the source data changed and
# the team agreed); never to make a failing test pass.

golden_commit <- "b62f366"

args <- commandArgs(trailingOnly = TRUE)
old_repo <- normalizePath(if (length(args) > 0) args[1] else "../nps_water_vulnerability",
                          mustWork = TRUE)
fixtures <- normalizePath(file.path("tests", "testthat", "fixtures"), mustWork = TRUE)
golden_dir <- file.path(fixtures, "golden")
dir.create(golden_dir, showWarnings = FALSE)

if ("wavacore" %in% loadedNamespaces()) {
  stop("wavacore is loaded; run this in a fresh R session")
}
if (!dir.exists(file.path(old_repo, "data"))) {
  stop("no data folder or link in ", old_repo)
}

git <- function(...) {
  system2("git", c("-C", shQuote(old_repo), ...), stdout = TRUE)
}
golden_commit_full <- git("rev-parse", "--verify", "--quiet",
                          paste0(golden_commit, "^{commit}"))
if (length(golden_commit_full) == 0) {
  stop("commit ", golden_commit, " not found in ", old_repo,
       "; run git fetch upstream")
}
clone_head <- git("rev-parse", "--short", "HEAD")

# the old code exactly as it was at the pinned commit
old_code <- file.path(tempfile("golden_"), "nps_water_vulnerability")
dir.create(old_code, recursive = TRUE)
archive <- tempfile(fileext = ".tar")
git("archive", "--format=tar", "-o", shQuote(archive), golden_commit,
    "setup.R", "src")
utils::untar(archive, exdir = old_code)
file.symlink(normalizePath(file.path(old_repo, "data")),
             file.path(old_code, "data"))

setwd(old_code)
source("setup.R")

source(file.path(fixtures, "golden_cases.R"))

info <- c(
  paste("Written:", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
  paste("Old code: nps_water_vulnerability", golden_commit,
        "(pinned; setup.R and src/ extracted from that commit)"),
  paste("Playground clone was on:", clone_head, "(not used for the code)"),
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
