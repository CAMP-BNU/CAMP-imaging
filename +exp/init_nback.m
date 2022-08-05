function trials = init_nback(task_load, stim_type, num_trials, options)
arguments
    task_load (1, 1) {mustBeMember(task_load, [2, 4])}
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
    cond_okay = true;
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
        cond_okay = false;
        continue
    end
    % require no more than 3 consecutive responses
    run_value = strings;
    for i = (task_load + 1):length(stim_conds)
        cresp = cresp_order(i);
        if run_value ~= cresp
            run_value = cresp;
            run_length = 1;
        else
            run_length = run_length + 1;
        end
        if run_length > 3
            cond_okay = false;
            break
        end
    end
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
