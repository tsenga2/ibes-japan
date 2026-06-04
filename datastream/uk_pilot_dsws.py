# %% UK pilot: match IBES firms to Datastream via SEDOL (DSWS / DatastreamPy)
# Run in CodeBook (DatastreamPy preinstalled) or locally (pip install DatastreamPy).
# In CodeBook: upload uk_ibes_firms.csv via the file browser first.
#
# Goal: measure what share of the 5,526 IBES UK firms resolve in Datastream,
# and collect DSCD/ISIN/static info for the matches.

import pandas as pd
import DatastreamPy as dsws

# ---- 1. credentials -------------------------------------------------------
DSWS_USER = "ZXXX000"   # <-- your DSWS ID
DSWS_PASS = "********"  # <-- your DSWS password
ds = dsws.DataClient(None, DSWS_USER, DSWS_PASS)

# ---- 2. load IBES UK firm list --------------------------------------------
uk = pd.read_csv("uk_ibes_firms.csv", dtype=str).fillna("")
sedols = [s for s in uk.sedol7.unique() if len(s) == 7]
print(f"{len(uk)} IBES firms, {len(sedols)} with full SEDOL")

# ---- 3. figure out which ticker format DSWS resolves ----------------------
# Try a small probe in two formats: raw SEDOL7 vs 'UK'+SEDOL7.
probe = sedols[:20]
FIELDS = ["NAME", "ISIN", "SECD", "GEOGN", "BDATE", "TIME", "MV"]

def static_pull(tickers, fields=FIELDS):
    out = []
    for i in range(0, len(tickers), 50):  # DSWS limit: 50 instruments/request
        chunk = ",".join(tickers[i:i+50])
        out.append(ds.get_data(tickers=chunk, fields=fields, kind=0))
    return pd.concat(out, ignore_index=True)

fmt_results = {}
for label, fmt in [("raw", probe), ("UKprefix", ["UK" + s for s in probe])]:
    try:
        r = static_pull(fmt, ["NAME"])
        ok = (~r.Value.astype(str).str.startswith("$$ER")).mean()
        fmt_results[label] = ok
        print(f"format {label}: {ok:.0%} resolved")
    except Exception as e:
        print(f"format {label}: failed ({e})")

best = max(fmt_results, key=fmt_results.get)
prefix = "" if best == "raw" else "UK"
print("using format:", best)

# ---- 4. full pull ----------------------------------------------------------
tickers = [prefix + s for s in sedols]
res = static_pull(tickers)

# DSWS returns long format: Instrument / Datatype / Value
wide = res.pivot_table(index="Instrument", columns="Datatype",
                       values="Value", aggfunc="first").reset_index()
wide["sedol7"] = wide.Instrument.str.replace("^UK", "", regex=True)
merged = uk.merge(wide, on="sedol7", how="left")
merged["matched"] = merged.NAME.notna() & ~merged.NAME.astype(str).str.startswith("$$ER")

print(f"\nMATCH RATE: {merged.matched.mean():.1%} of {len(merged)} IBES UK firms")
merged.to_csv("uk_pilot_match_results.csv", index=False)
print("saved -> uk_pilot_match_results.csv  (send this back for diagnosis)")
