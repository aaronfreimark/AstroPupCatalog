#!/usr/bin/env python3
"""Transform the IAU-CSN named-star list into the OpenNGC-schema stars.csv.

Source: IAU Catalog of Star Names (IAU-CSN), IAU Division C WGSN
        https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt  (CC-BY 4.0)
Run:    python3 scripts/build-stars.py path/to/IAU-CSN.txt
Writes: Sources/AstroPupCatalog/Catalog/stars.csv

The file is fixed-width. Left columns (name/designation/Bayer/constellation) are
left-aligned, so sliced by position; the numeric tail (mag, HIP, HD, RA, Dec) is
right-aligned, so pulled out by regex instead.
"""
import sys, os, re

HDR = ("Name;Type;RA;Dec;Const;MajAx;MinAx;PosAng;B-Mag;V-Mag;J-Mag;H-Mag;K-Mag;"
       "SurfBr;Hubble;Pax;Pm-RA;Pm-Dec;RadVel;Redshift;Cstar U-Mag;Cstar B-Mag;"
       "Cstar V-Mag;M;NGC;IC;Cstar Names;Identifiers;Common names;NED notes;OpenNGC notes;Sources")
NCOL = len(HDR.split(";"))

def hms(deg):
    h = deg/15.0; hh=int(h); mm=int((h-hh)*60); ss=(h-hh-mm/60)*3600
    return f"{hh:02d}:{mm:02d}:{ss:05.2f}"
def dms(deg):
    s = "-" if deg<0 else "+"; a=abs(deg); dd=int(a); mm=int((a-dd)*60); ss=(a-dd-mm/60)*3600
    return f"{s}{dd:02d}:{mm:02d}:{ss:04.1f}"

def main(src):
    lines = open(src, encoding="utf-8").read().splitlines()
    data = [l for l in lines if l and not l.startswith("#") and len(l) > 60 and l[0:1].isalpha()]
    rows, skipped = [], 0
    for l in data:
        name = l[0:18].strip()
        dia  = l[18:36].strip()
        desig= l[36:49].strip()
        bayer= l[49:61]
        con  = l[61:64].strip()
        rd = re.search(r'(\d{1,3}\.\d+)\s+(-?\d{1,2}\.\d+)\s+\d{4}-\d{2}-\d{2}', l)
        if not rd:
            skipped += 1; continue
        ra, dec = hms(float(rd.group(1))), dms(float(rd.group(2)))
        mm = re.search(r'(-?\d{1,2}\.\d{1,3})\s+[A-Za-z]\b', l[64:rd.start()])
        seg = l[64:rd.start()]
        mm = re.search(r'(-?\d{1,2}\.\d{1,3})\s+[A-Za-z]\b', seg)
        vmag = mm.group(1) if mm else ""
        after = seg[mm.end():] if mm else seg          # HIP/HD sit after the band letter
        ints = re.findall(r'\b(\d{3,6})\b', after)     # (skip the WDS_J coord + 1-2 digit components)
        ids = []
        if desig and desig != "_": ids.append(desig)
        bayer = bayer.split()[0] if bayer.split() else ""
        if bayer and bayer != "_": ids.append(f"{bayer} {con}")
        if len(ints) >= 1: ids.append(f"HIP {ints[0]}")
        if len(ints) >= 2: ids.append(f"HD {ints[1]}")
        commons = [name] + ([dia] if dia and dia != name else [])
        f = [""]*NCOL
        f[0]=name; f[1]="Star"; f[2]=ra; f[3]=dec; f[4]=con; f[9]=vmag
        f[27]=",".join(ids); f[28]=",".join(commons)
        rows.append(";".join(f))
    out = os.path.join(os.path.dirname(__file__), "..", "Sources", "AstroPupCatalog", "Catalog", "stars.csv")
    open(out, "w", encoding="utf-8").write(HDR + "\n" + "\n".join(rows) + "\n")
    print(f"wrote {len(rows)} stars  (skipped {skipped})")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "/tmp/iau-csn.txt")
