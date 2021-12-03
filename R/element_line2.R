element_line2 <- function (colour = NULL, size = NULL, linetype = NULL, lineend = NULL, 
    color = NULL, arrow = grid::arrow(length=unit(0.15, "inches")), inherit.blank = FALSE, id, ...) {
    if (!is.null(color)) 
        colour <- color
    if (is.null(arrow)) 
        arrow <- FALSE
    structure(list(colour = colour, size = size, linetype = linetype, 
        lineend = lineend, arrow = arrow, inherit.blank = inherit.blank, id = id,
        ...), 
        class = c("element_line2", "element_line", "element"))
}


element_grob.element_line2 <- function (element, colour = NULL, size = NULL, 
    linetype = NULL, lineend = NULL, default.units = "npc", id.lengths = NULL, 
    ...) {

    gp <- gpar(col = colour, fill = colour, lwd = len0_null(size * 
        .pt), lty = linetype, lineend = lineend)
    element_gp <- gpar(col = element$colour, fill = element$colour, 
        lwd = len0_null(element$size * .pt), lty = element$linetype, 
        lineend = element$lineend)
    arrow <- if (is.logical(element$arrow) && !element$arrow) {
        NULL
    }
    else {
        element$arrow
    }

    grob(default.units = default.units, 
        gp = modify_list(element_gp, gp), 
        arrow = arrow, id=element$id, cl="draxis")   

}

drawDetails.draxis <- function(x, recording=TRUE, id) {
    if (x$id == 1) {
        ## axis.line.x.bottom
        grid.segments(x0=0, x1=0.3, y0=1, y1=1, default.units = x$default.units, 
                    gp =  x$gp, arrow = x$arrow)
    } else {
        ## axis.line.y.left
        grid.segments(x0=1, x1=1, y0=0, y1=0.3, default.units = x$default.units, 
                    gp =  x$gp, arrow = x$arrow)
    }
}