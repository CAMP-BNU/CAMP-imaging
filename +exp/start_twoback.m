function [status, exception, recordings] = start_twoback(phase, run, opts)
%START_NBACK Starts stimuli presentation for n-back test
%   Detailed explanation goes here
arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test"])} = "prac"
    run {mustBeInteger, mustBePositive} = 1
    opts.id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
    opts.SaveData (1, 1) {mustBeNumericOrLogical} = true
    opts.SkipSyncTests (1, 1) {mustBeNumericOrLogical} = false
end

% ---- set default error related outputs ----
status = 0;
exception = [];

% ---- set experiment timing parameters (predefined here, all in secs) ----
timing = struct( ...
    'stim_secs', 2, ...
    'blank_secs', 2, ...
    'fixation_secs', struct("prac", 4, "test", 10), ...
    'feedback_secs', 0.5);

% ----prepare config and data recording table ----
config = init_config(phase, timing);
config = config(config.run_id == run, :);
rec_vars = {'stim_onset_real', 'stim_offset_real', 'acc', 'rt', 'resp', 'resp_raw'};
rec_init = table('Size', [height(config), length(rec_vars)], ...
    'VariableTypes', [repelem("doublenan", 4), repelem("string", 2)], ...
    'VariableNames', rec_vars);
recordings = horzcat(config, rec_init);

% ---- configure screen and window ----
% setup default level of 2
PsychDefaultSetup(2);
% screen selection
screen_to_display = max(Screen('Screens'));
% set the start up screen to black
old_visdb = Screen('Preference', 'VisualDebugLevel', 1);
% do not skip synchronization test to make sure timing is accurate
old_sync = Screen('Preference', 'SkipSyncTests', double(opts.SkipSyncTests));
% use FTGL text plugin
old_text_render = Screen('Preference', 'TextRenderer', 1);
% set priority to the top
old_pri = Priority(MaxPriority(screen_to_display));
% PsychDebugWindowConfiguration([], 0.1);

% ---- keyboard settings ----
keys = struct( ...
    'start', KbName('s'), ...
    'exit', KbName('Escape'), ...
    'same', KbName('1!'), ...
    'diff', KbName('4$'));

% ---- stimuli presentation ----
% the flag to determine if the experiment should exit early
early_exit = false;
% the flag to determine if early exiting will be treated as normal
early_exit_okay = false;
try
    % open a window and set its background color as gray
    [window_ptr, window_rect] = PsychImaging('OpenWindow', screen_to_display, WhiteIndex(screen_to_display));
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name
    Screen('TextFont', window_ptr, 'SimHei');
    Screen('TextSize', window_ptr, round(0.06 * RectHeight(window_rect)));
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);
    % prepare stimuli rectangle
    rect_size = round(0.625 * RectHeight(window_rect));
    [center(1), center(2)] = RectCenter(window_rect);
    base_rect = [0, 0, rect_size, rect_size];
    stim_rect = CenterRectOnPoint(base_rect, center(1), center(2));

    % display welcome/instr screen and wait for a press of 's' to start
    switch phase
        case "prac"
            [instr, ~, intsr_alpha] = imread(fullfile('stimuli', 'twoback', 'instr', 'instr.png'));
            instr(:, :, 4) = intsr_alpha;
            instr_tex = Screen('MakeTexture', window_ptr, instr);
            Screen('DrawTexture', window_ptr, instr_tex, [], window_rect)
        case "test"
            instr = '下面我们进行正式测试';
            DrawFormattedText(window_ptr, double(instr), 'center', 'center');
    end
    Screen('Flip', window_ptr);
    % here we should detect for a key press and release
    while ~early_exit
        [resp_timestamp, key_code] = KbStrokeWait(-1);
        if key_code(keys.start)
            start_time = resp_timestamp;
            break
        elseif key_code(keys.exit)
            early_exit = true;
        end
    end

    % main experiment
    for trial_order = 1:height(config)
        if early_exit
            break
        end
        this_trial = config(trial_order, :);

        if this_trial.cond == "rest"
            stim_onset_stamp = nan;
            while ~early_exit
                DrawFormattedText(window_ptr, '+', 'center', 'center', BlackIndex(window_ptr));
                vbl = Screen('Flip', window_ptr);
                if vbl >= start_time + this_trial.trial_end - 0.5 * ifi
                    break
                end
                if isnan(stim_onset_stamp)
                    stim_onset_stamp = vbl;
                end
                [~, ~, key_code] = KbCheck(-1);
                if key_code(keys.exit)
                    early_exit = true;
                end
            end
            timing_real = struct( ...
                'stim_onset', stim_onset_stamp - start_time, ...
                'stim_offset', nan);
            resp_result = struct( ...
                'time', nan, ...
                'name', "none", ...
                'raw', "");
        else
            % basic routine
            [resp_collected, timing_real] = collect_response(this_trial);
            resp_result = analyze_response(resp_collected);
        end

        % record response
        recordings.stim_onset_real(trial_order) = timing_real.stim_onset;
        recordings.stim_offset_real(trial_order) = timing_real.stim_offset;
        recordings.acc(trial_order) = this_trial.cresp == resp_result.name;
        recordings.rt(trial_order) = resp_result.time;
        recordings.resp(trial_order) = resp_result.name;
        recordings.resp_raw(trial_order) = resp_result.raw;

        % give feedback when in practice
        if this_trial.cond ~= "rest" && phase == "prac"
            show_feedback(this_trial, resp_result)
        end

    end

    % post wait-to-end screen
    if ~early_exit && phase == "test"
        early_exit_okay = true;
        instr_ending = char(strjoin(readlines(fullfile('common', 'instr_ending.txt'), ...
            "EmptyLineRule", "skip"), "\n"));
        DrawFormattedText(window_ptr, double(instr_ending), 'center', 'center');
        Screen('Flip', window_ptr);
        while ~early_exit
            [~, key_code] = KbStrokeWait(-1);
            if key_code(keys.exit)
                early_exit = true;
            end
        end
    end
catch exception
    status = 1;
end

if early_exit && ~early_exit_okay
    status = 2;
end

% --- post presentation jobs
Screen('Close');
sca;
% enable character input and show mouse cursor
ListenChar;
ShowCursor;

% restore preferences
Screen('Preference', 'VisualDebugLevel', old_visdb);
Screen('Preference', 'SkipSyncTests', old_sync);
Screen('Preference', 'TextRenderer', old_text_render);
Priority(old_pri);

if opts.SaveData
    utils.store_data(recordings, opts.id, "twoback", run);
end

    function [resp_collected, timing_real] = collect_response(trial)
        % this might be time consumig
        stim_file = [num2str(trial.stim), '.jpg'];
        stim_pic = imread(fullfile('stimuli', 'twoback', trial.stim_type, stim_file));
        stim = Screen('MakeTexture', window_ptr, stim_pic);
        % present stimuli
        resp_made = false;
        resp_code = nan;
        stim_onset_stamp = nan;
        stim_offset_stamp = nan;
        resp_timestamp = nan;
        stim_offset = start_time + trial.stim_offset;
        trial_end = start_time + trial.trial_end;
        while ~early_exit
            [key_pressed, timestamp, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
                break
            end
            if key_pressed
                if ~resp_made
                    resp_code = key_code;
                    resp_timestamp = timestamp;
                end
                resp_made = true;
            end
            if timestamp < stim_offset
                Screen('DrawTexture', window_ptr, stim, [], stim_rect)
                vbl = Screen('Flip', window_ptr);
                if isnan(stim_onset_stamp)
                    stim_onset_stamp = vbl;
                end
            else
                vbl = Screen('Flip', window_ptr);
                if isnan(stim_offset_stamp)
                    stim_offset_stamp = vbl;
                    if phase == "post" && resp_made
                        trial_end = stim_offset_stamp + timing.blank_secs.(phase);
                    end
                end
            end
            if vbl >= trial_end - 0.5 * ifi
                break
            end
        end
        resp_collected = struct( ...
            'made', resp_made, ...
            'code', resp_code, ...
            'time', resp_timestamp - stim_onset_stamp);
        timing_real = struct( ...
            'stim_onset', stim_onset_stamp - start_time, ...
            'stim_offset', stim_offset_stamp - start_time);
    end

    function resp_result = analyze_response(resp_collected)
        if ~resp_collected.made
            resp_raw = "";
            resp_name = "none";
            resp_time = 0;
        else
            % use "|" as delimiter for the KeyName of "|" is "\\"
            resp_code = resp_collected.code;
            resp_raw = string(strjoin(cellstr(KbName(resp_code)), '|'));
            valid_names = {'same', 'diff'};
            valid_codes = cellfun(@(x) keys.(x), valid_names);
            if sum(resp_code) > 1 || (~any(resp_code(valid_codes)))
                resp_name = "invalid";
            else
                resp_name = valid_names{valid_codes == find(resp_code)};
            end
            resp_time = resp_collected.time;
        end
        resp_result = struct( ...
            'raw', resp_raw, ...
            'name', resp_name, ...
            'time', resp_time);
    end

    function show_feedback(trial, resp_result)
        while ~early_exit
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
                break
            end

            if trial.cresp ~= resp_result.name
                fb.color = get_color('red');
                if resp_result.name == "none"
                    fb.text = '超时';
                elseif trial.cresp == "none"
                    fb.text = '前两个试次不能作答';
                else
                    fb.text = '错误';
                end
            else
                fb.color = get_color('green');
                fb.text = '正确';
            end
            DrawFormattedText(window_ptr, double(fb.text), 'center', 'center', fb.color);
            vbl = Screen('Flip', window_ptr);
            if vbl >= start_time + trial.trial_end + timing.feedback_secs - 0.5 * ifi
                break
            end
        end
    end
end

function config = init_config(phase, timing)
%INIT_CONFIG Initializing configurations for all tasks

arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test", "post"])}
    timing struct
end

trials_each_block = 11;
trial_dur = timing.stim_secs + timing.blank_secs + ...
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
                ones(trials_each_block + 1, 1), ... % run_id
                i_block * ones(trials_each_block + 1, 1), ... % block_id
                repmat(stim_types(i_block), trials_each_block + 1, 1), ... % stim_type
                'NewVariableNames', {'run_id', 'block_id', 'stim_type'}, ...
                'Before', 1);
            config = vertcat(config, cur_block); %#ok<AGROW>
        end
    case "test"
        config = readtable(fullfile('stimuli', 'twoback', 'sequence.csv'), "TextType", "string");
end
config.stim_onset = (config.block_id - 1) * block_dur + ...
    (config.trial_id - 1) * trial_dur;
config.stim_offset = config.stim_onset + timing.stim_secs;
config.trial_end = config.stim_offset + timing.blank_secs;
config.stim_offset(config.cond == "rest") = nan;
config.trial_end(config.cond == "rest") = ...
    config.stim_onset(config.cond == "rest") + timing.fixation_secs.(phase);
end

function trials = init_trials(num_trials, task_load, opts)
arguments
    num_trials {mustBeInteger, mustBePositive} = 10
    task_load {mustBeInteger, mustBePositive, ...
        mustBeLessThan(task_load, num_trials)} = 2
    opts.StimsPool = 91:95 % practice stimuli no is from 91 to 95
    opts.AppendRest {mustBeNumericOrLogical} = true;
end

stims_pool = opts.StimsPool;
append_rest = opts.AppendRest;

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
if append_rest
    rest_trial = table(12, 0, "rest", "none", ...
        VariableNames=["trial_id", "stim", "cond", "cresp"]);
    trials = vertcat(trials, rest_trial);
end
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
