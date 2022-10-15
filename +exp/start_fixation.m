function [status, exception] = start_fixation(opts)
%START_FIXATION Display fixation cross at the center of screen

arguments
    opts.Instruction {mustBeTextScalar} = '下面请盯着十字注视点休息'
    opts.Duration (1, 1) {mustBePositive} = 7.5
    opts.PostSlug (1, 1) {mustBePositive} = 5
    opts.SkipSyncTests (1, 1) {mustBeNumericOrLogical} = false
end

% ---- set default error related outputs ----
status = 0;
exception = [];

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

% ---- keyboard settings ----
keys = struct( ...
    'start', KbName('s'), ...
    'exit', KbName('Escape'));

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
    % display instruction
    DrawFormattedText(window_ptr, double(opts.Instruction), 'center', 'center');
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

    % display fixation
    while ~early_exit
        DrawFormattedText(window_ptr, '+', 'center', 'center', BlackIndex(window_ptr));
        vbl = Screen('Flip', window_ptr);
        if vbl >= start_time + opts.Duration * 60 + opts.PostSlug - 0.5 * ifi
            break
        end
        [~, ~, key_code] = KbCheck(-1);
        if key_code(keys.exit)
            early_exit = true;
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

end

