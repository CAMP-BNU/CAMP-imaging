function [recordings, status, exception] = start(task_config, id)
%START_NBACK Starts stimuli presentation for n-back test
%   Detailed explanation goes here
arguments
    task_config {mustBeTextScalar, mustBeMember(task_config, ["prac_nback", "prac_manip", "prac", "test"])} = "prac_nback"
    id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
end

import exp.init_config

% ---- set default error related outputs ----
status = 0;
exception = [];

% ---- set experiment timing parameters (predefined here, all in secs) ----
timing = struct( ...
    'nback_stim_secs', 1, ...
    'nback_blank_secs', 1.5, ...
    'manip_encoding_secs', 3, ...
    'manip_cue_secs', 3, ...
    'manip_probe_secs', 1, ...
    'manip_blank_secs', 1.5, ...
    'block_cue_secs', 2, ...
    'feedback_secs', 0.5, ...
    'wait_start_secs', 2);

% ----prepare config and data recording table ----
if task_config ~= "debug"
    config = init_config(task_config, timing, id);
    recordings = addvars(config, ...
        nan(height(config), 1), cell(height(config), 1), ...
        NewVariableNames={'block_onset_real', 'trials_rec'});
end

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
    [window_ptr, window_rect] = PsychImaging('OpenWindow', screen_to_display, gray);
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name
    Screen('TextFont', window_ptr, 'SimHei');
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
    switch task_config
        case "prac_nback"
            instr = '下面我们练习一下“N-back”任务';
        case "prac_manip"
            instr = '下面我们练习一下"表象操作”任务';
        case "prac"
            instr = '下面我们将两种任务合在一起一起练习';
        case "test"
            instr = '下面我们将进行"N-back"任务和"表象操作”任务';
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
    while ~early_exit && task_config == "test"
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
    for block_order = 1:height(config)
        if early_exit
            break
        end
        cur_block = config(block_order, :);

        % cue for each block: task name and domain
        stim_type_name = char(categorical(cur_block.stim_type, ...
            ["digit", "space"], ["数字", "空间"]));
        switch cur_block.task_name
            case "nback"
                task_disp_name = char(cur_block.task_load + "-Back");
            case "manip"
                task_disp_name = '操作';
            otherwise
                error('exp:start:invalid_task_name', ...
                    'Invalid game name! "nback" and "manip" are supported!')
        end
        start_time_block = start_time + cur_block.block_onset;
        block_onset_real = nan;
        while ~early_exit
            draw_text_center_at(window_ptr, stim_type_name, ...
                Position=[center(1), center(2) - 0.06 * RectHeight(window_rect)], ...
                Color=get_color('dark orange'));
            draw_text_center_at(window_ptr, task_disp_name, ...
                Position=[center(1), center(2) + 0.06 * RectHeight(window_rect)], ...
                Color=get_color('red'));
            vbl = Screen('Flip', window_ptr);
            if isnan(block_onset_real)
                block_onset_real = vbl - start_time;
            end
            if vbl >= start_time_block + timing.block_cue_secs - 0.5 * ifi
                break
            end
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
            end
        end
        recordings.block_onset_real(block_order) = block_onset_real;

        % presenting trials
        cur_block_trials = config.trials{block_order};
        switch cur_block.task_name
            case "nback"
                trials_rec = table( ...
                    'Size', [height(cur_block_trials), 6], ...
                    'VariableTypes', [repelem({'double'}, 4), repelem({'string'}, 2)], ...
                    'VariableNames', ...
                    {'stim_onset_real', 'stim_offset_real', ...
                    'acc', 'rt', 'resp', 'resp_raw'});
            case "manip"
                trials_rec = table( ...
                    'Size', [height(cur_block_trials), 8], ...
                    'VariableTypes', [repelem({'double'}, 2), repelem({'cell'}, 6)], ...
                    'VariableNames',  ...
                    {'encoding_onset_real', 'cue_onset_real', ...
                    'probe_onset_real', 'probe_offset_real', ...
                    'acc', 'rt', 'resp', 'resp_raw'});
        end
        
        for trial_order = 1:height(cur_block_trials)
            if early_exit
                break
            end
            this_trial = cur_block_trials(trial_order, :);
            switch cur_block.task_name
                case "nback"
                    routine_nback()
                case "manip"
                    routine_manip()
            end
        end
        recordings.trials_rec{block_order} = trials_rec;
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

    function routine_nback()
        % configure stimuli info
        stim = struct( ...
            'loc', grid_coords(this_trial.location, :), ...
            'fill', gray, ...
            'text', num2str(this_trial.number), ...
            'color', get_color('blue'));

        % present stimuli
        [resp_collected, timing_real] = routine_collect_response(stim, ...
            this_trial.stim_offset, this_trial.trial_end);
        resp_result = analyze_response(resp_collected);
        trials_rec.stim_onset_real(trial_order) = timing_real.stim_onset;
        trials_rec.stim_offset_real(trial_order) = timing_real.stim_offset;
        trials_rec.resp(trial_order) = resp_result.name;
        trials_rec.resp_raw(trial_order) = resp_result.raw;
        trials_rec.acc(trial_order) = this_trial.cresp == resp_result.name;
        trials_rec.rt(trial_order) = resp_result.time;

        % give feedback when in practice
        if contains(task_config, "prac")
            show_feedback(resp_result, this_trial.cresp, this_trial.trial_end)
        end
    end

    function routine_manip()
        % prepare encoding stimuli configuration
        encoding = arrayfun( ...
            @(i) ...
            struct( ...
            'loc', grid_coords(this_trial.encoding_location{:}(i), :), ...
            'fill', gray, ...
            'text', num2str(this_trial.encoding_number{:}(i)), ...
            'color', get_color('blue')), ...
            1:cur_block.task_load);
        
        % present encoding stimuli
        encoding_onset_real = nan;
        while ~early_exit
            Screen('DrawTexture', window_ptr, buffer_grid);
            draw_stimuli(encoding);
            vbl = Screen('Flip', window_ptr);
            if isnan(encoding_onset_real)
                encoding_onset_real = vbl - start_time_block;
            end
            if vbl >= start_time_block + this_trial.cue_onset - 0.5 * ifi
                break
            end
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
            end
        end
        trials_rec.encoding_onset_real(trial_order) = encoding_onset_real;

        % present cue
        cue_onset_real = nan;
        while ~early_exit
            draw_text_center_at(window_ptr, this_trial.cue, ...
                Color = get_color('green'))
            [~, ~, key_code] = KbCheck(-1);
            vbl = Screen('Flip', window_ptr);
            if isnan(cue_onset_real)
                cue_onset_real = vbl - start_time_block;
            end
            if vbl >= start_time_block + this_trial.probe_onset{:}(1) - 0.5 * ifi
                break
            end
            if key_code(keys.exit)
                early_exit = true;
            end
        end
        trials_rec.cue_onset_real(trial_order) = cue_onset_real;

        % present probes
        for i_probe = 1:length(this_trial.probe_number{:})
            if early_exit
                break
            end
            probe = struct( ...
                'loc', grid_coords(this_trial.probe_location{:}(i_probe), :), ...
                'fill', gray, ...
                'text', num2str(this_trial.probe_number{:}(i_probe)), ...
                'color', get_color('blue'));
            [resp_collected, timing_real] = routine_collect_response(probe, ...
                this_trial.probe_offset{:}(i_probe), ...
                this_trial.trial_end{:}(i_probe));
            resp_result = analyze_response(resp_collected);
            trials_rec.probe_onset_real{trial_order}(i_probe) = timing_real.stim_onset;
            trials_rec.probe_offset_real{trial_order}(i_probe) = timing_real.stim_offset;
            trials_rec.resp{trial_order}(i_probe) = resp_result.name;
            trials_rec.resp_raw{trial_order}(i_probe) = resp_result.raw;
            trials_rec.acc{trial_order}(i_probe) = this_trial.cresp{:}(i_probe) == resp_result.name;
            trials_rec.rt{trial_order}(i_probe) = resp_result.time;

            if contains(task_config, "prac")
                show_feedback(resp_result, ...
                    this_trial.cresp{:}(i_probe), ...
                    this_trial.trial_end{:}(i_probe))
            end
        end
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

    function draw_stimuli(stims)
        for stim = stims
            rect = CenterRectOnPoint( ...
                base_rect * (square_size - width_halfpen), ...
                stim.loc(1), stim.loc(2));
            % shade the rect and present digit
            Screen('FillRect', window_ptr, stim.fill, rect);
            draw_text_center_at(window_ptr, stim.text, ...
                Position=stim.loc, Color=stim.color);
        end
    end

    function [resp_collected, timing_real] = routine_collect_response(stim, stim_offset, trial_end)
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
            Screen('DrawTexture', window_ptr, buffer_grid);
            if timestamp < start_time_block + stim_offset
                draw_stimuli(stim);
                vbl = Screen('Flip', window_ptr);
                if isnan(stim_onset_real)
                    stim_onset_real = vbl - start_time_block;
                end
            else
                vbl = Screen('Flip', window_ptr);
                if isnan(stim_offset_real)
                    stim_offset_real = vbl - start_time_block;
                end
            end
            if vbl >= start_time_block + trial_end - 0.5 * ifi
                break
            end
        end
        resp_collected = struct( ...
            'made', resp_made, ...
            'code', resp_code, ...
            'time', resp_timestamp - start_time_block - stim_onset_real );
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
            Screen('DrawTexture', window_ptr, buffer_grid);
            fb.loc = center;
            fb.color = WhiteIndex(window_ptr);
            if cresp ~= resp_result.name
                fb.fill = get_color('red');
                if resp_result.name == "none"
                    fb.text = '?';
                else
                    fb.text = '×';
                end
            else
                fb.fill = get_color('green');
                fb.text = '√';
            end
            draw_stimuli(fb);
            vbl = Screen('Flip', window_ptr);
            if vbl >= start_time_block + trial_end + timing.feedback_secs - 0.5 * ifi
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
