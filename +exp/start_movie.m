function [status, exception, recordings] = start_movie(run, opts)
%START_MOVIE Start movie playing

arguments
    run {mustBeInteger, mustBePositive} = 1
    opts.id {mustBeInteger, mustBeNonnegative} = 0
    opts.SkipSyncTests (1, 1) {mustBeNumericOrLogical} = false
end

% ---- set default error related outputs ----
status = 0;
exception = [];

% get config for current run
config = readtable(fullfile('stimuli', 'movie', 'sequence.csv'));
config = config(config.run == run, :);
movie_names = cellfun( ...
    @(m) fullfile(pwd, 'stimuli', 'movie', [m, '.mp4']), ...
    config.movie, ...
    'UniformOutput', false);
rec_vars = {'movie_onset_real', 'movie_offset_real'};
rec_init = table('Size', [height(config), length(rec_vars)], ...
    'VariableTypes', repelem("doublenan", 2), ...
    'VariableNames', rec_vars);
recordings = horzcat(config, rec_init);

% set timing info
timing = struct('interval_secs', 10);

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

keys = struct( ...
    'start', KbName('s'), ...
    'exit', KbName('Escape'));

try
    % the flag to determine if the experiment should exit early
    early_exit = false;
    [window_ptr, window_rect] = PsychImaging('OpenWindow', screen_to_display, BlackIndex(screen_to_display));
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name
    Screen('TextFont', window_ptr, 'SimHei');
    Screen('TextSize', window_ptr, round(0.06 * RectHeight(window_rect)));
    DrawFormattedText(window_ptr, double('下面进入观看短片环节'), 'center', 'center', get_color('white'));
    Screen('Flip', window_ptr);
    % open the first movie
    Screen('OpenMovie', window_ptr, movie_names{1}, 1);
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

    % rest for 10 secs before going into movie
    while ~early_exit
        [~, ~, key_code] = KbCheck(-1);
        if key_code(keys.exit)
            early_exit = true;
            break
        end
        DrawFormattedText(window_ptr, double('休息'), 'center', 'center', get_color('white'));
        vbl = Screen('Flip', window_ptr);
        if vbl >= start_time + timing.interval_secs - 0.5 * ifi
            break
        end
    end

    for trial_order = 1:height(config)
        if early_exit
            break
        end
        % open movie
        movie = Screen('OpenMovie', window_ptr, movie_names{trial_order});
        % Start playback engine:
        Screen('PlayMovie', movie, 1, 0, 1);

        start_time_movie = nan;
        while ~early_exit
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
                break
            end
            % Wait for next movie frame, retrieve texture handle to it
            tex = Screen('GetMovieImage', window_ptr, movie);

            % Valid texture returned? A negative value means end of movie reached:
            if tex<=0
                end_time_movie = vbl;
                recordings.movie_offset_real(trial_order) = end_time_movie - start_time;
                % We're done, break out of loop:
                break;
            end

            % Draw the new texture immediately to screen:
            % calculate the real movie rect
            movie_asp = config.asp(trial_order);
            if isnan(movie_asp)
                movie_asp = 16 / 9;
            end
            movie_rect_base = [0, 0, RectWidth(window_rect), floor(RectWidth(window_rect) / movie_asp)];
            movie_rect_real = CenterRect(movie_rect_base, window_rect);
            Screen('DrawTexture', window_ptr, tex, [], movie_rect_real);

            % Update display:
            vbl = Screen('Flip', window_ptr);

            if isnan(start_time_movie)
                start_time_movie = vbl;
                recordings.movie_onset_real(trial_order) = start_time_movie - start_time;
            end

            % Release texture:
            Screen('Close', tex);
        end

        % Stop playback:
        Screen('PlayMovie', movie, 0);

        % Close movie:
        Screen('CloseMovie', movie);

        % rest for 10 secs before going next movie
        while ~early_exit
            [~, ~, key_code] = KbCheck(-1);
            if key_code(keys.exit)
                early_exit = true;
                break
            end
            DrawFormattedText(window_ptr, double('休息'), 'center', 'center', get_color('white'));
            vbl = Screen('Flip', window_ptr);
            if vbl >= end_time_movie + timing.interval_secs - 0.5 * ifi
                break
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
Screen('CloseAll');
sca;
% enable character input and show mouse cursor
ListenChar;
ShowCursor;

% restore preferences
Screen('Preference', 'VisualDebugLevel', old_visdb);
Screen('Preference', 'SkipSyncTests', old_sync);
Screen('Preference', 'TextRenderer', old_text_render);
Priority(old_pri);

utils.store_data(recordings, opts.id, "movie", run);

end
