library(targets)
purrr::walk(fs::dir_ls("R"), source)
tar_option_set(packages = "magick")
future::plan(future.callr::callr)
list(
  tarchetypes::tar_file_read(
    words,
    "stimuli-raw/words.txt",
    read = readr::read_lines(!!.x)
  ),
  tar_target(
    out_names,
    paste0(seq_along(words), ".jpg")
  ),
  tar_target(
    outputs, {
      filename <- fs::path("stimuli", "word", out_names)
      jpeg(filename, width = 480, height = 480)
      gplots::textplot(words)
      dev.off()
      filename
    },
    format = "file",
    pattern = map(words, out_names)
  ),
  tarchetypes::tar_files_input(
    raw_stimuli,
    fs::dir_ls(
      c(
        "stimuli-raw/object",
        "stimuli-raw/face",
        "stimuli-raw/place"
      ),
      type = "file"
    )
  ),
  tar_target(
    result_stimuli,
    resize_stimuli(raw_stimuli),
    pattern = map(raw_stimuli),
    format = "file"
  )
)
