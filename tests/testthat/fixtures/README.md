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
  they need the shared data folder or internet).
- `make_golden.R`: runs those calls with the old code at `b62f366` and saves
  the results to `golden/<id>.rds`, plus `golden/golden_info.txt` (date, the
  pinned commit, the commit the clone was on, package versions, row and warning
  counts).
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
find out why the output changed first. Some cases download live data (park
boundaries, state boundaries, visitation), so a failure can come from the
source changing rather than the code; `golden_info.txt` says when the golden
files were made.
