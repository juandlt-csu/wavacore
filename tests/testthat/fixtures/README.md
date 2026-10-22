# Golden test fixtures

`test-golden.R` checks that wavacore returns exactly what the old code in
`nps_water_vulnerability` returned before the split.

## The baseline: `nps_water_vulnerability` at `b62f366`

We chose one commit of the playground as the reference: `b62f366`, its
`upstream/main` when wavacore was split out (2026-10-20). The golden files
always come from that commit, even after the playground changes.
`make_golden.R` extracts `setup.R` and `src/` from that commit with
`git archive`, whatever the local clone is on. The commit is set in one place,
`golden_commit` at the top of `make_golden.R`.

This is a temporary arrangement for checking the move out of the playground.
Once development has moved off the playground, `b62f366` stops being the
reference, and these tests either retire or become wavacore's own regression
baseline.

## Files

- `golden_cases.R`: the calls to compare (function, arguments, and whether
  they need the shared data folder or internet), and the data files those
  calls read. It checks the fields of every case when it is sourced, so a typo
  stops with an error instead of silently dropping a skip.
- `make_golden.R`: runs those calls with the old code at `b62f366` and saves
  the results to `golden/<id>.rds`, plus `golden/golden_info.txt` (date, the
  pinned commit, the commit the clone was on, the data folder, row and warning
  counts) and `golden/golden_env.csv` (R and every package version, and a
  checksum of each data file). It writes to a temporary folder first and
  replaces `golden/` only if every case ran, so a failed run (e.g. a service
  is down) leaves the old golden files as they were.
- `golden/`: the saved results. Not in git for now; whether the outputs can go
  in this public repo is an open question for the team.

To create the golden files, from the wavacore repo root in a fresh R session
(the clone needs commit `b62f366` and its `data` link; the script doesn't
change the clone):

```sh
Rscript tests/testthat/fixtures/make_golden.R ../nps_water_vulnerability
```

To run the comparison, point wavacore at the same data folder the playground's
`data` link points to:

```sh
WAVA_DATA_DIR="/path/to/shared/data" Rscript -e 'devtools::test(filter = "golden")'
```

The comparison is `expect_identical()`. Every skip says which case it is and
what is missing:

- no golden files at all: one skip for the whole file, saying to run
  `make_golden.R` (this is what `R CMD check` shows, because `golden/` is in
  `.Rbuildignore`);
- one golden file missing: `<case>: golden file missing: <path>`;
- no data folder: `<case>: no Water_Supply_Systems folder in the data folder
  "<path>"`, plus whether it came from the option, `WAVA_DATA_DIR`, or the
  `"data"` fallback;
- offline: `<case>: offline; this case downloads <what>` (the `downloads`
  field in `golden_cases.R`).

A service that is down while the machine is online (e.g. the NPS visitation
API) is not skipped: the case errors with the HTTP error, so an outage is
never mistaken for a pass. That is an error, not a mismatch.

If a test fails, don't regenerate the golden file or loosen the comparison:
find out why the output changed first. A failure can come from wavacore, or
from something else that changed since the golden run: an R or package
upgrade, an edit to the shared database, or a live source (park boundaries,
state boundaries, visitation). The failure message lists the R, package and
data file changes it finds against `golden_env.csv`, and names the download if
the case has one. To find the cause:

1. Run `make_golden.R` from a scratch copy of wavacore (so the real `golden/`
   stays as it is) to rebuild the golden files with today's packages, data and
   downloads.
2. Compare the fresh files with the saved ones (`identical()`).
3. If they are identical, the old code still gives the saved output, so the
   change is in wavacore. If they differ, the change came from packages, data
   or a download, not from wavacore.
