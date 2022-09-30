library(targets)
purrr::walk(fs::dir_ls("R"), source)
tar_option_set(packages = c("magick", "tidyverse"))
future::plan(future.callr::callr)
list(
  words = list(
    tar_target(
      file_words,
      "stimuli-raw/words.csv",
      format = "file"
    ),
    tarchetypes::tar_group_size(
      config_words,
      read_csv(file_words, show_col_types = FALSE),
      size = 1L
    ),
    tar_target(
      file_word_pic,
      generate_word_pic(config_words),
      format = "file",
      pattern = map(config_words)
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
    tar_target(
      seq_post,
      generate_seq_post()
    ),
    tar_target(
      file_seq_post,
      write_csv(seq_post, "stimuli/seq_post.csv")
    )
  )
)
