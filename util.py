import itertools
import operator
import re
import sys
from functools import reduce

import numpy as np
import pandas as pd
import seaborn as sns
from scipy.stats import t

# SECTIONS


# constants
CAT_ORDERS = {
    "bmigrp": [
        "Underweight",
        "Normal",
        "Overweight",
        "Obese",
    ],
    "agegrp": [
        "15-19",
        "20-24",
        "25-29",
        "30-34",
        "35-39",
        "40-44",
        "45-49",
        "50-54",
        "55-59",
    ],
    "marital_status":  [
        "Married",
        "Divorced",
        "Widowed",
        "Single",
    ]
}

# types


class SASParseException(Exception):
    pass


# General


def _pad(string, length):
    return string + " " * max(0, length - len(string))


def prod(iterable):
    return reduce(operator.mul, iterable, 1)


def only(ser, lower_bound=0):
    lst = pd.Series(ser).unique().tolist()
    assert lower_bound <= len(lst) <= 1, lst
    res = lst[0] if len(lst) == 1 else None
    return res


def _assert_one_to_one(s1, s2):
    dct = dict(zip(s1, s2))
    assert len(set(dct.keys())) == len(
        set(dct.values())), f"1:1{s1},{s2},{dct}"


# Stat


def t_test_p_value_two_tails(z, df):
    return t.sf(abs(z), df=df) * 2


# Viz - Stat


def _sig_stars(z):
    if abs(z) > 2.58:
        return "*" * 2
    elif abs(z) > 1.96:
        return "*"
    else:
        return ""


def _cohens_h_label(ch):
    if abs(ch) < 0.3:
        return "S"
    elif abs(ch) < 0.4:
        return "S-M"
    elif abs(ch) < 0.6:
        return "M"
    elif abs(ch) < 0.7:
        return "M-L"
    else:
        return "L"


# Viz - General


def _order_cat(covariate, vals):
    def __index_of(v, lst):
        for i, l in enumerate(lst):
            if l.lower() == v.lower():
                return i
        return float("inf")

    if covariate in CAT_ORDERS:
        ordered = CAT_ORDERS[covariate]
        return list(sorted(vals, key=lambda v: __index_of(v, ordered)))
    else:
        return list(sorted(vals))


def _ds_sign(ds, _ds, left="IeDEA"):
    assert _ds in ds
    return (-1) ** int(_ds == left)


def _parse_tick_number_text(t):
    sgn = 1
    # minus sign. '−'. NOT hyphen.
    if t.startswith(chr(8722)):
        sgn = -1
        t = t[1:]

    return sgn * float(t)


def _fmt_tick_label(x):
    return str(int(x))


def _fmt_pct(pct_float):
    int_s = str(int(round(pct_float, 0)))
    return f"{int_s}%"


def _title_of(index_cols, title_pieces, debug=False):
    pieces_dict = dict(zip(index_cols, title_pieces))
    if debug:
        return "\n".join(map(str, pieces_dict.items()))

    cov = pieces_dict["covariate"]
    cov_display = {
        "agegrp": "Age Group",
        "bmigrp": "BMI Group",
        "marital_status": "Marital Status",
        "pregnant": "Pregnancy",
    }[cov]

    dom = pieces_dict["section"]
    dom_display = re.search(r"(\w*[mM]en)", dom).groups()[0]
    year = pieces_dict["year"]
    return f"{cov_display} ({dom_display}, {year})"


def _clean_levels(value):
    return value.split()[0]


def _get_bar_label_x(pct_value, sgn, l_text):
    return 5 * sgn - 5
    if sgn == 1:
        if pct_value < 10:
            return pct_value - 3
        else:
            return pct_value * 0.9
    else:
        return pct_value + 1


def _get_plot_label_x_axes_coords(sgn):
    return 0.5 - sgn * 0.1


def _pct_pad(pct):
    if isinstance(pct, str):
        pct = pct.strip("%")
        return 3 - len(pct)
    else:
        if pct == 100:
            return 0
        elif pct >= 10:
            return 1
        else:
            return 2


def _get_barplots(df_plot_filt, covariate, ds, colors, label_space, ax):
    df_plot_filt = df_plot_filt.copy()

    order_of_bars = _order_cat(covariate, df_plot_filt["level"].unique())

    bps = []
    for _ds, c in zip(ds, colors):
        x_col = f"Row_Percent_{_ds}"
        _df = df_plot_filt[[x_col, "level", "plot_label"]]
        sgn = _ds_sign(ds, _ds)
        _df[x_col] = sgn * _df[x_col]

        bp = sns.barplot(
            x=x_col, y="level", data=_df, order=order_of_bars, color=c, ax=ax
        )
        max_abs_lim = max([abs(lim) for lim in bp.get_xlim()])
        bp.set_xlim((-max_abs_lim, max_abs_lim))
        bps.append(bp)

    for _ds, bp in zip(ds, bps):
        x_col = f"Row_Percent_{_ds}"
        _plot_label_x_tnsf, _ = bp.transData.inverted().transform(
            bp.transAxes.transform([_get_plot_label_x_axes_coords(sgn), 0])
        )
        _df = df_plot_filt[[x_col, "level", "plot_label"]]
        sgn = _ds_sign(ds, _ds)
        if sgn == 1:
            for idx, val in _df.iterrows():
                pct = _fmt_pct(val[x_col])
                i = order_of_bars.index(val["level"])
                label = pct + (
                    " " * (label_space + _pct_pad(pct))
                ) + val["plot_label"]
                bp.text(
                    _plot_label_x_tnsf,
                    i + 0.15,
                    label,
                    fontdict={"size": 16,
                              "family": "monospace", "weight": "bold"}
                )
        else:
            for idx, val in _df.iterrows():
                i = order_of_bars.index(val["level"])
                pct = _fmt_pct(val[x_col])
                label = pct
                bp.text(
                    _plot_label_x_tnsf,
                    i + 0.15,
                    label,
                    ha="right",
                    fontdict={"size": 16,
                              "family": "monospace", "weight": "bold"}
                )

    return bps


def _get_axis_key(index, ordered_index):
    """
    index: index with levels as in INDEX, with a single unique value
    ordered_index as expected in `pp_grid()`
    """
    idx_value = only(index.to_series(), lower_bound=1)
    ordered_list = list(ordered_index)
    try:
        return ordered_list.index(idx_value)
    except ValueError:
        sys.stderr.write(f"{idx_value}\nNOT FOUND IN\n{ordered_list}\n")
        return -1


def _get_formatted_tick_label(raw_tick_label):
    return _fmt_tick_label(abs(_parse_tick_number_text(t.get_text())))


def _pp(df, ds, colors, index_cols, fig, ax, debug=False, ylabel=None,
        label_space=10):
    assert len(ds) == 2
    assert len(df.index.unique()) == 1, "pp: expected a unique index value"
    cov_lvl = index_cols.index("covariate")
    covariate = only(df.index.get_level_values(cov_lvl), lower_bound=1)
    title_pieces = df.reset_index()[index_cols].loc[0].tolist()
    df = df.reset_index().query("level != 'Total'")

    plot_mask = (df[[f"Row_Percent_{_ds}" for _ds in ds]] != 0).any(axis=1)
    df_plot_filt = df[plot_mask]
    if len(df_plot_filt) == 0:
        return False

    bps = _get_barplots(df_plot_filt, covariate, ds, colors, label_space, ax)

    ax.set_xlabel("", fontsize=20)
    _ylabel = ylabel if ylabel is not None else covariate
    ax.set_ylabel(_ylabel, fontsize=20)
    ax.set_title(_title_of(index_cols, title_pieces, debug=debug), fontsize=20)

    fig.canvas.draw()
    fig.show()
    for bp in bps:
        xtl = bp.xaxis.get_ticklabels()
        xtl2 = [""] * len(xtl)
        bp.set_xticklabels(xtl2)

    return True


def pp_grid(grp, fig, axes, ds, colors, index_cols, ordered_index, debug=False,
            ylabel=None, label_space=10):
    """
    grp: dataframe whose index is like `index` in `_get_axis_key()`
    axes: 1-d array in row-major order
    ordered_index: ordered array of tuples where
        each element is an instance of INDEX

    return: if plotting to the axis is successful, the key (index into array) for the axis.
            Otherwise -1
    """
    ax_key = _get_axis_key(grp.index, ordered_index)
    ax = axes[ax_key]
    res = _pp(
        grp, ds, colors, index_cols, fig, ax, debug=debug, ylabel=ylabel,
        label_space=label_space
    )
    if res:
        return ax_key
    else:
        return -1


# Data Processing


def _parse_crosstab_preproc(sheet, country_knows_status_year):
    v = list(sheet.values)
    if country_knows_status_year is None:
        country, year, knows_status = [_v.strip()
                                       for _v in v[0][0].split()][:3]
        return country, knows_status, year, v[4:]
    else:
        country, knows_status, year = country_knows_status_year
        return country, knows_status, year, v[2:]


def _parse_crosstab_sheet_values(sheet, country_knows_status_year):
    country, knows_status, year, v = _parse_crosstab_preproc(
        sheet, country_knows_status_year
    )
    table_of = v[0][0]
    m_svnc = re.search(r"(\w+) by (\w+)", table_of)
    if m_svnc is None or len(m_svnc.groups()) != 2:
        raise SASParseException(
            "couldnt match section_var_name and covariate from crosstab sheet"
        )

    section_var_name, covariate = m_svnc.groups()
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

    return (
        country,
        knows_status,
        year,
        section_var_name,
        covariate,
        dataset,
        pregnant_controlling,
        df_raw,
    )


def _crosstab_sheet_to_df(
    sheet, controlling_for_aside_from_dataset=None,
    country_knows_status_year=None,
):
    """
        country_knows_status_year: a triple like
          (country, knows_status, year) or None
          if tuple, like ("Burundi", "All", 2011)
    """
    assert controlling_for_aside_from_dataset in [
        "pregnant",
        None,
    ], "currently can only control for pregnant"
    (
        country,
        knows_status,
        year,
        section_var_name,
        covariate,
        dataset,
        pregnant_controlling,
        df_raw,
    ) = _parse_crosstab_sheet_values(sheet, country_knows_status_year)
    assert (
        section_var_name == "domain"
    ), f"TODO: refactor. This is conceptually simpler {section_var_name}"

    out = []
    section = None
    for _, row in df_raw.iterrows():
        rd = row.to_dict()
        if rd[section_var_name]:
            section = rd[section_var_name]
        else:
            rd[section_var_name] = section

        out.append(pd.Series(rd))

    df_out = pd.DataFrame(out).rename(columns={section_var_name: "section"})
    df_out["country"] = country
    df_out["year"] = year
    df_out["knows_status"] = knows_status
    df_out["covariate"] = covariate
    df_out["dataset"] = dataset
    df_out["pregnant_controlling"] = pregnant_controlling
    df_out["section_var_name"] = section_var_name
    return df_out.rename(columns={covariate: "level"})


def _crosstab_df_clean(df_crosstab, index_cols):
    Ns = {}
    for _, row in df_crosstab.iterrows():
        if row["level"] == "Total":
            Ns[row["section"]] = row["Frequency"]

    df_out = pd.DataFrame(df_crosstab)
    df_out["N"] = df_crosstab.apply(lambda r: Ns[r["section"]], axis=1)
    _cleaned_levels = df_out["level"].apply(_clean_levels)
    _assert_one_to_one(df_out["level"], _cleaned_levels)
    df_out["level"] = _cleaned_levels
    return (
        df_crosstab[["dataset"] + index_cols + ["level", "Row\nPercent", "N"]]
        .rename(columns={"Row\nPercent": "Row_Percent"})
        .replace(".", 0)
    )


def wb_to_df(wb, index_cols, country_knows_status_year=None):
    dfs_clean = []
    for sn in wb.sheetnames:
        if "crosstab" in sn.lower():
            sheet = wb[sn]
            df_sheet = _crosstab_sheet_to_df(
                sheet, country_knows_status_year=country_knows_status_year
            )
            df_sheet_clean = _crosstab_df_clean(df_sheet, index_cols)
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
        # if covariate = pregnant, section contains women
        # = (section contains women or covariate != pregnant)
        (
            (dfc.section.str.lower().str.contains("women"))
            | (dfc.covariate != "pregnant")
        ),
    ]
    mask = pd.concat(filters, axis=1).all(axis=1)
    return dfc[mask]


def _get_padded_label(cohens_h_label, significance_label):
    return _pad(
        f"{cohens_h_label}{significance_label}", 5
    )


def process_wb_df(df, values, ds, index_cols):
    df_piv = df.pivot_table(
        index=index_cols + ["level"], columns=["dataset"], values=values,
        aggfunc=only
    )
    df_piv.columns = ["_".join(col).strip() for col in df_piv.columns.values]
    df_dropped = df_piv.dropna(
        subset=[
            f"{val}_{ds}" for val, ds in
            itertools.product(values, ["IeDEA", "DHS"])
        ]
    )

    n_sum = (
        df_dropped.reset_index().groupby(index_cols)[
            [f"N_{_ds}" for _ds in ds]].sum()
    )
    neq0 = (n_sum != 0).all(axis=1)
    neq0_idx = neq0[neq0].index
    df_dropped = (
        df_dropped.reset_index().set_index(
            index_cols).loc[neq0_idx].reset_index()
    )

    for _ds in ds:
        df_dropped[f"proportion_{_ds}"] = \
            df_dropped[f"Row_Percent_{_ds}"] / 100

    df_dropped["N_total"] = sum(df_dropped[f"N_{_ds}"] for _ds in ds)
    df_dropped["p_hat"] = (
        sum(df_dropped[f"proportion_{_ds}"] *
            df_dropped[f"N_{_ds}"] for _ds in ds)
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
    df_dropped["significance_label"] = df_dropped["z_value"].apply(_sig_stars)
    df_dropped["cohens_h"] = (
        2 * np.arcsin(np.sqrt(df_dropped["proportion_IeDEA"]))
    ) - (2 * np.arcsin(np.sqrt(df_dropped["proportion_DHS"])))

    df_dropped["cohens_h_label"] = df_dropped["cohens_h"].apply(
        _cohens_h_label)
    df_dropped["plot_label"] = df_dropped.apply(
        lambda r: _get_padded_label(
            r["cohens_h_label"], r["significance_label"]
        ),
        axis=1
    )
    return df_dropped
