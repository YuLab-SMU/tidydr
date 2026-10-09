# tidydr

`tidydr` provides uniform output and is compatible with multiple methods for dimensionality reduction, including `prcomp`, `cmdscale`, `Rtsne`, `umap` and `metaMDS`. Any function that returns a numeric matrix can also be used.

## Installation

Install the released version from CRAN:

```r
install.packages("tidydr")
```

Install the development version from GitHub:

```r
remotes::install_github("YuLab-SMU/tidydr")
```

## Usage

```r
library(ggplot2)
library(tidydr)

x <- dr(data = iris[, 1:4], fun = prcomp)
autoplot(x, aes(color = Species), metadata = iris[, 5, drop = FALSE]) +
    theme_dr()
```

The methods known to work are listed by `available_methods()`. Methods that need
their own arguments receive them through `...`, e.g.
`dr(iris[, 1:4], Rtsne::Rtsne, check_duplicates = FALSE)`.

## Comparing several methods

`dr_compare()` runs several methods on the same data. Each method is evaluated
independently, so a method that fails is reported in the summary instead of
aborting the whole call:

```r
r <- dr_compare(iris[, 1:4],
                funs = list(prcomp = stats::prcomp, umap = uwot::umap),
                dim = 1:2)

r$summary      # method, status, n, k, has_eigenvalue, has_stress, error
autoplot(r)    # one facet per method that produced coordinates
```

## Clustering and silhouette widths

`nk()` computes the average silhouette width over one or more values of `k`. It
uses `cluster::pam()` by default; any other clustering function can be plugged in
through `fun`:

```r
si <- nk(iris[, 1:4], 2:4)                     # pam(), the default
si <- nk(iris[, 1:4], 3, fun = stats::kmeans)  # any other clusterer

autoplot(si)                                   # average silhouette width vs k
autoplot(si, k = 3)                            # samples coloured by cluster
autoplot(si, k = 3, type = "silhouette")       # per-cluster silhouette bars
```

The per-sample widths of a single `k` are available from `silinfo_widths()`:

```r
w <- silinfo_widths(si, 3)
head(w)
```

## Going further

For more examples, see `vignette("tidydr")`, the [GitHub repository](https://github.com/YuLab-SMU/tidydr/), and the [CRAN page](https://cran.r-project.org/package=tidydr).
