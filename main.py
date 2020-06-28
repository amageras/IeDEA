#!/usr/bin/env python
import argparse
import sys

import matplotlib.pyplot as plt
import openpyxl

from util import get_inverse_permutation, pp_grid, process_wb_df, prod, wb_to_df

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


def _df_wb_proc_to_charts(
    df_wb_proc, grid_shape, idx_level_sort_precedence, figsize=(20, 20), debug=False
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
    idx_level_sort_inv = get_inverse_permutation(idx_level_sort_precedence)
    ordered_index = (
        df_wb_proc_idx.reorder_levels(idx_level_sort_precedence)
        .sort_index()
        .reorder_levels(idx_level_sort_inv)
        .index.unique()
        .to_series()
    )
    df_wb_proc_idx.groupby(INDEX).apply(
        lambda df: pp_grid(df, fig, axes[0], DS, INDEX, ordered_index, debug=debug)
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
    # sort the grid (row major order) by
    # "pregnant_controlling",
    # then "section_var_name",
    # then "section"
    # then "covariate"

    precedence = [
        "country",
        "knows_status",
        "section",
        "pregnant_controlling",        
        "covariate",
        "year",
        "section_var_name",
    ]
    idx_level_sort_precedence = [INDEX.index(pr) for pr in precedence]

    grid_shape = (3, 2)
    figsize = (20, 20)

    fig = _df_wb_proc_to_charts(
        df_wb_proc,
        grid_shape,
        idx_level_sort_precedence,
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
