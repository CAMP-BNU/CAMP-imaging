function [recordings, status, exception] = start(phase, run, id)
%START_NBACK Starts stimuli presentation for n-back test
%   Detailed explanation goes here
arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test"])} = "prac"
    run {mustBeInteger, mustBePositive} = 1
    id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
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
    'feedback_secs', 0.5, ...
    'wait_start_secs', 2);

% ----prepare config and data recording table ----
config = init_config(phase, timing);
config = config(config.run_id == run, :);
recordings = config;

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
keys.start = KbName('s');
keys.exit = KbName('Escape');
keys.left = KbName('LeftArrow');
keys.right = KbName('RightArrow');

% ---- stimuli presentation ----
try
    % open a window and set its background color as gray
    gray = WhiteIndex(screen_to_display) / 2;
    window_ptr = PsychImaging('OpenWindow', screen_to_display, gray);
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name
    Screen('TextFont', window_ptr, 'SimHei');
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);

    % display welcome screen and wait for a press of 's' to start
    switch phase
        case "prac"
            instr = '下面我们开始练习部分';
        case "test"
            instr = '下面我们进行正式测试';
    end
    draw_text_center_at(window_ptr, instr, size=0.03);
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
    while ~early_exit && phase == "test"
        draw_text_center_at(window_ptr, '请稍候...');
        vbl = Screen('Flip', window_ptr);
        if vbl >= start_time + timing.wait_start_secs - 0.5 * ifi
            break
        end
        [~, ~, key_code] = KbCheck(-1);
        if key_code(keys.exit)
            early_exit = true;
        end
    end

    for trial_order = 1:height(config)
        if early_exit
            break
        end
        this_trial = config(trial_order, :);
        % basic routine
        [resp_collected, timing_real] = routine_collect_response(this_trial);
        resp_result = analyze_response(resp_collected);

        % record response
        recordings.stim_onset_real(trial_order) = timing_real.stim_onset;
        recordings.stim_offset_real(trial_order) = timing_real.stim_offset;
        recordings.resp(trial_order) = resp_result.name;
        recordings.resp_raw(trial_order) = resp_result.raw;
        recordings.acc(trial_order) = this_trial.cresp == resp_result.name;
        recordings.rt(trial_order) = resp_result.time;

        % give feedback when in practice
        if phase == "prac"
            show_feedback(resp_result, this_trial.cresp, this_trial.trial_end)
        end

        % show fixation when next trial end cur run or enter into new block 
        if trial_order == height(config) || ...
                config.block_id(trial_order + 1) ~= this_trial.block_id
            while ~early_exit
                draw_text_center_at(window_ptr, "+")
                vbl = Screen('Flip', window_ptr);
                if vbl >= start_time + this_trial.trial_end + ...
                        timing.feedback_secs * (phase == "prac") + ...
                        timing.fixation_secs.(phase) - 0.5 * ifi
                    break
                end
                [~, ~, key_code] = KbCheck(-1);
                if key_code(keys.exit)
                    early_exit = true;
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
Screen('Preference', 'TextRenderer', old_text_render);
Priority(old_pri);

if ~isempty(exception)
    rethrow(exception)
end

    function [resp_collected, timing_real] = routine_collect_response(trial)
        % present stimuli
        resp_made = false;
        resp_code = nan;
        stim_onset_real = nan;
        stim_offset_real = nan;
        resp_timestamp = nan;
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
            if timestamp < start_time + trial.stim_offset
                % add stimuli
                draw_text_center_at(window_ptr, '练习')
                vbl = Screen('Flip', window_ptr);
                if isnan(stim_onset_real)
                    stim_onset_real = vbl - start_time;
                end
            else
                vbl = Screen('Flip', window_ptr);
                if isnan(stim_offset_real)
                    stim_offset_real = vbl - start_time;
                end
            end
            if vbl >= start_time + trial.trial_end - 0.5 * ifi
                break
            end
        end
        resp_collected = struct( ...
            'made', resp_made, ...
            'code', resp_code, ...
            'time', resp_timestamp - start_time - stim_onset_real );
        timing_real = struct( ...
            'stim_onset', stim_onset_real, ...
            'stim_offset', stim_offset_real);
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
            if ~resp_code(keys.left) && ~resp_code(keys.right)
                resp_name = "neither";
            elseif resp_code(keys.left) && resp_code(keys.right)
                resp_name = "both";
            elseif resp_code(keys.left)
                resp_name = "left";
            else
                resp_name = "right";
            end
            resp_time = resp_collected.time;
        end
        resp_result = struct( ...
            'raw', resp_raw, ...
            'name', resp_name, ...
            'time', resp_time);
    end

    function show_feedback(resp_result, cresp, trial_end)
        while ~early_exit
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
                break
            end

            if cresp ~= resp_result.name
                fb.color = get_color('red');
                if resp_result.name == "none"
                    fb.text = '超时';
                elseif cresp == "none"
                    fb.text = '前两个试次不能作答';
                else
                    fb.text = '错误';
                end
            else
                fb.color = get_color('green');
                fb.text = '正确';
            end
            draw_text_center_at(window_ptr, fb.text, Color=fb.color)
            vbl = Screen('Flip', window_ptr);
            if vbl >= start_time + trial_end + timing.feedback_secs - 0.5 * ifi
                break
            end
        end
    end
end

function draw_text_center_at(w, string, opts)
%DRAW_TEXT_CENTER_AT Better control text position.
%
% Input:
%   w: Window pointer
%   string: The text to draw. Must be scalar text.
%   Name-value pairs:
%       Position: the position to draw text.
%       Color: the text color.
%       Size: the text size.
arguments
    w
    string {mustBeTextScalar}
    opts.Position = "center"
    opts.Color = BlackIndex(w)
    opts.Size = 0.06
end

% DrawText only accept char type
string = double(char(string));
window_rect = Screen('Rect', w);
size = opts.Size;
color = opts.Color;
if isequal(opts.Position, "center")
    [x, y] = RectCenter(window_rect);
else
    x = opts.Position(1);
    y = opts.Position(2);
end
Screen('TextSize', w, round(size * RectHeight(window_rect)));
text_bounds = Screen('TextBounds', w, string);
Screen('DrawText', w, string, ...
    x - round(text_bounds(3) / 2), ...
    y - round(text_bounds(4) / 2), ...
    color);
end
