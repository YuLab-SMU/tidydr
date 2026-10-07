# tidydr

`tidydr` provides uniform output and is compatible with multiple methods for dimensionality reduction, including `prcomp`, `mds`, and `Rtsne`.

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

For more examples, see `vignette("tidydr")`, the [GitHub repository](https://github.com/YuLab-SMU/tidydr/), and the [CRAN page](https://cran.r-project.org/package=tidydr).
