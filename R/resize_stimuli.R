#' Resize Stimuli as Given Size
#'
#' @title
#' @param file Path to stimuli.
#' @param geometry New stimuli size.
#' @return
#' @author Liang Zhang
#' @export
resize_stimuli <- function(file, geometry = NULL) {
  if (is.null(geometry)) {
    geometry <- geometry_area(480, 480)
  }
  img_raw <- image_read(file)
  ext_size <- with(image_info(img_raw), max(width, height))
  img_new <- img_raw |>
    image_extent(geometry_area(ext_size, ext_size), color = "white") |>
    image_resize(geometry)
  outfile <- sub("stimuli-raw", "stimuli", file) |>
    fs::path_ext_set("jpg")
  image_write(img_new, outfile)
  outfile
}
