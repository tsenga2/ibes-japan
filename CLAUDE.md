# IBES Japan / International — Analyst Forecast Dispersion

## Research question

How does analyst disagreement about EPS (STDEV of estimates) evolve as the forecast
horizon (FPI) shrinks toward the fiscal period end?

1. **Evolution of disagreement**: Does the cross-analyst SD of EPS forecasts decline
   as time passes (FPI ↓, STATPERS → FPEDATS)? Presumed to shrink, but to be verified.
2. **Heterogeneity**: Does the speed/shape of this "shrinkage" vary systematically
   with firm characteristics — size, age, market cap?

## Plan

1. Compute evolution measures of dispersion (e.g., SD by FPI/horizon per firm × fiscal
   period; shrinkage rates like STDEV_5_vs_0, CV_10_vs_0, mean log STDEV change).
2. Merge with firm-level accounting data to supplement firm information missing in
   IBES — to be sourced from **Refinitiv LSEG Datastream**.
3. Relate shrinkage measures to firm characteristics (and country-level variables:
   FDI, GDP, financial development — see Dropbox folder).

## Current priority (June 2026)

Substantial country-level analysis is already done (shrinkage by country/year, FDI/GDP/
GFDD merges, binscatters — see Dropbox `graphs/`, `Both/`, `outputs/`). That direction
continues, but the immediate focus is **firm-level analysis first**: compute shrinkage
measures per firm × fiscal period, merge Datastream firm characteristics, then revisit
country aggregation later.

## Data

| File | Location | Content |
|---|---|---|
| `IBES/international/ibes-summary-international.dta` (467 MB) | repo | Consensus EPS forecasts, non-US firms: firm × STATPERS (monthly) × FPI; NUMEST, MEAN/MEDEST, STDEV, HIGH/LOW, CURCODE, FPEDATS, ACTUAL |
| `IBES/international/ibes-detail-international.dta` (542 MB) | repo | Analyst-level detail file, same coverage |
| `IBES/North America/ibes-summary-na.dta`, `ibes-detail-na.dta` | repo | US/Canada counterparts |
| `combined_data.csv` / `combined_data.dta` (~190–260 MB) | repo | Japan firm-month panel from 1995m02: Nikkei/Toyo Keizai data — EPS actual/estimate, prices, mktcap, sectors. CSV is **Shift-JIS** encoded |
| `ibes-summary-japan-tseries.csv/.dta` | repo | Monthly aggregate Japan series from 1987m1: means/SDs of actuals, estimates, dispersion (STDEV, CV), forecast errors |
| Datastream firm accounting data | **to be obtained** | Firm characteristics: size, age, mktcap, etc. |

Country-level merge data and shrinkage outputs live in
`/Users/tsenga/Dropbox (Personal)/IBES/` (FDI, Penn World Table, World Bank GFDD,
shrinkage_year_country.dta, graphs). NOTE: most Dropbox files are online-only
placeholders (0 bytes locally) — right-click → "Make Available Offline" to use them.

## IBES ↔ Datastream linking (pilot done, UK, June 2026)

The IBES international "CUSIP" field = 2-char country prefix + first 6 chars of SEDOL
(e.g. Japan `FJ`, UK `EX`); reconstruct SEDOL7 by recomputing the check digit.
UK pilot in `datastream/`: **80.6% of 5,526 UK firms linked** (`uk_link_v2.csv`) —
73% via SEDOL (codes must be requested as `UK`+SEDOL7 in Datastream; bare SEDOLs and
new-style B-codes fail), +7.6% via name matching against the WSCOPEUK+DEADUK universe
(`uk_ds_universe.csv`). Residual ~19%: renamed firms (RBS→NatWest, Reckitt&Colman→
Reckitt Benckiser — name match can't bridge renames), SEDOL churn after corporate
actions (Tesco 2021 — caught by name), ADR/identifier oddities. `uk_name_match_review.csv`
has 105 borderline candidates pending manual check. **Japan done: 98.2% linked**
(`jp_link_v1.csv`; universe = WSCOPEJP + DEADJP in `jp_ds_universe.csv`). Key shortcut
discovered: with a full country universe (WSCOPE## + DEAD##) pulled once, IBES SEDOLs
match locally — no per-code resolution requests needed. Japan residual is mostly
duplicate IBES lines for ADRs (EISAI `EII`, HOYA `HYB`) — when an IBES firm has
multiple records, prefer the 4-digit-OFTIC one. Lesson: dropping unmatched firms biases
toward dead small firms — large survivors churn identifiers most.

## Repo notes

- Flattened June 2026: everything now directly in `/Users/tsenga/ibes-japan`
  (previously nested `ibes-japan/ibes-japan`). Stata path globals updated accordingly;
  collaborator (kawabatahatsu) globals left as-is.
- Key folders: `2025/` and `2026/` (current analysis .do files), `IBES/` (raw data),
  `Nikkei/`, `graph/`, `table/`; `paper.tex` / `slides.tex` (LaTeX outputs).
- Mixed Stata (.do) and Python; Stata scripts use `global mypath` headers per machine.
