function config = init_config(phase, timing)
%INIT_CONFIG Initializing configurations for all tasks

arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test", "post"])}
    timing struct
end

if phase ~= "post"
    trials_each_block = 10;
    trial_dur = timing.stim_secs.(phase) + timing.blank_secs.(phase) + ...
        timing.feedback_secs * (phase == "prac"); % feedback when practice
    block_dur = trial_dur * trials_each_block + ...
        timing.fixation_secs.(phase); % fixation when test
    switch phase
        case "prac"
            rng('shuffle')
            stim_types = ["word", "object", "place", "face"];
            config = table;
            for i_block = 1:length(stim_types)
                cur_block = addvars( ...
                    init_trials(trials_each_block), ...
                    ones(trials_each_block, 1), ... % run_id
                    i_block * ones(trials_each_block, 1), ... % block_id
                    repmat(stim_types(i_block), trials_each_block, 1), ... % stim_type
                    'NewVariableNames', {'run_id', 'block_id', 'stim_type'}, ...
                    'Before', 1);
                config = vertcat(config, cur_block); %#ok<AGROW>
            end
        case "test"
            config = readtable(fullfile('stimuli', 'seq_2back.csv'), "TextType", "string");
    end
    config.stim_onset = (config.block_id - 1) * block_dur + ...
        (config.trial_id - 1) * trial_dur;
    config.stim_offset = config.stim_onset + timing.stim_secs.(phase);
    config.trial_end = config.stim_offset + timing.blank_secs.(phase);
else
    config = readtable(fullfile('stimuli', 'seq_post.csv'), "TextType", "string");
end
end

function trials = init_trials(num_trials, task_load, opts)
arguments
    num_trials {mustBeInteger, mustBePositive} = 10
    task_load {mustBeInteger, mustBePositive, ...
        mustBeLessThan(task_load, num_trials)} = 2
    opts.StimsPool = 91:95 % practice stimuli no is from 91 to 95
end

stims_pool = opts.StimsPool;

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
            cresp_order(i) = "diff";
        else
            cresp_order(i) = "same";
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
order_stim = [ ...
    randsample(stims_pool, task_load, false), ...
    nan(1, num_trials - task_load)];
for i = (task_load + 1):num_trials
    if cond_order(i) == "same"
        order_stim(i) = order_stim(i - task_load);
    else
        if cond_order(i) == "lure"
            stims_sample = order_stim(i - (1:(task_load - 1)));
        else
            stims_sample = setdiff(stims_pool, ...
                order_stim(i - (1:task_load)));
        end
        order_stim(i) = randsample(stims_pool, 1, true, ...
            ismember(stims_pool, stims_sample));
    end
end

trials = table( ...
    (1:num_trials)', order_stim', ...
    cond_order', cresp_order', ...
    VariableNames=["trial_id", "stim", "cond", "cresp"]);
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
