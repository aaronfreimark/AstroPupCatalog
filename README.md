# AstroPupCatalog

A **shared Swift package**: the single source of deep-sky-object **identity and
reference data** for the AstroPup family (Gallery, Sky, View).

It answers *"what objects exist, what are they called, how big, where — and what is
the one canonical id for each?"* such that an id minted in one app means exactly the
same object in another. It owns **identity + reference data only** — sync, transport,
and user state (favorites / already-imaged) stay in each app as lists of canonical ids.

## Status

**Phase 1 — package scaffolded and building** (extracted from AstroPup Gallery).
`swift build` + `swift test` are green.

## What's here

- `CatalogObject` — value type; **canonical `id`** in Sky's exact format (`M31`,
  `NGC 7000`, `IC 405`, native names verbatim; always a **bare designation**). Exposes
  raw fields (`rawType`, `bMag`, `vMag`, both axes, cross-ids) so apps keep their own
  parse policies.
- `OpenNGCCatalog` — loads OpenNGC core + six supplements (Sharpless/LDN/LBN/PK/Abell/vdB).
- `AliasCrossReference` + `OpenNGC/alias-map.json` — the **SIMBAD-vetted** supplement→
  canonical dedup (272 aliases), applied at load so duplicates resolve to one object.
- `CatalogResolver` — name/designation/alias → object; free-text search.

See [ATTRIBUTION.md](ATTRIBUTION.md) for data licensing (OpenNGC CC-BY-SA-4.0 +
public-domain VizieR supplements). The cross-match tooling lives in the Gallery repo
under `scripts/`.

## Build

```sh
swift build
swift test
```

## License

Swift code: **MIT** (see [LICENSE](LICENSE)). Bundled catalog data is licensed
separately — OpenNGC under CC-BY-SA-4.0 and the supplements as public-domain VizieR
catalogues; see [ATTRIBUTION.md](ATTRIBUTION.md).
