function config = init_config(task_config, timing, id)
%INIT_CONFIG Initializing configurations for all tasks
%
% Parameters:
%   task_config: Can only be one of these values: "prac_nback",
%   "prac_manip", "prac" and "test".
%
%   id: The idenitifier of the participant. Note: id of 0 is used for
%   debugging!

arguments
    task_config {mustBeTextScalar, mustBeMember(task_config, ["prac_nback", "prac_manip", "prac", "test"])}
    timing struct
    id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
end

if contains(task_config, "prac")
    trials_each_block_nback = 10;
    trials_each_block_manip = 3;
    trial_length_nback = timing.nback_stim_secs + ...
        timing.nback_blank_secs + timing.feedback_secs;
    probe_length_manip = timing.manip_probe_secs + ...
        timing.manip_blank_secs + timing.feedback_secs;
    trial_length_manip = timing.manip_encoding_secs + ...
        timing.manip_cue_secs + probe_length_manip;
else
    trials_each_block_nback = 20;
    trials_each_block_manip = 5;
    trial_length_nback = timing.nback_stim_secs + timing.nback_blank_secs;
    probe_length_manip = timing.manip_probe_secs + timing.manip_blank_secs;
    trial_length_manip = timing.manip_encoding_secs + ...
        timing.manip_cue_secs + probe_length_manip;
end
block_length_nback = timing.block_cue_secs + trial_length_nback * trials_each_block_nback;
block_length_manip = timing.block_cue_secs + trial_length_manip * trials_each_block_manip;
stim_type = ["digit"; "space"];
blocks_pool_nback = create_blocks_pool("nback", stim_type, [1; 3], block_length_nback);
blocks_pool_manip = create_blocks_pool("manip", stim_type, [1; 3], block_length_manip);

switch task_config
    case "prac_nback"
        blocks = blocks_pool_nback;
    case "prac_manip"
        blocks = blocks_pool_manip;
    case "prac"
        blocks = vertcat(blocks_pool_nback, blocks_pool_manip);
    case "test"
        blocks = repelem( ...
            vertcat(blocks_pool_nback, blocks_pool_manip), ...
            4, 1);
end
if contains(task_config, "prac")
    blocks.rand_seed = repelem(-1, height(blocks))';
else
    blocks.rand_seed = (1:height(blocks))';
end
blocks.trials = cell(height(blocks), 1);
for i_block = 1:height(blocks)
    switch blocks.task_name(i_block)
        case "nback"
            trials = init_trials_nback( ...
                blocks.task_load(i_block), ...
                blocks.stim_type(i_block), ...
                trials_each_block_nback, ...
                RandSeed=blocks.rand_seed(i_block));
            init_timing_nback()
        case "manip"
            trials = init_trials_manip( ...
                blocks.task_load(i_block), ...
                blocks.stim_type(i_block), ...
                trials_each_block_manip, ...
                RandSeed=blocks.rand_seed(i_block));
            init_timing_manip()
    end
    blocks.trials{i_block} = trials;
end
if ismember(task_config, ["prac", "test"])
    if task_config == "test"
        if id == 0
            warning('exp:init_config:id_abnormal', ...
                'Identifier of 0 is used in test phase.')
        end
        rng(id)
    end
    blocks = datasample(blocks, height(blocks), Replace=false);
end
blocks.block_onset = cumsum([0; blocks.block_length(1:end - 1)]);
config = addvars(blocks, (1:height(blocks))', ...
    Before=1, NewVariableNames='block_id');
    
    function init_timing_nback()
        trials.stim_onset = timing.block_cue_secs + ...
            ((1:trials_each_block_nback)' - 1) * trial_length_nback;
        trials.stim_offset = trials.stim_onset + timing.nback_stim_secs;
        trials.trial_end = trials.stim_offset + timing.nback_blank_secs;
    end

    function init_timing_manip()
        trials.encoding_onset = timing.block_cue_secs + ...
            ((1:trials_each_block_manip)' - 1) * trial_length_manip;
        trials.cue_onset = trials.encoding_onset + timing.manip_encoding_secs;
        trials.probe_onset = arrayfun( ...
            @(i) trials.cue_onset(i) + timing.manip_cue_secs, ...
            (1:height(trials))');
        trials.probe_offset = arrayfun( ...
            @(i) trials.probe_onset(i) + timing.manip_probe_secs, ...
            (1:height(trials))');
        trials.trial_end = arrayfun( ...
            @(i) trials.probe_offset(i) + timing.manip_blank_secs, ...
            (1:height(trials))');
    end
end

function blocks_pool = create_blocks_pool(task_name, stim_type, task_load, block_length)
[x, y, z, u] = ndgrid( ...
    1:length(task_name), ...
    1:length(stim_type), ...
    1:length(task_load), ...
    1:length(block_length));
blocks_pool = array2table([x(:), y(:), z(:), u(:)], ...
    'VariableNames', {'task_name', 'stim_type', 'task_load', 'block_length'});
blocks_pool.task_name = task_name(blocks_pool.task_name);
blocks_pool.stim_type = stim_type(blocks_pool.stim_type);
blocks_pool.task_load = task_load(blocks_pool.task_load);
blocks_pool.block_length = block_length(blocks_pool.block_length);
end

function trials = init_trials_nback(task_load, stim_type, num_trials, options)
arguments
    task_load (1, 1) {mustBeInteger, mustBePositive}
    stim_type {mustBeTextScalar, mustBeMember(stim_type, ["digit", "space"])}
    num_trials (1, 1) {mustBeInteger, mustBeGreaterThan(num_trials, task_load)}
    options.StimsPool = 1:16
    % note: random seed of -1 is used for 'shuffle'
    options.RandSeed (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(options.RandSeed, -1)} = -1
end

stims_pool = options.StimsPool;

if options.RandSeed == -1
    rng('shuffle')
else
    rng(options.RandSeed)
end

n_filler = task_load;
n_same = fix((num_trials - task_load) / 2);
n_lure = fix((num_trials - task_load) / 4);
n_diff = num_trials - n_filler - n_same - n_lure;
stim_conds = [ ...
    repelem("same", n_same), ...
    repelem("lure", n_lure), ...
    repelem("diff", n_diff)];
% ---- randomise conditions ----
cond_okay = false;
while ~cond_okay
    cond_order = [ ...
        repelem("filler", task_load), ...
        stim_conds(randperm(length(stim_conds)))];
    cresp_order = strings(1, length(cond_order));
    for i = 1:length(cond_order)
        if cond_order(i) == "filler"
            cresp_order(i) = "none";
        elseif ismember(cond_order(i), ["lure", "diff"])
            cresp_order(i) = "right";
        else
            cresp_order(i) = "left";
        end
    end
    % lure/same trials cannot directly follow lure trials
    after_lure = cond_order(circshift(cond_order == "lure", 1));
    if (any(ismember(after_lure, ["lure", "same"])))
        continue
    end
    % require no more than 3 consecutive repetition responses
    cond_okay = validate_consecutive(cresp_order(task_load + 1:end));
end

% --- allocate stimulus ---
% main stimuli are cued
order_stim_main = [ ...
    randsample(stims_pool, task_load, false), ...
    nan(1, num_trials - task_load)];
% control stimuli are not to be remembered
order_stim_ctrl = randsample(stims_pool, num_trials, true);
for i = (task_load + 1):num_trials
    if cond_order(i) == "same"
        order_stim_main(i) = order_stim_main(i - task_load);
    else
        if cond_order(i) == "lure"
            stims_sample = order_stim_main(i - (1:(task_load - 1)));
        else
            stims_sample = setdiff(stims_pool, ...
                order_stim_main(i - (1:task_load)));
        end
        order_stim_main(i) = randsample(stims_pool, 1, true, ...
            ismember(stims_pool, stims_sample));
    end
end
switch stim_type
    case "digit"
        name_stim_main = "number";
        name_stim_ctrl = "location";
    case "space"
        name_stim_main = "location";
        name_stim_ctrl = "number";
end

trials = table( ...
    (1:num_trials)', order_stim_main', order_stim_ctrl', ...
    cond_order', cresp_order', ...
    VariableNames=["trial_id", name_stim_main, name_stim_ctrl, ...
    "cond", "cresp"]);
end

function trials = init_trials_manip(task_load, stim_type, num_trials, options)
arguments
    task_load (1, 1) {mustBeInteger, mustBePositive}
    stim_type {mustBeTextScalar, mustBeMember(stim_type, ["digit", "space"])}
    num_trials (1, 1) {mustBeInteger, mustBePositive}
    options.StimsPool = 1:16
    % note: random seed of -1 is used for 'shuffle'
    options.RandSeed (1, 1) {mustBeInteger, mustBeGreaterThanOrEqual(options.RandSeed, -1)} = -1
end

stims_pool = options.StimsPool;

if options.RandSeed == -1
    rng('shuffle')
else
    rng(options.RandSeed)
end

switch stim_type
    case "digit"
        % ensure correct answer is in [1, 16] range
        encodings_main = allocate_stim_manip(setdiff(stims_pool, [1:3, 14:16]), task_load, num_trials);
    case "space"
        encodings_main = allocate_stim_manip(stims_pool, task_load, num_trials);
end
encodings_ctrl = allocate_stim_manip(stims_pool, task_load, num_trials);
while true
    cresps = randsample(["left"; "right"], num_trials, true);
    if validate_consecutive(cresps)
        break
    end
end

cues = strings(num_trials, 1);
probes_main = nan(num_trials, 1);
probes_ctrl = nan(num_trials, 1);
for i_trial = 1:num_trials
    encoding_ctrl = encodings_ctrl{i_trial};
    encoding_main = encodings_main{i_trial};
    switch stim_type
        case "digit"
            cue = randsample(["加上3", "减去3"], 1);
            switch cue
                case "加上3"
                    probe_main_correct = encoding_main + 3;
                case "减去3"
                    probe_main_correct = encoding_main - 3;
            end
        case "space"
            cue = randsample(["顺时针", "逆时针"], 1);
            loc_pre = reshape(1:16, 4, 4);
            switch cue
                case "顺时针"
                    loc_post = rot90(loc_pre, 3);
                case "逆时针"
                    loc_post = rot90(loc_pre);
            end
            probe_main_correct = arrayfun( ...
                @(loc) loc_pre(loc_post == loc), ...
                encoding_main);
    end
    probe_idx = randsample(1:task_load, 1);
    probe_main = probe_main_correct(probe_idx);
    probe_ctrl = encoding_ctrl(probe_idx);
    if cresps(i_trial) ~= "left" % indicate probe is incorrect
        while true
            new_probe = randsample( ...
                [probe_main + 1, probe_main - 1], 1);
            if ismember(new_probe, stims_pool)
                break
            end
        end
        probe_main = new_probe;
    end
    cues(i_trial) = cue;
    probes_main(i_trial) = probe_main;
    probes_ctrl(i_trial) = probe_ctrl;
end

switch stim_type
    case "digit"
        name_stim_main = "number";
        name_stim_ctrl = "location";
    case "space"
        name_stim_main = "location";
        name_stim_ctrl = "number";
end

trials = table( ...
    (1:num_trials)', ...
    encodings_main, encodings_ctrl, cues, ...
    probes_main, probes_ctrl, cresps, ...
    VariableNames=["trial_id", "encoding_" + name_stim_main, ...
    "encoding_" + name_stim_ctrl, "cue", ...
    "probe_" + name_stim_main, "probe_" + name_stim_ctrl, "cresp"]);

end

function stim_order = allocate_stim_manip(stims_pool, task_load, num_trials)
num_stims = task_load * num_trials;
replacement = false;
if num_stims > length(stims_pool)
    warning('init_config:too_many_trials', ...
        'Too many trials required! Stimuli will be used repeatedly now!')
    replacement = true;
end
stims = randsample(stims_pool, num_stims, replacement);
stim_order = mat2cell(reshape(stims, [num_trials, task_load]), repelem(1, num_trials));
end

function tf = validate_consecutive(seq, max_run_value)
arguments
    seq {mustBeVector}
    max_run_value (1, 1) {mustBeInteger, mustBePositive} = 3
end

tf = true;
run_value = missing;
for i = 1:length(seq)
    cur_value = seq(i);
    if run_value ~= cur_value
        run_value = cur_value;
        run_length = 1;
    else
        run_length = run_length + 1;
    end
    if run_length > max_run_value
        tf = false;
        break
    end
end
end
