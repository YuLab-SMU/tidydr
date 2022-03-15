##' @importFrom ggplot2 autoplot
##' @export
ggplot2::autoplot

##' @importFrom ggplot2 autoplot
##' @method autoplot DrResult
##' @importFrom ggplot2 ggplot
##' @importFrom ggplot2 geom_point
##' @importFrom ggplot2 aes_
##' @importFrom utils modifyList
##' @export
autoplot.DrResult <- function(object, mapping, ...) {
    if (missing(mapping)) {
        mapping <- aes_(~Dim1, ~Dim2)
    }else {
        mapping <- modifyList(aes_(~Dim1, ~Dim2), mapping)
    }
    ggplot(object, mapping, ...) + geom_point()
}

