import operator
from functools import reduce

import numpy as np
import pandas as pd
from scipy.stats import t


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


def t_test_p_value_two_tails(z, df):
    return t.sf(abs(z), df=df) * 2


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
