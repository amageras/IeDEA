#!/usr/bin/env python
import argparse
import sys

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import openpyxl

from util import pp_grid, process_wb_df, prod, wb_to_df

DS = ["IeDEA", "DHS"]
INDEX = [
    "country",
    "knows_status",
    "year",
    "pregnant_controlling",
    "section_var_name",
    "section",
    "covariate",
]

CUSTOM_ORDER = {"covariate": ["agegrp", "marital_status", "bmigrp", "pregnant"]}


def _get_supplemented_grid_order(
    pd_idx, index_cols, years, precedence
):
    year_idx = index_cols.index("year")
    prec_idxs = [index_cols.index(c) for c in precedence]
    def __replace(val, col):
        if col in CUSTOM_ORDER:
            if val in CUSTOM_ORDER[col]:
                return CUSTOM_ORDER[col].index(val)
            else:
                return val
        else:
            return val

    def __key(t):
        k_raw = [__replace(t[i], index_cols[i]) for i in prec_idxs]
        return tuple(k_raw)

    out_unordered = []
    for tup_in in set(pd_idx):
        for yr in years:
            l = list(tup_in[:year_idx]) + [yr] + list(tup_in[year_idx + 1:])
            out_unordered.append(tuple(l))
    out = list(sorted(out_unordered, key=__key))
    return out


def _df_wb_proc_to_charts(
    df_wb_proc,
    grid_shape,
    precedence,
    years,
    figsize=(20, 20),
    debug=False,
):
    """
    rule: 
      group and sort by country, then knows status (1 page per value)
        (order doesn't matter)
      for each country and knows status, group and sort by domain, then covariate
        Men first, [agegrp, marital_status, bmigrp, pregnancy]
      for each page, domain, and covariate (i.e. for each row)
        insert any missing years as blanks then sort by year

    """
    fig, axes = plt.subplots(*grid_shape, figsize=figsize)
    axes = axes.reshape((1, prod(grid_shape)))
    df_wb_proc_idx = df_wb_proc.set_index(INDEX)

    grid_order = _get_supplemented_grid_order(
        df_wb_proc_idx.index, INDEX, years, precedence
    )
    df_wb_proc_idx.groupby(INDEX).apply(
        lambda df: pp_grid(df, fig, axes[0], DS, INDEX, grid_order, debug=debug)
    )
    fig.tight_layout(pad=4)
    return fig


def _xl_to_charts(args):
    def __parse_cksy(cyks_raw):
        if cyks_raw:
            parts = [p.strip() for p in cyks_raw.split(",")]
            assert len(parts) == 3
            return tuple(parts)
        else:
            return None

    wb = openpyxl.load_workbook(args.wb_path)
    country_knows_status_year = __parse_cksy(args.country_knows_status_year)
    df_wb = wb_to_df(wb, INDEX, country_knows_status_year=country_knows_status_year)

    value_cols = ["Row_Percent", "N", "sheet_name"]
    df_wb_proc = process_wb_df(df_wb, value_cols, DS, INDEX).reset_index(drop=True)
    precedence = [
        "country",
        "knows_status",
        "section",
        "covariate",
        "year",
        "pregnant_controlling",
        "section_var_name",
    ]
    row_key_cols = [
        "country",
        "knows_status",
        "section_var_name",
        "section",
        "covariate",
        "pregnant_controlling",
    ]
    n_rows = len(df_wb_proc.groupby(row_key_cols))
    years = sorted(df_wb_proc["year"].unique().tolist())
    grid_shape = (n_rows, len(years))
    figsize = (20, 20)

    fig = _df_wb_proc_to_charts(
        df_wb_proc,
        grid_shape,
        precedence,
        years,
        figsize=figsize,
        debug=args.debug,
    )
    return fig


def main():
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument("wb_path", type=str, help="file path for excel workbook")
    parser.add_argument(
        "--debug", action="store_true",
    )
    parser.add_argument(
        "--country_knows_status_year",
        "--cksy",
        type=str,
        default=None,
        help="optional comma-separated value like 'Burundi,All,2011'",
    )
    subparsers = parser.add_subparsers(help="how to do output", dest="sub_cmd")
    subparsers.required = True
    parser_save = subparsers.add_parser("save", help="write png")
    parser_save.add_argument("output_file", type=str, help="image file to write")
    _ = subparsers.add_parser("interactive", help="just plt.show()")
    args = parser.parse_args()
    fig = _xl_to_charts(args)
    if args.sub_cmd == "save":
        fig.savefig(args.output_file)
    elif args.sub_cmd == "interactive":
        plt.show()
    else:
        sys.stderr.write(f"invalid sub_cmd: {args.sub_cmd}")
        return 1
    return 0


if __name__ == "__main__":
    res = main()
    sys.exit(res)
