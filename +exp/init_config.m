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

import exp.init_nback
import exp.init_manip

stim_type = ["digit"; "space"];
blocks_pool_nback = create_blocks_pool("nback", stim_type, [2; 4]);
blocks_pool_manip = create_blocks_pool("manip", stim_type, [3; 6]);
if contains(task_config, "prac")
    trials_each_block_nback = 10;
    trials_each_block_manip = 3;
    switch task_config
        case "prac_nback"
            blocks_pool = blocks_pool_nback;
            trial_length_nback = timing.nback_stim_secs + ...
                timing.nback_blank_secs + ...
                timing.feedback_secs;
            blocks_pool.block_length = repelem( ...
                timing.block_cue_secs + ...
                trial_length_nback * trials_each_block_nback, ...
                height(blocks_pool), 1);
        case "prac_manip"
        case "prac"
    end
    blocks = blocks_pool;
    blocks.block_onset = cumsum([0; blocks.block_length(1:end - 1)]);
    blocks.rand_seed = repelem(-1, height(blocks))';
else
    rep_each_type = 4;
    trials_each_block_nback = 20;
    trials_each_block_manip = 5;
    blocks_pool = vertcat(blocks_pool_nback, blocks_pool_manip);
    blocks = repelem(blocks_pool, 4, 1);
end

blocks = addvars(blocks, (1:height(blocks))', ...
    Before=1, NewVariableNames='block_id');
blocks.trials = cell(height(blocks), 1);
for i_block = 1:height(blocks)
    switch blocks.task_name(i_block)
        case "nback"
            trials = init_nback( ...
                blocks.task_load(i_block), ...
                blocks.stim_type(i_block), ...
                trials_each_block_nback, ...
                RandSeed=blocks.rand_seed(i_block));
            trials.stim_onset = timing.block_cue_secs + ...
                ((1:trials_each_block_nback)' - 1) * trial_length_nback;
            trials.stim_offset = trials.stim_onset + timing.nback_stim_secs;
            trials.trial_end = trials.stim_offset + timing.nback_blank_secs;
        case "manip"
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
    config = datasample(blocks, length(blocks), Replace=false);
else
    config = blocks;
end
end

function blocks_pool = create_blocks_pool(task_name, stim_type, task_load)
[x, y, z] = ndgrid(1:length(task_name), ...
    1:length(stim_type), ...
    1:length(task_load));
blocks_pool = array2table([x(:), y(:), z(:)], ...
    'VariableNames', {'task_name', 'stim_type', 'task_load'});
blocks_pool.task_name = task_name(blocks_pool.task_name);
blocks_pool.stim_type = stim_type(blocks_pool.stim_type);
blocks_pool.task_load = task_load(blocks_pool.task_load);
end
