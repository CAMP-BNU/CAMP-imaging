#' Generate Word Picture
#'
#' @title
#' @param config
#' @return
#' @author Liang Zhang
#' @export
generate_word_pic <- function(config) {
  file_name <- fs::path("stimuli", "word", sprintf("%s.jpg", config$id))
  jpeg(file_name, width = 480, height = 480)
  gplots::textplot(config$word)
  dev.off()
  file_name
}
