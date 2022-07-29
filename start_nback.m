function [recordings, status, exception] = start_nback(args)
%START_NBACK Starts stimuli presentation for n-back test
%   Detailed explanation goes here
arguments
    args.StimType {mustBeMember(args.StimType, ["digit", "space"])} = "digit"
    args.TaskLoad {mustBeMember(args.TaskLoad, [2, 4])} = 2
    args.ExpPhase {mustBeMember(args.ExpPhase, ["prac", "test"])} = "prac"
end

stim_type = args.StimType;
task_load = args.TaskLoad;
exp_phase = args.ExpPhase;
% choose base location and digit
switch stim_type
    case "digit"
        base_loc = randsample(1:16, 1);
    case "space"
        base_digit = randsample(1:16, 1);
end

% ---- set default error related outputs ----
status = 0;
exception = [];

% ---- set experiment timing parameters (predefined here, all in secs) ----
% stimuli duration
time_stimuli_secs = 1;
% a blank screen still wait for user's response
time_blank_secs = 2;
% used in "prac" phase, feedback duration
time_feedback_secs = 0.5;
% used in "test" part, interval for user's preparation for test
time_wait_start_secs = 4;
time_wait_end_secs = 4;

% ----prepare config and data recording table ----
config = init_config();
vars_trial_timing = {'stim_onset_real', 'stim_offset_real'};
dflt_trial_timing = {nan, nan};
vars_trial_resp = {'resp', 'resp_raw', 'acc', 'rt'};
dflt_trial_resp = {strings, strings, nan, nan};
recordings = [struct2table(config), ...
    cell2table( ...
    repmat([dflt_trial_timing, dflt_trial_resp], length(config), 1), ...
    'VariableNames', [vars_trial_timing, vars_trial_resp])];

% ---- configure screen and window ----
% setup default level of 2
PsychDefaultSetup(2);
% screen selection
screen_to_display = max(Screen('Screens'));
% set the start up screen to black
old_visdb = Screen('Preference', 'VisualDebugLevel', 1);
% do not skip synchronization test to make sure timing is accurate
old_sync = Screen('Preference', 'SkipSyncTests', 0);
% set priority to the top
old_pri = Priority(MaxPriority(screen_to_display));
% PsychDebugWindowConfiguration([], 0.1);

% ---- keyboard settings ----
keys.start = KbName('s');
keys.exit = KbName('Escape');
keys.left = KbName('LeftArrow');
keys.right = KbName('RightArrow');

% ---- stimuli presentation ----
try
    % open a window and set its background color as gray
    gray = WhiteIndex(screen_to_display) / 2;
    [window_ptr, window_rect] = PsychImaging('OpenWindow', screen_to_display, gray);
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name and size
    Screen('TextFont', window_ptr, 'SimHei');
    Screen('TextSize', window_ptr, 64);
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);
    % make grid buffer
    [center(1), center(2)] = RectCenter(window_rect);
    square_size = round(0.2 * RectHeight(window_rect));
    width_pen = round(0.005 * RectHeight(window_rect));
    width_halfpen = round(width_pen / 2);
    base_rect = [0, 0, 1, 1];
    [x, y] = meshgrid(-1.5:1:1.5, -1.5:1:1.5);
    grid_coords = round([x(:), y(:)] * square_size) + center;
    buffer_grid = Screen('OpenOffscreenWindow', window_ptr, gray);
    draw_grid(buffer_grid);

    % display welcome screen and wait for a press of 's' to start
    [welcome_img, ~, welcome_alpha] = ...
        imread(fullfile('image', 'welcome.png'));
    welcome_img(:, :, 4) = welcome_alpha;
    welcome_tex = Screen('MakeTexture', window_ptr, welcome_img);
    Screen('DrawTexture', window_ptr, welcome_tex);
    Screen('Flip', window_ptr);
    % the flag to determine if the experiment should exit early
    early_exit = false;
    % here we should detect for a key press and release
    while true
        [resp_timestamp, key_code] = KbStrokeWait(-1);
        if key_code(keys.start)
            start_time = resp_timestamp;
            break
        elseif key_code(keys.exit)
            early_exit = true;
            break
        end
    end
    % TODO: add instruction for practice

    % wait for start
    while true
        [~, ~, key_code] = KbCheck(-1);
        if key_code(keys.exit)
            early_exit = true;
            break
        end
        DrawFormattedText(window_ptr, double('请稍候...'), ...
            'center', 'center');
        vbl = Screen('Flip', window_ptr);
        if vbl >= start_time + config(1).stim_onset - 0.5 * ifi
            break
        end
    end
    for trial_order = 1:length(config)
        if early_exit
            break
        end

        this_trial = config(trial_order);
        % configure stimuli info
        switch stim_type
            case "digit"
                loc_coords = grid_coords(base_loc, :);
                stim_str = num2str(this_trial.stim);
            case "space"
                loc_coords = grid_coords(this_trial.stim, :);
                stim_str = num2str(base_digit);
        end

        % present stimuli
        resp_made = false;
        stim_status = 0;
        stim_color = [0, 0, 1];
        while true
            [key_pressed, timestamp, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
                break
            end
            Screen('DrawTexture', window_ptr, buffer_grid);
            if key_pressed
                if ~resp_made
                    resp_code = key_code;
                    resp_timestamp = timestamp;
                end
                resp_made = true;
            end
            if resp_made
                stim_fill_color = WhiteIndex(window_ptr);
            else
                stim_fill_color = gray;
            end
            if timestamp < start_time + this_trial.stim_offset
                draw_stimuli(true);
                vbl = Screen('Flip', window_ptr);
                if stim_status == 0
                    recordings.stim_onset_real(trial_order) = ...
                        vbl - start_time;
                    stim_status = 1;
                end
            else
                draw_stimuli(false);
                vbl = Screen('Flip', window_ptr);
                if stim_status == 1
                    recordings.stim_offset_real(trial_order) = ...
                        vbl - start_time;
                    stim_status = 2;
                end
            end
            if vbl >= start_time + this_trial.trial_end - 0.5 * ifi
                break
            end
        end
        % analyze user's response
        if ~resp_made
            resp_raw = "";
            resp = "none";
            resp_time = 0;
        else
            % use "|" as delimiter for the KeyName of "|" is "\\"
            resp_raw = string(strjoin(cellstr(KbName(resp_code)), '|'));
            if ~resp_code(keys.left) && ~resp_code(keys.right)
                resp = "neither";
            elseif resp_code(keys.left) && resp_code(keys.right)
                resp = "both";
            elseif resp_code(keys.left)
                resp = "left";
            else
                resp = "right";
            end
            resp_time = resp_timestamp - start_time - ...
                recordings.stim_onset_real(trial_order);
        end
        recordings.resp(trial_order) = resp;
        recordings.resp_raw(trial_order) = resp_raw;
        recordings.acc(trial_order) = this_trial.cresp == resp;
        recordings.rt(trial_order) = resp_time;

        if exp_phase == "prac"
            while true
                [~, ~, key_code] = KbCheck(-1);
                if key_code(keys.exit)
                    early_exit = true;
                    break
                end
                Screen('DrawTexture', window_ptr, buffer_grid);
                stim_color = WhiteIndex(window_ptr);
                if this_trial.cresp ~= resp
                    stim_fill_color = [1, 0, 0];
                    stim_str = double('×');
                else
                    stim_fill_color = [0, 1, 0];
                    stim_str = double('√');
                end
                draw_stimuli(true);
                vbl = Screen('Flip', window_ptr);
                if vbl >= start_time + this_trial.trial_end + ...
                        time_feedback_secs - 0.5 * ifi
                    break
                end
            end
        end
    end
catch exception
    status = 1;
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
Priority(old_pri);

if ~isempty(exception)
    rethrow(exception)
end

    function config = init_config()
        stims_pool = 1:16;
        trial_length = time_stimuli_secs + time_blank_secs;
        switch exp_phase
            case "prac"
                rng("shuffle")
                % there is feedback in practice
                trial_length = trial_length + time_feedback_secs;
                exp_onset = 0;
                num_trials = 10;
            case "test"
                rng(sum(char(stim_type)))
                exp_onset = time_wait_start_secs;
                num_trials = 20;
        end

        % --- randomise conditions ---
        n_filler = task_load;
        n_same = fix((num_trials - task_load) / 2);
        n_lure = fix((num_trials - task_load) / 4);
        n_diff = num_trials - n_filler - n_same - n_lure;
        stim_conds = [ ...
            repelem("same", n_same), ...
            repelem("lure", n_lure), ...
            repelem("diff", n_diff)];
        cond_okay = false;
        while ~cond_okay
            cond_okay = true;
            cond_order = [ ...
                repelem("filler", task_load), ...
                stim_conds(randperm(length(stim_conds)))];
            cresp_order = strings(1, num_trials);
            for i = 1:num_trials
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
            for i = (task_load + 1):num_trials
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
        stim_order = [ ...
            randsample(stims_pool, task_load, false), ...
            nan(1, num_trials - task_load)];
        for i = (task_load + 1):num_trials
            if cond_order(i) == "same"
                stim_order(i) = stim_order(i - task_load);
            else
                if cond_order(i) == "lure"
                    stims_sample = stim_order(i - (1:(task_load - 1)));
                else
                    stims_sample = setdiff(stims_pool, ...
                        stim_order(i - (1:task_load)));
                end
                stim_order(i) = randsample(stims_pool, 1, true, ...
                    ismember(stims_pool, stims_sample));
            end
        end

        % --- set timestamps ---
        stim_onset = exp_onset + ((1:num_trials) - 1) * trial_length;
        stim_offset = stim_onset + time_stimuli_secs;
        trial_end = stim_offset + time_blank_secs;

        config = arrayfun( ...
            @(i) struct( ...
            'stim', stim_order(i), ...
            'cond', cond_order(i), ...
            'cresp', cresp_order(i), ...
            'stim_onset', stim_onset(i), ...
            'stim_offset', stim_offset(i), ...
            'trial_end', trial_end(i)), ...
            1:num_trials);
    end

    function draw_grid(window)
        outer_border = CenterRectOnPoint( ...
            base_rect * (square_size * 4 + width_pen), ...
            center(1), center(2));
        fill_rects = CenterRectOnPoint( ...
            base_rect * (square_size - width_halfpen), ...
            grid_coords(:, 1), grid_coords(:, 2))';
        frame_rects = CenterRectOnPoint( ...
            base_rect * (square_size + width_halfpen), ...
            grid_coords(:, 1), grid_coords(:, 2))';
        Screen('FrameRect', window, WhiteIndex(window_ptr), ...
            outer_border, width_pen);
        Screen('FrameRect', window, WhiteIndex(window_ptr), ...
            frame_rects, width_pen);
        Screen('FillRect', window, BlackIndex(window_ptr), ...
            fill_rects);
    end

    function draw_stimuli(show_stim)
        rect = CenterRectOnPoint( ...
            base_rect * (square_size - width_halfpen), ...
            loc_coords(1), loc_coords(2));
        % shade the rect and present digit
        Screen('FillRect', window_ptr, stim_fill_color, ...
            rect);
        if show_stim
            text_bounds = Screen('TextBounds', window_ptr, stim_str);
            Screen('DrawText', window_ptr, stim_str, ...
                loc_coords(1) - round(text_bounds(3) / 2), ...
                loc_coords(2) - round(text_bounds(4) / 2), ...
                stim_color);
        end
    end

end
