import operator
from functools import reduce

import numpy as np
import pandas as pd
from scipy.stats import t

# SECTIONS


## General


def _get_inverse_permutation(p):
    p_list = list(p)
    assert sorted(p_list) == list(range(len(p_list))), f"{p} is not a permutation"
    return np.argsort(p)


def prod(iterable):
    return reduce(operator.mul, iterable, 1)


def only(ser, lower_bound=0):
    l = pd.Series(ser).unique().tolist()
    assert lower_bound <= len(l) <= 1, l
    res = l[0] if len(l) == 1 else None
    return res


# Stat


def t_test_p_value_two_tails(z, df):
    return t.sf(abs(z), df=df) * 2


# Viz - Stat


def sig_stars(z):
    if abs(z) > 2.58:
        return "*" * 3
    elif abs(z) > 1.96:
        return "*" * 2
    elif abs(z) > 1.68:
        return "*"
    else:
        return ""


def cohens_h_label(ch):
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


def order_cat(covariate, vals):
    bmigrps_ordered = [
        "Underweight",
        "Normal Range",
        "Overweight",
        "Obese",
    ]
    agegrps_ordered = [
        "15-19",
        "20-24",
        "25-29",
        "30-34",
        "35-39",
        "40-44",
        "45-49",
        "50-54",
        "55-59",
    ]

    def __index_of(v, lst):
        for i, l in enumerate(lst):
            if l.lower() == v.lower():
                return i
        return float("inf")

    if covariate == "bmigrp":
        return list(sorted(vals, key=lambda v: __index_of(v, bmigrps_ordered)))
    elif covariate == "agegrp":
        return list(sorted(vals, key=lambda v: __index_of(v, agegrps_ordered)))
    else:
        return list(sorted(vals))


def _ds_sign(ds, _ds, left="IeDEA"):
    assert _ds in ds
    return (-1) ** int(_ds == left)


def parse_tick_number_text(t):
    sgn = 1
    if t.startswith(chr(8722)):  # minus sign
        sgn = -1
        t = t[1:]

    return sgn * float(t)


def fmt_tick_label(x):
    return str(int(x))


def title_of(index_cols, title_pieces):
    pieces_dict = dict(zip(index_cols, title_pieces))
    cov = pieces_dict["covariate"]
    return {
        "agegrp": "Age Group",
        "bmigrp": "BMI Group",
        "marital_status": "Marital Status",
        "pregnant": "Pregnancy",
    }[cov]
