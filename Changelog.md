# Development version

# 1.0.5

* Fixed a bug in AMT task when finished run one experiment.
* Enhance AMT task by including response label when data recording.

# 1.0.4

* Now stimuli are untracked. Please follow the instructions in the `README.md` file to download the stimuli.

# 1.0.3

* Fixed aspect ratio error for mixed-video presentation.

# 1.0.2

* Fixed a bug in AMT task when exiting the experiment early.

# 1.0.1

* Enhanced AMT task by setting stimuli size according to screen size.
* Fixed aspect ratio error for movie presentation.
* Added support for upgrading the experiment code from GitHub. Please call `exp.upgrade()` to update the code.

# 1.0.0

* Added AMT practice to the UI, so that the experimenter can run the practice more easily ([#23](https://github.com/psychelzh/CAMP-imaging/issues/23)).
* Unified the format of participant response data ([#25](https://github.com/CAMP-BNU/CAMP-imaging/issues/25)).
* Unified the response keys for all the tasks.
* Enhanced AMT task from many aspects.
  * Background color is now white.
  * Practice instructions are now integrated into the task ([#17](https://github.com/CAMP-BNU/CAMP-imaging/issues/17)).
  * Support to exit the task by pressing `'Escape'` key.
  * Added a wait-to-end screen after the experiment ([#19](https://github.com/CAMP-BNU/CAMP-imaging/issues/19)).
  * Added the real onset time of each trial to the response data.
  * Adjust the flip time to avoid stimulation early present

# 0.2.1

* Renamed the project as `CAMP-imaging`. This will be more informative for the future development of the project.
* Supported fixation without triggering. Now all the fixation screen will be displayed without waiting for the scanner to trigger start, and will remain on screen before the experimenter presses `'Escape'` key([#18](https://github.com/psychelzh/CAMP-imaging/issues/18)).
* Added a wait-to-end screen after the experiment of two-back task([#19](https://github.com/psychelzh/CAMP-imaging/issues/19)).
* Enhanced some internal structures of the files.

# 0.2.0

* Removed post-test ([#12](https://github.com/psychelzh/wm-fmri/issues/12)).
* Enhanced subject management and ui logic.
* Removed contents of post recognition test and all the raw stimuli.
* Added association memory test.

# 0.1.1

* Fix practice face images.
* Skip sync tests in practice phase.

# 0.1.0

* Add `"rest"` condition to two-back sequence file ([#8](https://github.com/psychelzh/wm-fmri/issues/8)).
* Add `exp.start_fixation()` for fixation display during resting or structure imaging phases.
* Add a uers interface to aid in the administration of the experiment ([#3](https://github.com/psychelzh/wm-fmri/issues/3)).
* Update stimuli based on recent pilot study [#10](https://github.com/psychelzh/wm-fmri/issues/10).

# 0.0.4

* Enhance stimuli quality: remove watermark and enhance resolution.

# 0.0.3

* Add one similar stimuli for all the stimuli presented in 2-back test.

# 0.0.1.9000

* Added a `Changelog.md` file to track changes.
