function [recordings, status, exception] = start_twoback(phase, run, opts)
%START_NBACK Starts stimuli presentation for n-back test
%   Detailed explanation goes here
arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test"])} = "prac"
    run {mustBeInteger, mustBePositive} = 1
    opts.id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
    opts.SaveData (1, 1) {mustBeNumericOrLogical} = true
end

import exp.init_config

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
old_sync = Screen('Preference', 'SkipSyncTests', 0);
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
            [instr, ~, intsr_alpha] = imread(fullfile('image', 'instr.png'));
            instr(:, :, 4) = intsr_alpha;
            instr_tex = Screen('MakeTexture', window_ptr, instr);
            Screen('DrawTexture', window_ptr, instr_tex, [], window_rect)
        case "test"
            instr = '下面我们进行正式测试';
            DrawFormattedText(window_ptr, double(instr), 'center', 'center');
    end
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
Screen('Preference', 'TextRenderer', old_text_render);
Priority(old_pri);

if opts.SaveData
    writetable(recordings, fullfile('data', ...
        sprintf('2back-phase_%s-sub_%03d-run_%d-time_%s.csv', ...
        phase, opts.id, run, datetime("now", "Format", "yyyyMMdd_HHmmss"))))
end

if ~isempty(exception)
    rethrow(exception)
end

    function [resp_collected, timing_real] = collect_response(trial)
        % this might be time consumig
        stim_file = [num2str(trial.stim), '.jpg'];
        stim_pic = imread(fullfile('stimuli', trial.stim_type, stim_file));
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
