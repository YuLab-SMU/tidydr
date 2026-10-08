# tidydr 0.0.6.001

+ `dr()` now validates its `data` input and fails early with a tidydr-specific
  message instead of forwarding an obscure error from the underlying method (2026-10-08, Thu)
    - rejects `NULL`, bare vectors (hint: use `as.dist()` for distance vectors),
      non-numeric data, `data.frame`s with non-numeric columns, and `NA`/`NaN`/`Inf`
    - `dist` objects remain supported
+ `nk()` now validates `data` and `k` (2026-10-08, Thu)
    - `k = 1` is rejected: the silhouette width is undefined for a single cluster
      (previously produced an object that could not be printed)
    - `k >= n`, non-integer and non-numeric `k` are rejected with clear messages
    - `data` may still be a numeric matrix, a numeric data.frame, or a 'dist' object
+ `fortify()` no longer mishandles `metadata` (2026-10-08, Thu)
    - `matrix` metadata is no longer silently dropped (converted to a data.frame)
    - a `list` of length `n` no longer creates `n` junk `.group.*` columns
    - atomic vectors (including classed ones such as `Date`) are used as `.group`
    - unsupported types raise a warning listing the supported types
+ added a `dr_extract()` fallback for plain numeric matrices (2026-10-08, Thu)
    - makes `stats::cmdscale()` (and any wrapped method returning a bare matrix) work
    - any function returning a numeric matrix with at least two columns is accepted
    - non-numeric or single-column matrices are rejected
+ added a GitHub Actions workflow that runs `R CMD check` on push and PR (2026-10-08, Thu)

# tidydr 0.0.6

+ S3 method consistency with ggplot2 (v=4.0.0) (2025-06-21, Sat, #4)
+ `nk()` for choose k (number of clusters) (2023-03-17, Fri)
    - output is a `silinfo` object with `print()`, `summary()` and `autoplot()` methods

# tidydr 0.0.5

+ `autoplot` method for `SingleCellExperiment` object (2022-11-01, Tue)

# tidydr 0.0.4

+ added `available_methods()` to show available DR methods (2022-3-15, Tue)
+ update `dr_extract` to support methods work for distance objects (2022-3-14, Mon)
    - `uwot::umap()`
    - `uwot::tumap()`
    - `uwot::lvish()`
+ fixed the error: mapping is missing with no default (2022-3-14, Mon)

# tidydr 0.0.3

+ update Rd files with return value (2021-12-08, Wed)
+ use `theme_minimal()` as base theme in `theme_dr()` (2021-12-07, Tue)

# tidydr 0.0.2

+ add vignette (2021-12-07, Tue)
+ `print()` method for `DrResult`
+ support `metadata` in `fortify()`, `ggplot()` and `autoplot()`
+ update `dr_extract` to support methods work for distance objects (2021-12-5, Sun)
    - `stats::cmdscale`
    - `MASS::sammon`
    - `vegan::metaMDS`
    - `ape::pcoa`
    - `smacof::mds`
    - `vegan::wcmdscale`
    - `ecodist::pco`
    - `labdsv::pco`
    - `ade4::dudi.pco`
+ add new slots `eigenvalue` and `stress` to the `DrResult` class

# tidydr 0.0.1

+ `theme_dr()` that add shorten version of x and y axis
+ `theme_noaxis()` to remove axis elements
+ `autoplot()` to plot `dr()` output
+ extend `ggplot()` to support `dr()` output
+ `dr()` to unify dimension reduction result
    - supports `stats::prcomp` and `Rtsne::Rtsne`
+ `DrResult` class
    - data: original data
    - drdata: Dr result, i.e., point coordinations
    - .call: function call
