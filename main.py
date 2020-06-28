#!/usr/bin/env python
import argparse
import itertools
import operator
import re
import sys

import matplotlib.pyplot as plt
import numpy as np
import openpyxl
import pandas as pd
import seaborn as sns
from matplotlib.patches import Patch

from util import (_ds_sign, _get_inverse_permutation, cohens_h_label,
                  fmt_tick_label, only, order_cat, parse_tick_number_text,
                  prod, sig_stars, t_test_p_value_two_tails, title_of)

DS = ["IeDEA", "DHS"]
INDEX = ["pregnant_controlling", "section_var_name", "section", "covariate"]


def crosstab_sheet_to_df(
    sheet, section_var_name="domain", controlling_for_aside_from_dataset=None
):
    assert controlling_for_aside_from_dataset in [
        "pregnant",
        None,
    ], "currently can only control for pregnant"
    assert section_var_name == "domain", "TODO: refactor. This is conceptually simpler"
    out = []
    v = list(sheet.values)[2:]

    table_of = v[0][0]
    section_var_name, covariate = re.search(r"(\w+) by (\w+)", table_of).groups()
    controlling_for = v[1][0]
    m_dataset = re.search(r"dataset=([^ ]*)", controlling_for)
    dataset = m_dataset.groups()[0]
    m_pregnant_controlling = re.search(r"pregnant=(\w*)", controlling_for)
    pregnant_controlling = (
        m_pregnant_controlling.groups()[0].strip()
        if m_pregnant_controlling is not None
        else "N/A"
    )
    df_raw = pd.DataFrame(v[3:], columns=v[2])
    section = None
    for _, row in df_raw.iterrows():
        rd = row.to_dict()
        if rd[section_var_name]:
            section = rd[section_var_name]
        else:
            rd[section_var_name] = section

        out.append(pd.Series(rd))

    df_out = pd.DataFrame(out).rename(columns={section_var_name: "section"})
    df_out["covariate"] = covariate
    df_out["dataset"] = dataset
    df_out["pregnant_controlling"] = pregnant_controlling
    df_out["section_var_name"] = section_var_name
    return df_out.rename(columns={covariate: "level"})


def crosstab_df_clean(df_crosstab):
    Ns = {}
    for _, row in df_crosstab.iterrows():
        if row["level"] == "Total":
            Ns[row["section"]] = row["Frequency"]

    df_out = pd.DataFrame(df_crosstab)
    df_out["N"] = df_crosstab.apply(lambda r: Ns[r["section"]], axis=1)
    return (
        df_crosstab[["dataset"] + INDEX + ["level", "Row\nPercent", "N"]]
        .rename(columns={"Row\nPercent": "Row_Percent"})
        .replace(".", 0)
    )


def wb_to_df(wb):
    dfs_clean = []
    for sn in wb.sheetnames:
        if "crosstab" in sn.lower():
            sheet = wb[sn]
            df_sheet = crosstab_sheet_to_df(sheet)
            df_sheet_clean = crosstab_df_clean(df_sheet)
            df_sheet_clean["sheet_name"] = sn
            dfs_clean.append(df_sheet_clean)

    dfc = pd.concat(dfs_clean)

    # filters - special cases where data is bad
    dfc = dfc[dfc.section != "Total"]
    filters = [
        # missing data
        ~(
            (dfc.section_var_name == "pregnant")
            & (dfc.section == "Yes")
            & (dfc.covariate == "bmigrp")
        ),
        # dont care about them
        (~dfc.section.str.contains("HIV Negative")),
        ~(dfc.pregnant_controlling == "Yes"),
        ~(
            (dfc.section.str.lower().str.contains("men"))
            & (dfc.covariate == "pregnant")
        ),
    ]
    mask = pd.concat(filters, axis=1).all(axis=1)
    return dfc[mask]


def process_wb_df(df, values, ds):
    df_piv = df.pivot_table(
        index=INDEX + ["level"], columns=["dataset"], values=values, aggfunc=only
    )
    df_piv.columns = ["_".join(col).strip() for col in df_piv.columns.values]
    df_dropped = df_piv.dropna(
        subset=[
            f"{val}_{ds}" for val, ds in itertools.product(values, ["IeDEA", "DHS"])
        ]
    )

    n_sum = df_dropped.reset_index().groupby(INDEX)[[f"N_{_ds}" for _ds in ds]].sum()
    neq0 = (n_sum != 0).all(axis=1)
    neq0_idx = neq0[neq0].index
    df_dropped = df_dropped.reset_index().set_index(INDEX).loc[neq0_idx].reset_index()

    for _ds in ds:
        df_dropped[f"proportion_{_ds}"] = df_dropped[f"Row_Percent_{_ds}"] / 100

    df_dropped["N_total"] = sum(df_dropped[f"N_{_ds}"] for _ds in ds)
    df_dropped["p_hat"] = (
        sum(df_dropped[f"proportion_{_ds}"] * df_dropped[f"N_{_ds}"] for _ds in ds)
        / df_dropped["N_total"]
    )

    df_dropped["q_hat"] = 1 - df_dropped["p_hat"]
    df_dropped["stderr"] = np.sqrt(
        df_dropped["p_hat"]
        * df_dropped["q_hat"]
        * df_dropped["N_total"]
        / (df_dropped[f"N_{ds[0]}"] * df_dropped[f"N_{ds[1]}"])
    )
    df_dropped["z_value"] = (
        df_dropped["proportion_IeDEA"] - df_dropped["proportion_DHS"]
    ) / df_dropped["stderr"]
    df_dropped["p_value"] = t_test_p_value_two_tails(
        df_dropped["z_value"], df_dropped["N_IeDEA"] - 1
    )
    df_dropped["p_value_round"] = df_dropped["p_value"].round(4)
    df_dropped["significance_label"] = df_dropped["z_value"].apply(sig_stars)
    df_dropped["cohens_h"] = (
        2 * np.arcsin(np.sqrt(df_dropped["proportion_IeDEA"]))
    ) - (2 * np.arcsin(np.sqrt(df_dropped["proportion_DHS"])))

    df_dropped["cohens_h_label"] = df_dropped["cohens_h"].apply(cohens_h_label)
    df_dropped["plot_label"] = df_dropped.apply(
        lambda r: " ".join([r["cohens_h_label"], r["significance_label"]]), axis=1
    )
    return df_dropped


def _get_barplots(df_plot_filt, covariate, ds, colors, ax):
    order_of_bars = order_cat(covariate, df_plot_filt["level"].unique())
    bps = []
    for _ds, c in zip(ds, colors):
        x_col = f"Row_Percent_{_ds}"
        _df = df_plot_filt[[x_col, "level", "plot_label"]]
        sgn = _ds_sign(ds, _ds)
        _df[x_col] = sgn * _df[x_col]

        bp = sns.barplot(
            x=x_col, y="level", data=_df, order=order_of_bars, color=c, ax=ax
        )
        if sgn == 1:
            for idx_vals, p in zip(_df.iterrows(), bp.patches):
                _, vals = idx_vals
                # print(p.get_y(), p.get_x(), p.get_height())
                bp.text(
                    10,
                    p.get_y() + 0.5,
                    vals["plot_label"],
                    ha="center",
                    color="black",
                    fontsize=20,
                )
        bps.append(bp)
    return bps


def pp(df, ds, fig, ax):
    assert len(ds) == 2
    assert len(df.index.unique()) == 1, "pp: expected a unique index value"
    cov_lvl = INDEX.index("covariate")
    covariate = only(df.index.get_level_values(cov_lvl), lower_bound=1)
    title_pieces = df.reset_index()[INDEX].loc[0].tolist()
    df = df.reset_index().query("level != 'Total'")

    plot_mask = (df[[f"Row_Percent_{_ds}" for _ds in ds]] != 0).any(axis=1)
    df_plot_filt = df[plot_mask]
    if len(df_plot_filt) == 0:
        return False
    colors = ["gray", "lightgrey"]

    bps = _get_barplots(df_plot_filt, covariate, ds, colors, ax)

    ax.set_xlabel("Percent")
    ax.set_ylabel("Level")
    ax.set_title(title_of(INDEX, title_pieces), fontsize=22)
    ax.legend(handles=[Patch(facecolor=c, label=_ds) for _ds, c in zip(ds, colors)])

    fig.canvas.draw()
    fig.show()
    for bp in bps:
        xtl = bp.xaxis.get_ticklabels()
        xtl2 = [fmt_tick_label(abs(parse_tick_number_text(t.get_text()))) for t in xtl]
        bp.set_xticklabels(xtl2)

    return True


def _get_axis_key(index, ordered_index):
    """
    index: index with levels as in INDEX, with a single unique value
    ordered_index as expected in `pp_grid()`
    """
    idx_value = only(index.to_series(), lower_bound=1)
    ordered_list = ordered_index.tolist()
    try:
        return ordered_list.index(idx_value)
    except ValueError:
        sys.stderr.write(f"{idx_value}\nNOT FOUND IN\n{ordered_list}\n")
        return -1


def pp_grid(grp, fig, axes, ordered_index):
    """
    grp: dataframe whose index is like `index` in `_get_axis_key()`
    axes: 1-d array in row-major order
    ordered_index: ordered array of tuples where
        each element is an instance of INDEX
    """
    ax_key = _get_axis_key(grp.index, ordered_index)
    ax = axes[ax_key]
    return pp(grp, DS, fig, ax)


def _df_wb_proc_to_charts(
    df_wb_proc, grid_shape, idx_level_sort_precedence, figsize=(20, 20)
):
    fig, axes = plt.subplots(*grid_shape, figsize=(20, 20))
    axes = axes.reshape((1, prod(grid_shape)))
    df_wb_proc_idx = df_wb_proc.set_index(INDEX)
    idx_level_sort_inv = _get_inverse_permutation(idx_level_sort_precedence)
    ordered_index = (
        df_wb_proc_idx.reorder_levels([0, 1, 3, 2])
        .sort_index()
        .reorder_levels(idx_level_sort_inv)
        .index.unique()
        .to_series()
    )
    df_wb_proc_idx.groupby(INDEX).apply(
        lambda df: pp_grid(df, fig, axes[0], ordered_index)
    )
    fig.tight_layout(pad=4)
    return fig


def _xl_to_charts(args):
    wb = openpyxl.load_workbook(args.wb_path)
    df_wb = wb_to_df(wb)

    value_cols = ["Row_Percent", "N", "sheet_name"]
    df_wb_proc = process_wb_df(df_wb, value_cols, DS).reset_index(drop=True)
    # sort the grid (row major order) by
    # "pregnant_controlling",
    # then "section_var_name",
    # then "section"
    # then "covariate"
    idx_level_sort_precedence = [0, 1, 3, 2]

    grid_shape = (3, 2)
    figsize = (20, 20)

    fig = _df_wb_proc_to_charts(
        df_wb_proc, grid_shape, idx_level_sort_precedence, figsize=figsize
    )
    return fig


def main():
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument("wb_path", type=str, help="file path for excel workbook")
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
