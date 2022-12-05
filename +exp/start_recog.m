function [status, exception, recordings] = start_recog(opts)
%START_NBACK Starts stimuli presentation for n-back test
%   Detailed explanation goes here
arguments
    opts.id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
    opts.SaveData (1, 1) {mustBeNumericOrLogical} = true
    opts.SkipSyncTests (1, 1) {mustBeNumericOrLogical} = false
end

import exp.init_config

% ---- set default error related outputs ----
status = 0;
exception = [];

% ---- set experiment timing parameters (predefined here, all in secs) ----
timing = struct( ...
    'stim_secs', 4, ...
    'blank_secs', 0.5, ...
    'rest_secs', 10);

% ----prepare config and data recording table ----
config = readtable(fullfile('stimuli', 'seq_post.csv'), 'TextType', 'string');
rec_vars = {'acc', 'rt', 'resp', 'resp_raw'};
rec_init = table('Size', [height(config), length(rec_vars)], ...
    'VariableTypes', [repelem("doublenan", 2), repelem("string", 2)], ...
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
keys = dictionary( ...
    'start', KbName('s'), ...
    'exit', KbName('Escape'), ...
    '1', KbName('1!'), ... % definitely old
    '2', KbName('2@'), ... % old
    '3', KbName('3#'), ... % sort of old
    '4', KbName('4$'), ... % sort of new
    '5', KbName('5%'), ... % new
    '6', KbName('6^') ...  % definitely new
    );

% ---- stimuli presentation ----
try
    % the flag to determine if the experiment should exit early
    early_exit = false;
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
    instr = '下面我们进行记忆再认测试';
    DrawFormattedText(window_ptr, double(instr), 'center', 'center');
    Screen('Flip', window_ptr);
    % here we should detect for a key press and release
    while ~early_exit
        [~, key_code] = KbStrokeWait(-1);
        if key_code(keys('start'))
            break
        elseif key_code(keys('exit'))
            early_exit = true;
        end
    end

    % main experiment
    for trial_order = 1:height(config)
        if early_exit
            break
        end
        this_trial = config(trial_order, :);
        % basic routine
        resp_collected = collect_response(this_trial);
        resp_result = analyze_response(resp_collected);

        % record response
        if this_trial.cresp == "new"
            acc = ismember(resp_result.name, ["4", "5", "6"]);
        else
            acc = ismember(resp_result.name, ["1", "2", "3"]);
        end
        recordings.acc(trial_order) = acc;
        recordings.rt(trial_order) = resp_result.time;
        recordings.resp(trial_order) = resp_result.name;
        recordings.resp_raw(trial_order) = resp_result.raw;

        % next trial will begin next block, rest till user stroke 's'
        if trial_order < height(config) && ...
                config.block_id(trial_order + 1) ~= this_trial.block_id
            DrawFormattedText(window_ptr, double('休息一下'), ...
                'center', 'center', BlackIndex(window_ptr));
            start_time_rest = Screen('Flip', window_ptr);
            while ~early_exit
                [~, timestamp, key_code] = KbCheck(-1);
                if key_code(keys('exit'))
                    early_exit = true;
                end
                if timestamp > start_time_rest + timing.rest_secs - 0.5 * ifi
                    break
                end
            end
            DrawFormattedText(window_ptr, double('休息结束\n按s键继续'), ...
                'center', 'center', BlackIndex(window_ptr));
            Screen('Flip', window_ptr);
            while ~early_exit
                [~, key_code] = KbStrokeWait(-1);
                if key_code(keys('start'))
                    break
                elseif key_code(keys('exit'))
                    early_exit = true;
                    break
                end
            end
        end
    end
catch exception
    status = 1;
end

if early_exit
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
    writetable(recordings, fullfile('data', ...
        sprintf('recog-sub_%03d-time_%s.csv', ...
        opts.id, datetime("now", "Format", "yyyyMMdd_HHmmss"))))
end

    function resp_collected = collect_response(trial)
        % this might be time consumig
        if trial.cresp ~= "similar"
            stim_file = [num2str(trial.stim), '.jpg'];
        else % use the similar copy
            stim_file = [num2str(trial.stim), 'b.jpg'];
        end
        stim_pic = imread(fullfile('stimuli', trial.stim_type, stim_file));
        stim = Screen('MakeTexture', window_ptr, stim_pic);

        % present stimuli
        resp_made = false;
        resp_code = nan;
        stim_onset_stamp = nan;
        resp_timestamp = nan;
        start_time_trial = GetSecs;
        while ~early_exit
            Screen('DrawTexture', window_ptr, stim, [], stim_rect);
            vbl = Screen('Flip', window_ptr);
            if isnan(stim_onset_stamp)
                stim_onset_stamp = vbl;
            end
            [key_pressed, timestamp, key_code] = KbCheck(-1);
            if key_code(keys('exit'))
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
            if resp_made || ...
                    vbl >= start_time_trial + timing.stim_secs - 0.5 * ifi
                stim_offset_stamp = vbl;
                break
            end
        end

        % inter trial interval: blank screen
        while ~early_exit
            vbl = Screen('Flip', window_ptr);
            if vbl >= stim_offset_stamp + timing.blank_secs - 0.5 * ifi
                break
            end
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys('exit'))
                early_exit = true;
            end
        end
        resp_collected = struct( ...
            'made', resp_made, ...
            'code', resp_code, ...
            'time', resp_timestamp - stim_onset_stamp);
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
            valid_names = {'1', '2', '3', '4', '5', '6'};
            valid_codes = cellfun(@(x) keys(x), valid_names);
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
end
