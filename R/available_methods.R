##'  This function shows available methods that worked for `dr()` function.
##' @title List dimensionality reduction methods currently available
##' @return A character vector of available DR methods
##' @examples available_methods()
##' @export
##' @author Lang Zhou
available_methods <- function() {
    data_methods <- c("stats::prcomp()",
                      "Rtsne::Rtsne()",
                      "uwot::umap()",
                      "uwot::tumap()",
                      "uwot::lvish()")
    
    distance_methods <- c("stats::cmdscale()",
                          "MASS::sammon()",
                          "vegan::metaMDS()",
                          "ape::pcoa()",
                          "smacof::mds()",
                          "vegan::wcmdscale()",
                          "ecodist::pco()",
                          "labdsv::pco()",
                          "ade4::dudi.pco()")
     
    message("dr() function works for methods that ",
            "require data matrix (or data frame):" )
    message(paste(data_methods, collapse = "\n"),
            "\n")

    message("dr() function works for methods that ",
            "require distance matrix (or distance object):" )
    message(paste(distance_methods, collapse = "\n"),
            "\n")
    
}



