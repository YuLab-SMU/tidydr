# tidydr 0.0.6.002

+ `nk()` can now use any clustering method through `fun` (2026-10-08, Thu)
    - `fun` defaults to `cluster::pam`, so the default result is bit-for-bit unchanged
    - `stats::kmeans` works out of the box; `stats::hclust` is cut with `cutree()`
    - a function returning a plain vector of cluster labels is also accepted
    - for non-`pam` clusterers the silhouette width is computed with
      `cluster::silhouette()` and assembled into the same shape `pam()` produces
+ `silinfo_widths()` exports the fine-grained silhouette widths of one `k` (2026-10-08, Thu)
    - returns a data.frame with `sample`, `cluster`, `neighbor` and `sil_width`
    - the per-cluster averages are attached as the `"clus.avg.widths"` attribute
+ `autoplot()` for a `silinfo` object gained a silhouette bar plot (2026-10-08, Thu)
    - `type = "silhouette"` draws the classic per-cluster bar plot
    - `type` is inferred from `k` when it is not given, so `autoplot(x)` is
      unchanged and `autoplot(x, k = 3)` still draws the same plot — except that
      the sample labels are now correct (see the fix below)
    - fixed: `autoplot(x, k = )` aligned `pam()`'s silhouette table to the samples
      by position, but `pam()` returns that table sorted by cluster; the labels are
      now matched by sample name (agreement with the true clustering on iris, k = 3,
      goes from 84% to 100%)
+ added `dr_compare()` to run several dimensionality reduction methods at once (2026-10-08, Thu)
    - every method is evaluated independently: a method that fails is reported in
      `$summary` with its error message instead of aborting the whole call
    - `$summary` gives `method`, `status`, `n`, `k`, `has_eigenvalue`, `has_stress`
      and `error`, so it is visible which methods ran and which did not
    - `autoplot()` facets the methods that produced plottable coordinates
+ `DrResult` gained a `sample_info` slot for method-specific, per-sample information (2026-10-08, Thu)
    - a `dr_extract()` method may return `sample_info`; `fortify()` merges its
      length-`n` elements into the returned data.frame as columns
    - `print()` output is unchanged
+ the methods advertised by `available_methods()` are now backed by tests (2026-10-08, Thu)
    - all 14 advertised methods are exercised end-to-end through `dr()`
    - `vegan`, `smacof`, `ecodist`, `ade4`, `labdsv` added to `Suggests`, together
      with `ape`, `MASS`, `Rtsne` and `uwot`, which the tests already used
+ `available_methods("all")` prints its closing note once instead of twice (2026-10-08, Thu)
    - the note is shared by the data and the distance listing but was printed from
      both branches, so it appeared twice; it is now printed once, after both
      listings
    - the `"data"` and `"distance"` branches are unchanged, and the returned
      value is unaffected
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
+ a hand-written `dr_extract()` method may return the coordinates as a numeric matrix (2026-10-08, Thu)
    - previously rejected with "length of 'dimnames' [2] not equal to array
      extent": the `Dim1`, `Dim2`, ... names were assigned with `seq_along()`,
      which counts *elements* rather than columns on a matrix
    - the matrix is now converted to a data.frame, so `fortify()` -- a 'ggplot2'
      generic -- always returns a data.frame
    - a `drdata` that is neither a data.frame nor a numeric matrix is now rejected
      with a message pointing at `?dr_extract`, instead of a cryptic error
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
