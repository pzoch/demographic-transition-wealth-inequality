"""Bootstrap the three MvD_1 frozen-data snapshots without Stata's dbnomics.

Downloads three series from the dbnomics REST API, applies HP filter + 5-year
collapse (same parameters MvD_1_macro.do uses), and writes Stata .dta files to
outputs_stata_code/data/. These .dta files are what MvD_1_macro.do reads when
$download_data=0 (the repo default).

Why a Python bootstrap: the dbnomics Stata package (`capture dbnomics import`)
fails to compile on some Stata 16 installs (Mata errors on `urlencode()` and
return statements, even after `ssc install libjson; ssc install moremata`).
The REST API is the same underlying data source; the processing math is
identical (HP-filter with Ravn-Uhlig lambda=1600).

Usage (from the sandbox root):
    python tools/bootstrap_mvd_data.py

Requires: pandas, statsmodels, pyreadstat, requests (pip install ...).
Produces: outputs_stata_code/data/{irr_data,benefits_cbo,avghours_data}.dta

Equivalent Stata blocks reproduced here (with line numbers from
outputs_stata_code/MvD_1_macro.do):
    irr:      lines 9-19   (GGDC penn10/irr.USA)
    benefits: lines 37-49  (CBO 51134-MO/SS.PGDP)
    avghours: lines 85-117 (OECD WAP x GGDC avh, emp)
"""
from __future__ import annotations

import os
import requests
import pandas as pd
import numpy as np
from statsmodels.tsa.filters.hp_filter import hpfilter


SANDBOX = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(SANDBOX, 'outputs_stata_code', 'data')


def fetch_series(provider: str, dataset: str, series: str) -> pd.DataFrame:
    url = f"https://api.db.nomics.world/v22/series/{provider}/{dataset}/{series}?observations=1"
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    s = r.json()['series']['docs'][0]
    df = pd.DataFrame({'period': s['period'], 'value': s['value']})
    df['period'] = pd.to_numeric(df['period'])
    return df


def build_irr():
    """Replicate MvD_1_macro.do lines 9-19."""
    df = fetch_series('GGDC', 'penn10', 'irr.USA').rename(columns={'period': 'year', 'value': 'irr_data'})
    df = df.dropna(subset=['irr_data']).sort_values('year').reset_index(drop=True)
    _cycle, trend = hpfilter(df['irr_data'], lamb=1600)
    df['irr_data'] = trend * 100
    df['fiveyear'] = (df['year'] // 5 * 5).astype(np.int32)
    out = df.groupby('fiveyear', as_index=False).agg(irr_data=('irr_data', 'mean'), year=('year', 'first'))
    out = out[['fiveyear', 'irr_data', 'year']]
    out['fiveyear'] = out['fiveyear'].astype(np.int32)
    out['year'] = out['year'].astype(np.int32)
    return out


def build_benefits():
    """Replicate MvD_1_macro.do lines 37-49 (periods window 1950-2020)."""
    df = fetch_series('CBO', '51134-MO', 'SS.PGDP').rename(columns={'period': 'year', 'value': 'benefits_data'})
    df.loc[df['year'] == 1962, 'year'] = 1960
    df = df[(df['year'] >= 1950) & (df['year'] <= 2020)].dropna(subset=['benefits_data']).reset_index(drop=True)
    yr_min = df['year'].min()
    df['fiveyear'] = (((df['year'] - yr_min) // 5) - ((1950 - yr_min) // 5) + 1).astype(np.int32)
    out = df.groupby('fiveyear', as_index=False).agg(benefits_data=('benefits_data', 'mean'), year=('year', 'first'))
    out['source'] = 'data'
    out['year'] = out['year'].astype(np.int32)
    return out


def build_avghours():
    """Replicate MvD_1_macro.do lines 85-117 (OECD WAP x GGDC avh, emp)."""
    wap = fetch_series('OECD', 'DSD_POPULATION@DF_POP_HIST', 'USA.POP.PS._T.Y20T64.H')
    wap = wap.rename(columns={'period': 'year', 'value': 'wap'})
    wap['wap'] = wap['wap'] / 1_000_000
    avh = fetch_series('GGDC', 'penn10', 'avh.USA').rename(columns={'period': 'year', 'value': 'avh'})
    emp = fetch_series('GGDC', 'penn10', 'emp.USA').rename(columns={'period': 'year', 'value': 'emp'})
    penn = avh.merge(emp, on='year', how='inner')
    penn['tothours'] = penn['emp'] * penn['avh']
    df = penn.merge(wap, on='year', how='inner')
    df['avghours_data'] = df['tothours'] / df['wap']
    df = df[['year', 'avghours_data']].sort_values('year').reset_index(drop=True)
    df = df[(df['year'] >= 1950) & (df['year'] <= 2020)].reset_index(drop=True)
    _cycle, trend = hpfilter(df['avghours_data'], lamb=1600)
    df['avghours_data'] = trend
    ref = df.loc[(df['year'] >= 1950) & (df['year'] <= 2015), 'avghours_data'].mean()
    df['avghours_data'] = df['avghours_data'] / ref * 100
    yr_min = df['year'].min()
    df['fiveyear'] = (((df['year'] - yr_min) // 5) - ((1950 - yr_min) // 5) + 1).astype(np.int32)
    out = df.groupby('fiveyear', as_index=False).agg(avghours_data=('avghours_data', 'mean'), year=('year', 'first'))
    out['year'] = out['year'].astype(np.int32)
    return out


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, builder in [('irr_data', build_irr), ('benefits_cbo', build_benefits), ('avghours_data', build_avghours)]:
        print(f'Fetching {name}...')
        df = builder()
        path = os.path.join(OUT_DIR, f'{name}.dta')
        df.to_stata(path, write_index=False, version=117)
        print(f'  wrote {path}  shape={df.shape}')


if __name__ == '__main__':
    main()
