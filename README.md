# FTOOLS: Fast Stata commands for large datasets

**ftools** is two things:

1. A Mata called *Factor* that creates identifiers ("factors") from a set of variables or vectors. It is very fast for big datasets because it avoids sorting the data.
2. A list of Stata commands that exploit the *Factor* class,
providing alternatives to common commands such as collapse,
contract, egen group, sort, levelsof, etc.

# Usage

```stata
* Stata usage:
sysuse auto

fsort turn
fegen id = group(turn trunk)
fcollapse (sum) price (mean) gear, by(turn foreign) freq

* Advanced: creating the .mlib library:
ftools compile

* Mata usage:
sysuse auto, clear
mata: F = factor("turn")
mata: F.keys, F.counts
mata: sorted_price = F.sort(st_data(., "price"))
```

Other features include:

- Add your own functions to -fcollapse-
- View the levels of each variable with `mata: F.keys`
- Embed -factor()- into your own Mata program. For this, you can
  use `F.sort()` and the built-in `panelsubmatrix()`.

# Benchmarks

(see the *test* folder for the details of the tests and benchmarks)

## egen group

Given a dataset with 20 million obs. and 5 variables, we create the following variable, and create IDs based on that:

```stata
gen long x = ceil(uniform()*5000)
```

Then, we compare five different variants of egen group:

| Method               | Min    | Avg    |
|----------------------|--------|--------|
| egen id = group(x)           | 49.174 | 51.263 |
| fegen id = group(x)  | 1.438  | 1.532  |
| fegen id = group(x), method(hash0)      | 1.414  | 1.597  |
| fegen id = group(x), method(hash1)      | 8.868  | 9.346  |
| fegen id = group(x), method(stata)     | 34.733 | 35.43  |

Our variant takes roughly 3% of the time of egen group.
If we were to choose a more complex hash method, it would take 18% of the time.
We also report the most efficient method based in Stata (that uses `bysort`),
which is still significantly slower than our Mata approach.

Notes:

- The gap is larger in systems with two or less cores, and smaller in systems with many cores (because our approach does not take much advantage of multicore)
- The gap is larger in datasets with more observations or variables.
- The gap is larger with fewer levels

## collapse

On a dataset of similar size, we run `collapse (sum) y1-y15`:

| Method             | Avg.  |
|--------------------|-------|
| collapse           | 50.01 |
| fcollapse          | 17.45 |
| fcollapse, pool(1) | 20.47 |

We can see that `fcollapse` takes roughly a third of the time of `collapse` (although using more memory when
moving data from Stata to Mata).
Alternatively, the `pool(1)` option uses very little memory (similar to `collapse`) at also very good speeds.

Notes:

- The gap is larger if you want to collapse fewer variables
- The gap is larger if you want to collapse to fewer levels
- The gap is larger for more complex stats. (such as median)

## fsort

At this stage, you would need a significantly large dataset (50 million+) for `fsort` to be faster than `sort`.

| Method          | Avg. 1 | Avg. 2 |
|-----------------|--------|--------|
| sort id         | 62.52  | 71.15  |
| sort id, stable | 63.74  | 65.72  |
| fsort id        | 55.4   | 67.62  |

The table above shows the benchmark
on a 50 million obs. dataset.
The unstable sorting is slightly slower (col. 1) or slighlty faster (col. 2)
than the `fsort` approach. On the other hand, a stable sort is clearly
slower than `fsort` (which always produces a stable sort)

# Installation

With Stata 13+, type:

```
cap ado uninstall ftools
net install ftools, from(https://github.com/sergiocorreia/ftools/raw/master/source/)
```

For older versions, first download and extract the [zip file](https://github.com/sergiocorreia/ftools/archive/master.zip), and then run

```
ado uninstall ftools
net install ftools, from(SOME_FOLDER)
```

Where *SOME_FOLDER* is the folder that contains the *stata.toc* and related files.

## Compiling the mata library

In case of a Mata error, try typing `ftools` to create the Mata library (lftools.mlib).

## Dependencies

The `fcollapse` function requires the `moremata` package from SSC.


# FAQ:

## "What features is this missing?"

- You can create levels based on one or more variables, and on numeric or string variables, but *not* on combinations of both. Thus, you can't do something like `fcollapse price, by(make foreign)` because make is string and foreign is numeric. This is due to a limitation in Mata and is probably a hard restriction. As a workaround, just run something like `fegen id = group(make)`, to create a numeric ID.
- Support for weights is incomplete (datasets that use weights are often relatively small, so this feature has less priority)
- Some commands could also gain large speedups (merge, reshape, etc.)
- Since Mata is ~4 times slower than C, rewriting this in a C plugin should lead to a large speedup.

## "How can this be faster than existing commands?"

Existing commands (e.g. sort) are often compiled and don't have to move data
from Stata to Mata and viceversa.
However, they use inefficient algorithms, so for datasets large enough, they are slower.
In particular, creating identifiers can be an ~O(N) operation if we use hashes instead of sorting the data (see the help file).
Similarly, once the identifiers are created, sorting other variables by these identifiers can be done as an O(N) operation instead of O(N log N).

## "But I already tried to use Mata's `asarray` and it was much slower"

Mata's `asarray()` has a key problem: it is very slow with hash collisions (which you see a lot in this use case). Thus, I avoid using `asarray()` and instead use `hash1()` to create a hash table with open addressing (see a comparision between both approaches [here](http://www.algolist.net/Data_structures/Hash_table/Open_addressing#open_addressing_vs_chaining)).

