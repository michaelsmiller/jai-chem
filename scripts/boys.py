#!/usr/bin/env python

# kummer confluent hypergeometric function
from scipy.special import hyp1f1 as hyper
import numpy as np

# Prevents line breaks from being inserted
np.set_printoptions(linewidth=np.nan)

def boys(n : int | float, t: float):
    n = float(n)
    # This is an analytic formula for the boys function
    return hyper(n+0.5,n+1.5,-t)/(2.0*n+1.0)

def main():
    max_n = 5

    t1 = 0.0
    t2 = 20.0
    dt = 0.107
    T = np.arange(t1, t2, dt)
    N = np.arange(0, max_n+1, 1)
    B = np.zeros((T.shape[0], N.shape[0]))

    for iteration, t in enumerate(T):
        for i_n, n in enumerate(N):
            B[iteration, i_n] = boys(n, t)

    print(f"# Boys function F(n, t) evaluated for all n <= {max_n} over [{t1}, {t2}) in intervals of {dt}")
    print(f"# Format: 't F(0, t) F(1, t) ... F(max_n, t)'")
    print(f"{B.shape[0]} {B.shape[1] + 1}")
    for i, t in enumerate(T):
        bi = B[i, :]
        values_string = np.array2string(bi, precision=15, separator=" ", floatmode="maxprec")
        values_string = values_string.strip("[").strip("]")
        line = f"{T[i]} {values_string}"
        print(line)


if __name__ == "__main__":
    main()
