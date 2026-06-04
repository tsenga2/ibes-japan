# Datastream sitting #1 — Japan (≈30 min)

All files referenced are in `datastream/`. Same workflow as the UK pilot.
Save each request's output to its own sheet; save workbook as `jp_results.xlsx`.

## Step 0 — probe (1 row, sanity check)

Before uploading lists, add one request-table row:

| Update | Type | Series (type directly) | Datatypes |
|---|---|---|---|
| YES | S | `UK6821506,UK6900643,UK6435145` | `NAME,SECD,ISIN` |

Expected: SONY GROUP, TOYOTA MOTOR, +1. If these come back blank, STOP and tell
Claude — the UK-prefix convention may not extend to Japanese SEDOLs, and we switch
to plan B (TSE local codes) without wasting the session.

## Step 1 — upload code lists

- `jp_codes_prefixed_1.csv` (4,000 codes) → Create List (from range) → note L# code
- `jp_codes_prefixed_2.csv` (640 codes) → same

## Step 2 — resolve codes (2 rows)

| Update | Type | Series | Datatypes |
|---|---|---|---|
| YES | S | L#(list 1) | `NAME,ISIN,SECD,DSCD,GEOGN,BDATE,TIME,MV` |
| YES | S | L#(list 2) | `NAME,ISIN,SECD,DSCD,GEOGN,BDATE,TIME,MV` |

## Step 3 — Japan universe for name matching (rows as needed)

| Update | Type | Series | Datatypes |
|---|---|---|---|
| YES | S | `WSCOPEJP` | `NAME,ISIN,SECD,DSCD,GEOGN,BDATE,TIME` |
| YES | S | `DEADJP1` (then DEADJP2, ... as many as exist — check Find Series for "DEADJP") | same |

## Step 4 — send back

`jp_results.xlsx` (all sheets) → Claude builds `jp_link_v1.csv` automatically,
using SEDOL first, then TSE code (OFTIC) cross-check, then name matching.
