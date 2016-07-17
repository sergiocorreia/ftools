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

