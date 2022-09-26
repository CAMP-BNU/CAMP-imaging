library(targets)
future::plan(future.callr::callr)
list(
  tarchetypes::tar_file_read(
    words,
    "stimuli-raw/words.txt",
    read = readr::read_lines(!!.x)
  ),
  tar_target(
    out_names,
    paste0(c(1:90, paste0("prac", 1:5)), ".jpg")
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
  )
)
