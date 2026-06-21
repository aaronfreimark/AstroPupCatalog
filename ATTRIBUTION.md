# Data attribution & licensing

This package bundles deep-sky-object catalog data from several sources. The data
licensing is independent of the package's **code** license.

## OpenNGC core (`OpenNGC/NGC.csv`, `OpenNGC/addendum.csv`)

- **OpenNGC** by Mattia Verga — <https://github.com/mattiaverga/OpenNGC>
- License: **Creative Commons Attribution-ShareAlike 4.0 International (CC-BY-SA-4.0)**
  — <https://creativecommons.org/licenses/by-sa/4.0/>
- Built from NED, HyperLEDA, SIMBAD, and HEASARC databases.
- **Share-alike** applies to the *data files*; it does not reach consuming code.
  Apps embedding this package should surface this attribution (e.g. in an in-app
  Credits / Acknowledgements screen).

## Supplemental catalogs (public domain, via CDS/VizieR)

Schema-converted to the OpenNGC CSV layout; coordinates precessed to FK5 J2000 by
VizieR. Public-domain scientific catalogues:

- `sharpless.csv` — Sharpless HII Regions (Sh2), Sharpless 1959, VizieR VII/20
- `ldn.csv` — Lynds' Catalogue of Dark Nebulae (LDN), Lynds 1962, VizieR VII/7A
- `lbn.csv` — Lynds' Catalogue of Bright Nebulae (LBN), Lynds 1965, VizieR VII/9
- `pk.csv` — Galactic Planetary Nebulae (PK), Strasbourg-ESO Catalogue, VizieR V/84
- `abell.csv` — Abell planetary nebulae (V/84) + Abell galaxy clusters (VizieR VII/110A)
- `vdb.csv` — van den Bergh Reflection Nebulae (vdB), van den Bergh 1966, VizieR VII/21

## Cross-identification (`OpenNGC/alias-map.json`)

The supplement→canonical alias map was prepared offline by coordinate cross-match
and **SIMBAD** verification (CDS, Strasbourg). SIMBAD is used only at build time to
*prepare* the map; it is **not** a runtime dependency — the shipped package is fully
offline. Tooling lives in the AstroPup Gallery repo under `scripts/`.
