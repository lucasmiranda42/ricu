# ricu 0.6.4

* MIMIC-IV (`miiv`) updated from version 2.2 to 3.1
  - Adds data from 2020-2022 (new anchor_year_group: "2020 - 2022")
  - ~27% increase in patient data (364,627 patients, 546,028 admissions, 94,458 ICU stays)
  - itemid values in d_labitems/labevents are consistent with v2.2 (no concept mapping changes needed)
  - No schema changes from v2.2

* SICdb (`sic`) updated from version 1.0.6 to 1.0.8
  - 36 invalid cases removed (27,350 ICU admissions)
  - New columns in `cases` table: HospitalDischargeDay, HospitalStayDays, AdmissionUrgency
  - New LOINC mapping columns in `d_references` table: LOINC_code, LOINC_short, LOINC_long
  - New signals in data_float_h: HFNC therapy, RASS, NRS-11, SOFA score
  - Fixed OffsetAfterFirstAdmission calculation
  - Fixed `data_ref` table: added missing FieldID column, removed invalid index_var

# ricu 0.6.3

* Docs only update

# ricu 0.6.2

* fix ignore.attr argument that changed in rbindlist() in data.table >=1.15.0
* SICdb bicarbonate / BUN units fixed
* SICdb vasopressor units
* separate SpO2 / SaO2 concepts

# ricu 0.6.1

* fixing the data-sources specification for MIMIC-IV (`miiv`)

# ricu 0.6.0

* Salzburg database (SICdb, `sic` in `ricu`) added as a data source with 64 concepts available
* MIMIC-IV (`miiv` in `ricu`) version bumped to 2.2
* fixed the usage of `round()` and `trunc()`; both replaced by `floor()` throughout

# ricu 0.5.6

* maintenance release: fixes non-character numeric version input issues

# ricu 0.5.5

* maintenance release: fixes an issue introduced by pillar 1.9.0 via an update
  to 0.2.0 of prt

# ricu 0.5.4

* maintenance release: tests using `mockthat` are only run when available

# ricu 0.5.3

* maintenance release for compatibility with an update to `prt`

# ricu 0.5.2

* maintenance release due to issue with `units` (#301)

# ricu 0.5.1

* maintenance release due to upcoming API change of `rlang` v1.0.0

# ricu 0.5.0

* adds `miiv` data source (MIMIC-IV)
* new data class `win_tbl` (inheriting from `ts_tbl`), which allows for
  specifying a validity duration (for example for infusions consisting of both
  a rate and a duration)
* automatic unit conversion is available by specifying the `unt_cncpt` concept
  type

# ricu 0.4.0

* CRAN release which includes `aumc` data source and `sep3` concept

# ricu 0.3.0

* revamped `src_env` setup

# ricu 0.2.1

* concept harmonization (mostly `aumc` and `hirid` uom fixes)
* split of `setup_src_data()` from `setup_src_env()` for convenient setup in
  non-interactive scenarios

# ricu 0.2.0

* add `aumc` data source

# ricu 0.1.3

* concept fixes (`susp_inf`, non-hadm loading of `abx` on `mimic`, `map` on
  `hirid`)
* fix CRAN policy violation

# ricu 0.1.2

* restructure SOFA computation
* add concept caching
* add `\value{}` entries to docs

# ricu 0.1.1

* make CRAN compliant (`.GlobalEnv` default in `attach_src()`)
* concept fixes: weight, vasopressors & height

# ricu 0.1.0

* Added a `NEWS.md` file to track changes to the package.
* CRAN submission
