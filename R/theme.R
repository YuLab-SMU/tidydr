theme_dr <- function() {
    theme(axis.line=element_blank(), 
        axis.ticks=element_blank(), 
        axis.text=element_blank(), 
        axis.line.y.left=element_line2(id=2), 
        axis.line.x.bottom=element_line2(id=1),
        axis.title=element_text(hjust=0.1))
}
