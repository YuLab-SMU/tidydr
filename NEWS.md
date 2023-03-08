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
