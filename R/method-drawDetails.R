##' @importFrom grid drawDetails
##' @importFrom grid grid.segments
##' @method drawDetails draxis
##' @export
drawDetails.draxis <- function(x, recording=TRUE) {
    if (x$id == 1) {
        ## axis.line.x.bottom
        grid.segments(x0=0, x1=x$xlength, y0=1, y1=1, default.units = x$default.units, 
                    gp =  x$gp, arrow = x$arrow)
    } else {
        ## axis.line.y.left
        grid.segments(x0=1, x1=1, y0=0, y1=x$ylength, default.units = x$default.units, 
                    gp =  x$gp, arrow = x$arrow)
    }
}
