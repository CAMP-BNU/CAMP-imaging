library(targets)
purrr::walk(fs::dir_ls("R"), source)
tar_option_set(packages = c("magick", "tidyverse"))
future::plan(future.callr::callr)
list(
  words = list(
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
    )
  ),
  images = list(
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
  ),
  seq_post = list(
    tarchetypes::tar_file_read(
      seq_2back,
      "stimuli/seq_2back.csv",
      read = read_csv(!!.x, show_col_types = FALSE)
    ),
    tar_target(
      seq_post,
      generate_seq(seq_2back)
    ),
    tar_target(
      file_seq_post,
      write_csv(seq_post, "stimuli/seq_post.csv")
    )
  )
)
