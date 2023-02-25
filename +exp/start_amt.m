function [Result,distractTaskResult,dispResult] = start_amt(phase, run, opts)

arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test"])} = "prac"
    run {mustBeInteger, mustBePositive} = 1
    opts.id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
    opts.SkipSyncTests (1, 1) {mustBeNumericOrLogical} = false
end

%% screen setting

%experimentStart = GetSecs;
rng(1205);

Screen('Preference','SkipSyncTests',double(opts.SkipSyncTests)); 

PsychDefaultSetup(2);

screenNumber = max(Screen('Screens'));

bgColor = [128 128 128];

[wPtr, rect] = Screen('OpenWindow',screenNumber,bgColor);
[xCenter, yCenter] = WindowCenter(wPtr);
ifi = Screen('GetFlipInterval', wPtr);
Screen('TextFont',wPtr,'SimHei');
Screen('TextSize',wPtr,round(0.06*RectHeight(rect)));

Priority(1);

Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); 

%% basic setting of the task

%实验流程的基本设置
trialNum = 12;%每个block的trial数
blockNum = 8;%总共多少block
presentTime = 2;%每个object呈现2s
sampledelayTime = 2;%每个object之间的间隔

%刺激数
objectNum=12;

%注视点和context设置
crossWidth = 2; 
crossColor = [0 0 0];
crossLengthPixels = 20;
crossLines = [-crossLengthPixels crossLengthPixels 0 0; 0 0 -crossLengthPixels crossLengthPixels];%注视点设置
rectlineColor = [0 0 0];
contextTexture = cell(1,4);
for context = 1:4
    fileName = [pwd '/stimuli/context/context' num2str(context) '.jpg'];
    contextImage = imread(fileName);
    contextTexture{context} = Screen('MakeTexture',wPtr,contextImage);
end

%baseline task阶段的基本设置
baselineTaskduration =12;%总共进行多久的baseline task
baselineTaskinterval = 0.2;%trial之间的间隔
shortestinterval = 0.3;%两次按键反应之间的最小间距

%probe阶段设置
probeDispTime = 4;
contestTestTime = 1.5;
positionTestTime = 2.5;
currentRectColor = [0 255 0];
contextInfo = '森林=1,公路=2,雪山=9,海底=0';
minimalinterval = 0.2;

%practice设置
pracblockNum = 2;
feedbackTime = 1;
correctColor = [0 255 0];
wrongColor = [255 0 0];

%载入practice和formal阶段的相关序列以及刺激呈现的位置
load([pwd '/stimuli/formal_experiment_information.mat']);
load([pwd '/stimuli/practice_information.mat']);
load([pwd '/stimuli/rect_location_information.mat']);
rectsNum = length(Rects);

%% practice

if phase == "prac"

    ListenChar(2);
    HideCursor;
    instractor = '下面将进行联系记忆实验的练习，准备好后按s开始';
    DrawFormattedText(wPtr,double(instractor),'center','center',[0 0 0]);
    Screen('Flip',wPtr);

    while 1
        [ ~ , keycode] = KbStrokeWait();
        if keycode(KbName('s'))%按s开始
            break
        end
    end
    Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
    [~,delayStartTime] = Screen('Flip',wPtr);

    %绘制所有sample的texture
    pracsampleTextture = cell(1,objectNum);
    for obj = 1:12
        object_pic_name = [pwd '/stimuli/item/' num2str(obj+12) '.jpg'];
        pic = imread(object_pic_name);
        pracsampleTextture{obj} =  Screen('MakeTexture',wPtr,pic);
    end
    clear pic obj object_pic_name

    %TimeInfo = zeros(pracblockNum,4);
    %learningPhaseTimeMat = zeros(pracblockNum*12,2);
    responseMat = [trialNum*pracblockNum,12];%probe呈现时间，test1开始时间，反应时间，选择背景，实际背景，是否正确，test2开始时间，test2被试第一次按键时间，test反应时间，所选位置，实际位置，是否正确

    for block = 1:pracblockNum

        startposList = Shuffle([5*ones(1,trialNum/2),8*ones(1,trialNum/2)]);

        for trial = 1:12
            trialSeq = (block-1)*12+trial;
            %绘制context
            context = prac_sample_mat(trialSeq,3);
            Screen('DrawTexture',wPtr,contextTexture{context},[],RectsEdge);

            %绘制sample
            sample_object_seq = prac_sample_mat(trialSeq,1);
            sample_disp_rect_seq = prac_object_rect_seq(prac_sample_mat(trialSeq,2));
            sample_disp_rect = Rects(:,sample_disp_rect_seq)';
            Screen('DrawTexture',wPtr,pracsampleTextture{sample_object_seq-12},[],sample_disp_rect);

            %绘制矩形边框
            Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
            Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);

            if block == 1
                [~,sampleDispTime] = Screen('Flip',wPtr,delayStartTime+sampledelayTime-ifi);
            elseif trial == 1
                [~,sampleDispTime] = Screen('Flip',wPtr,feedbackTime+feedbackStartTime-ifi);
            else
                [~,sampleDispTime] = Screen('Flip',wPtr,delayStartTime+sampledelayTime-ifi);
            end
            %learningPhaseTimeMat(trialSeq,1) =  sampleDispTime;
%             if trial == 1
%                 learningPhaseStratTime = sampleDispTime;
%             end

            Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
            [~,delayStartTime] = Screen('Flip',wPtr,sampleDispTime+presentTime-ifi);
            %learningPhaseTimeMat(trialSeq,2) =  delayStartTime;
        end

        if block == 1
            baseLineMat = [];%trial,arrowtype,disptime,reponse,responsetime,iscorrect,RT
            baseline_trial_seq = 0;
        end
        currentTime = GetSecs;
        baseline_task_start = 0;

       while currentTime<baselineTaskduration+sampledelayTime-1.5*ifi+delayStartTime
            if baseline_task_start ~=0
                Screen('Flip',wPtr);
            end
            baseline_trial_seq = baseline_trial_seq+1;
            baseLineMat(baseline_trial_seq,:) = zeros(1,8);
            baseLineMat(baseline_trial_seq,1) = baseline_trial_seq;

            %获取箭头
            arrowDir = randperm(4,1);
            baseLineMat(baseline_trial_seq,2) = arrowDir;
            switch arrowDir
                case 1
                    arrow = '←';
                case 2
                    arrow = '→';
                case 3
                    arrow = '↑';
                case 4
                    arrow = '↓';
            end
            DrawFormattedText(wPtr,double(arrow),'center','center',[0 0 0]);

            if baseline_task_start ==0
                baseline_task_start = 1;
                responseTime = 0;
                [~,arrowStartTime] = Screen('Flip',wPtr,delayStartTime+sampledelayTime-ifi);
                baselineTaskStart = arrowStartTime;
            else
                [~,arrowStartTime] = Screen('Flip',wPtr,responseTime+baselineTaskinterval-ifi);
            end
            baseLineMat(baseline_trial_seq,3) = arrowStartTime;

            resp_made = 0;
            while ~resp_made
                [key_pressed, currentTime, keycode] = KbCheck(-1);
                if key_pressed && currentTime-responseTime>shortestinterval
                    if ~resp_made
                        if keycode(KbName('1!'))
                            response = 1;
                            responseTime = currentTime;
                            resp_made = 1;
                        elseif keycode(KbName('0)'))
                            response = 2;
                            responseTime = currentTime;
                            resp_made = 1;
                        elseif keycode(KbName('2@'))
                            response = 3;
                            responseTime = currentTime;
                            resp_made = 1;
                        elseif keycode(KbName('9('))
                            response = 4;
                            responseTime = currentTime;
                            resp_made = 1;
                        else
                            response = -1;
                            responseTime = currentTime;
                            resp_made = 1;
                        end
                    end
                end
                if currentTime >= baselineTaskduration+sampledelayTime-1.5*ifi+delayStartTime
                    response = 0;
                    break
                end
            end

            baseLineMat(baseline_trial_seq,4) = response;
            baseLineMat(baseline_trial_seq,5) = responseTime;
            baseLineMat(baseline_trial_seq,6) = (response == arrowDir);
            baseLineMat(baseline_trial_seq,7) = responseTime-arrowStartTime;
            baseLineMat(baseline_trial_seq,8) = block;
        end
        baselineTaskEnd = GetSecs;

        firstTrial = 1;
        for trial = 1:12
            trialSeq = (block-1)*12+trial;
            %绘制sample
            Screen('DrawTexture',wPtr,pracsampleTextture{pracprobeMat(trialSeq,1)-12},[],testSampleLoc);

            if firstTrial == 1
                firstTrial = 0;
                [~,probeStart] = Screen('Flip',wPtr,delayStartTime++baselineTaskduration+sampledelayTime-ifi);
                probePhaseStartTime = probeStart;
            else
                [~,probeStart] = Screen('Flip',wPtr,feedbackStartTime+feedbackTime-ifi);
            end

            DrawFormattedText(wPtr,double(contextInfo),'center','center',[0 0 0]);
            [~,test1Start] = Screen('Flip',wPtr,probeStart+probeDispTime-ifi);

            resp_made = 0;
            while 1
                [key_pressed, currentTime, keycode] = KbCheck(-1);
                if key_pressed
                    if ~resp_made
                        if keycode(KbName('1!'))
                            choosedContext = 1;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        elseif keycode(KbName('2@'))
                            choosedContext = 2;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        elseif keycode(KbName('9('))
                            choosedContext = 3;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        elseif keycode(KbName('0)'))
                            choosedContext = 4;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        end

                    end
                end
                if currentTime >= test1Start+contestTestTime-ifi
                    break
                end
            end
            if resp_made == 0
                choosedContext = 0;
                t1responseTime = 0;
            end

            if choosedContext == pracprobeMat(trialSeq,3) && choosedContext~=0
                conisCorrect = 1;
                feedback = 'Correct';
                feedbackColor = correctColor;
            elseif choosedContext~=0
                conisCorrect = 0;
                feedback = 'Wrong';
                feedbackColor = wrongColor;
            else
                conisCorrect = -1;
                feedback = 'Be Quick!';
                feedbackColor = wrongColor;
            end
            DrawFormattedText(wPtr,double(feedback),'center','center',feedbackColor);
            feedbackStartTime = Screen('Flip', wPtr);


            randomStartSeq = startposList(trial);
            randomStartRect = Rects(:,randomStartSeq)';
            Screen('FillRect',wPtr,currentRectColor,randomStartRect);
            Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
            Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);
            [~,test2Start] = Screen('Flip',wPtr,feedbackStartTime+feedbackTime-ifi);

            currentChoosedSeq = randomStartSeq;
            firstInput = 1;
            t2responseTime = 0;
            test2firstInput = 0;
            while 1
                [key_pressed,currentTime, keycode] = KbCheck(-1);
                if key_pressed && currentTime-t2responseTime>minimalinterval
                    if firstInput
                        test2firstInput = currentTime;
                        firstInput = 0;
                    end
                    if keycode(KbName('2@'))
                        currentChoosedSeq = mod(currentChoosedSeq-1,rectsNum);
                        if mod(currentChoosedSeq,3) == 0
                            currentChoosedSeq = currentChoosedSeq+3;
                        end
                        t2responseTime = currentTime;
                    elseif keycode(KbName('9('))
                        currentChoosedSeq = mod(currentChoosedSeq+1,rectsNum);
                        if mod(currentChoosedSeq,3) == 1
                            currentChoosedSeq = currentChoosedSeq-3;
                        end
                        t2responseTime = currentTime;
                    elseif keycode(KbName('1!'))
                        currentChoosedSeq = mod(currentChoosedSeq-3,rectsNum);
                        t2responseTime = currentTime;
                    elseif keycode(KbName('0)'))
                        currentChoosedSeq = mod(currentChoosedSeq+3,rectsNum);
                        t2responseTime = currentTime;
                    end
                    if currentChoosedSeq <= 0
                        currentChoosedSeq = currentChoosedSeq+rectsNum;
                    end
                    currentRect = Rects(:,currentChoosedSeq)';
                    Screen('FillRect',wPtr,currentRectColor,currentRect);
                    Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
                    Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);
                    Screen('Flip', wPtr);
                    currentTime = GetSecs;
                end
                if currentTime>=test2Start+positionTestTime-ifi
                    break
                end
            end

            if currentChoosedSeq == prac_object_rect_seq(pracprobeMat(trialSeq,2))
                posisCorrect = 1;
                feedback = 'Correct';
                feedbackColor = correctColor;
            else
                posisCorrect = 0;
                feedback = 'Wrong';
                feedbackColor = wrongColor;
            end
            DrawFormattedText(wPtr,double(feedback),'center','center',feedbackColor);
            feedbackStartTime = Screen('Flip', wPtr);

            responseMat(trialSeq,1) = probeStart;
            responseMat(trialSeq,2) = test1Start;
            responseMat(trialSeq,3) = t1responseTime;
            responseMat(trialSeq,4) = choosedContext;
            responseMat(trialSeq,5) = pracprobeMat(trialSeq,3);
            responseMat(trialSeq,6) = conisCorrect;
            responseMat(trialSeq,7) = test2Start;
            responseMat(trialSeq,8) = test2firstInput;
            responseMat(trialSeq,9) = t2responseTime;
            responseMat(trialSeq,10) = currentChoosedSeq;
            responseMat(trialSeq,11) = prac_object_rect_seq(pracprobeMat(trialSeq,2));
            responseMat(trialSeq,12) = posisCorrect;

        end

    %TimeInfo(block,:) = [learningPhaseStratTime baselineTaskStart baselineTaskEnd probePhaseStartTime];
    end

     finished = '您已完成本练习，按任意键退出';
     DrawFormattedText(wPtr,double(finished),'center','center',[0 0 0]);
     Screen('Flip',wPtr,feedbackStartTime+feedbackTime-ifi);
     KbStrokeWait;

     Screen('CloseAll');  %Close all the screens
     sca;
     ListenChar;
     ShowCursor;


end

%% formal experiment

if phase == "test"
    ListenChar(2);
    HideCursor;

    %绘制所有sample的texture
    sampleTextture = cell(1,objectNum);
    for obj = 1:objectNum
        object_pic_name = [pwd '/stimuli/item/' num2str(obj) '.jpg'];
        pic = imread(object_pic_name);
        sampleTextture{obj} =  Screen('MakeTexture',wPtr,pic);
    end
    clear pic obj object_pic_name

    switch run
        case 1
            block_array = (1:blockNum/2);
        case 2
            block_array = (blockNum/2+1:blockNum);
    end

    firstbaselineTask = 1;

    responseMat = [trialNum*blockNum,12];%probe呈现时间，test1开始时间，反应时间，选择背景，实际背景，是否正确，test2开始时间，test2被试第一次按键时间，test反应时间，所选位置，实际位置，是否正确
    
    if run == 1
        instractor = '下面将进行联系记忆实验的正式测试';
    else
        instractor = '下面将进行联系记忆实验的第二个run';
    end
    DrawFormattedText(wPtr,double(instractor),'center','center',[0 0 0]);
    Screen('Flip',wPtr);

    while 1
        [ currentTime , keycode] = KbStrokeWait(-1);
        if keycode(KbName('s'))%按s开始
            StartTime = currentTime;
            break;
        end
    end

    %TimeInfo = zeros(blockNum,4);
    %learningPhaseTimeMat = zeros(blockNum*trialNum,2);

    for block = block_array(1:length(block_array))

        startposList = Shuffle([5*ones(1,trialNum/2),8*ones(1,trialNum/2)]);

        for trial = 1:12

            trialSeq = (block-1)*trialNum + trial;

            %绘制context
            context = true_sample_mat(trialSeq,6);
            Screen('DrawTexture',wPtr,contextTexture{context},[],RectsEdge);

            %绘制sample
            sample_object_seq = true_sample_mat(trialSeq,4);
            sample_disp_rect_seq = object_rect_seq(true_sample_mat(trialSeq,5));
            sample_disp_rect = Rects(:,sample_disp_rect_seq)';
            Screen('DrawTexture',wPtr,sampleTextture{sample_object_seq},[],sample_disp_rect);

            %绘制矩形边框
            Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
            Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);

            Screen('Flip',wPtr,StartTime+true_sample_mat(trialSeq,7)-ifi);
            %learningPhaseTimeMat(trialSeq,1) =  sampleDispTime;
%             if trial == 1
%                 learningPhaseStratTime = sampleDispTime;
%             end

            Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
            [~,delayStartTime] = Screen('Flip',wPtr,StartTime+true_sample_mat(trialSeq,8)-ifi);
            %learningPhaseTimeMat(trialSeq,2) =  delayStartTime;
        end

        if firstbaselineTask
            firstbaselineTask = 0;
            baseLineMat = [];%trial,arrowtype,disptime,reponse,responsetime,iscorrect,RT
            baseline_trial_seq = 0;
        end
        baseline_task_start = 0;
        currentTime = GetSecs;

       while currentTime<baselineTaskduration+sampledelayTime-1.5*ifi+delayStartTime
            if baseline_task_start ~=0
                Screen('Flip',wPtr);
            end
            baseline_trial_seq = baseline_trial_seq+1;
            baseLineMat(baseline_trial_seq,:) = zeros(1,8);
            baseLineMat(baseline_trial_seq,1) = baseline_trial_seq;

            %获取箭头
            arrowDir = randperm(4,1);
            baseLineMat(baseline_trial_seq,2) = arrowDir;
            switch arrowDir
                case 1
                    arrow = '←';
                case 2
                    arrow = '→';
                case 3
                    arrow = '↑';
                case 4
                    arrow = '↓';
            end
            DrawFormattedText(wPtr,double(arrow),'center','center',[0 0 0]);

            if baseline_task_start ==0
                baseline_task_start = 1;
                responseTime = 0;
                [~,arrowStartTime] = Screen('Flip',wPtr,delayStartTime+sampledelayTime-ifi);
                baselineTaskStart = arrowStartTime;
            else
                [~,arrowStartTime] = Screen('Flip',wPtr,responseTime+baselineTaskinterval-ifi);
            end
            baseLineMat(baseline_trial_seq,3) = arrowStartTime;

            resp_made = 0;
            while ~resp_made
                [key_pressed, currentTime, keycode] = KbCheck(-1);
                if key_pressed && currentTime-responseTime>shortestinterval
                    if ~resp_made
                        if keycode(KbName('1!'))
                            response = 1;
                            responseTime = currentTime;
                            resp_made = 1;
                        elseif keycode(KbName('4$'))
                            response = 2;
                            responseTime = currentTime;
                            resp_made = 1;
                        elseif keycode(KbName('2@'))
                            response = 3;
                            responseTime = currentTime;
                            resp_made = 1;
                        elseif keycode(KbName('3#'))
                            response = 4;
                            responseTime = currentTime;
                            resp_made = 1;
                        else
                            response = -1;
                            responseTime = currentTime;
                            resp_made = 1;
                        end
                    end
                end
                if currentTime >= baselineTaskduration+sampledelayTime-1.5*ifi+delayStartTime
                    response = 0;
                    break
                end
            end
            baseLineMat(baseline_trial_seq,4) = response;
            baseLineMat(baseline_trial_seq,5) = responseTime;
            baseLineMat(baseline_trial_seq,6) = (response == arrowDir);
            baseLineMat(baseline_trial_seq,7) = responseTime-arrowStartTime;
            baseLineMat(baseline_trial_seq,8) = block;
            currentTime = GetSecs;
        end
        baselineTaskEnd = GetSecs;

        firstTrial = 1;
        for trial = 1:12
            trialSeq = (block-1)*trialNum + trial;

            %绘制sample
            Screen('DrawTexture',wPtr,sampleTextture{trueprobeMat(trialSeq,1)},[],testSampleLoc);

            if firstTrial == 1
                firstTrial = 0;
                [~,probeStart] = Screen('Flip',wPtr,StartTime+trueprobeMat(trialSeq,4)-ifi);
                %probePhaseStartTime = probeStart;
            else
                [~,probeStart] = Screen('Flip',wPtr,test2Start+positionTestTime-ifi);
            end

            DrawFormattedText(wPtr,double(contextInfo),'center','center',[0 0 0]);
            [~,test1Start] = Screen('Flip',wPtr,StartTime+trueprobeMat(trialSeq,5)-ifi);

            randomStartSeq = startposList(trial);
            randomStartRect = Rects(:,randomStartSeq)';
            Screen('FillRect',wPtr,currentRectColor,randomStartRect);
            Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
            Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);

            resp_made = 0;
            while 1
                [key_pressed, currentTime, keycode] = KbCheck(-1);
                if key_pressed
                    if ~resp_made
                        if keycode(KbName('1!'))
                            choosedContext = 1;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        elseif keycode(KbName('2@'))
                            choosedContext = 2;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        elseif keycode(KbName('3#'))
                            choosedContext = 3;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        elseif keycode(KbName('4$'))
                            choosedContext = 4;
                            resp_made = 1;
                            t1responseTime = currentTime;
                        end
                    end
                end
                if currentTime >= test1Start+contestTestTime-ifi
                    break
                end
            end
            if resp_made == 0
                choosedContext = 0;
                t1responseTime = 0;
            end

            if choosedContext == trueprobeMat(trialSeq,3) && choosedContext~=0
                conisCorrect = 1;
            elseif choosedContext~=0
                conisCorrect = 0;
            else
                conisCorrect = -1;
            end

            [~,test2Start] = Screen('Flip',wPtr,StartTime+trueprobeMat(trialSeq,6)-ifi);

             currentChoosedSeq = randomStartSeq;
            firstInput = 1;
            t2responseTime = 0;
            test2firstInput = 0;
            while 1
                [key_pressed,currentTime, keycode] = KbCheck(-1);
                if key_pressed && currentTime-t2responseTime>minimalinterval
                    if firstInput
                        test2firstInput = currentTime;
                        firstInput = 0;
                    end
                    if keycode(KbName('2@'))
                        currentChoosedSeq = mod(currentChoosedSeq-1,rectsNum);
                        if mod(currentChoosedSeq,3) == 0
                            currentChoosedSeq = currentChoosedSeq+3;
                        end
                        t2responseTime = currentTime;
                    elseif keycode(KbName('3#'))
                        currentChoosedSeq = mod(currentChoosedSeq+1,rectsNum);
                        if mod(currentChoosedSeq,3) == 1
                            currentChoosedSeq = currentChoosedSeq-3;
                        end
                        t2responseTime = currentTime;
                    elseif keycode(KbName('1!'))
                        currentChoosedSeq = mod(currentChoosedSeq-3,rectsNum);
                        t2responseTime = currentTime;
                    elseif keycode(KbName('4$'))
                        currentChoosedSeq = mod(currentChoosedSeq+3,rectsNum);
                        t2responseTime = currentTime;
                    end
                    if currentChoosedSeq <= 0
                        currentChoosedSeq = currentChoosedSeq+rectsNum;
                    end
                    currentRect = Rects(:,currentChoosedSeq)';
                    Screen('FillRect',wPtr,currentRectColor,currentRect);
                    Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
                    Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);
                    Screen('Flip', wPtr);
                    currentTime = GetSecs;
                end
                if currentTime>=test2Start+positionTestTime-ifi
                    break
                end
            end

            if currentChoosedSeq == object_rect_seq(trueprobeMat(trialSeq,2))
                posisCorrect = 1;
            else
                posisCorrect = 0;
            end

            responseMat(trialSeq,1) = probeStart;
            responseMat(trialSeq,2) = test1Start;
            responseMat(trialSeq,3) = t1responseTime;
            responseMat(trialSeq,4) = choosedContext;
            responseMat(trialSeq,5) = trueprobeMat(trialSeq,3);
            responseMat(trialSeq,6) = conisCorrect;
            responseMat(trialSeq,7) = test2Start;
            responseMat(trialSeq,8) = test2firstInput;
            responseMat(trialSeq,9) = t2responseTime;
            responseMat(trialSeq,10) = currentChoosedSeq;
            responseMat(trialSeq,11) = object_rect_seq(trueprobeMat(trialSeq,2));
            responseMat(trialSeq,12) = posisCorrect;
        end
%         TimeInfo(block,:) = [learningPhaseStratTime baselineTaskStart baselineTaskEnd probePhaseStartTime];
    end

    finished = '您已完成本轮实验，按任意键退出';
    DrawFormattedText(wPtr,double(finished),'center','center',[0 0 0]);
    Screen('Flip',wPtr);
    KbStrokeWait;

    Screen('CloseAll');  %Close all the screens
    sca;
    ListenChar;
    ShowCursor;
end

%%结果记录

Result = array2table(responseMat,'VariableNames',{'probeStart','test1Start','t1responseTime',...
    'choosedContext','trueContext','conisCorrect','test2Start','test2firstInput','t2finialResponse',...
    'choosedPostion','truePosition','posisCorrect'});
distractTaskResult = array2table(baseLineMat,'VariableNames',{'trial','arrowDir','arrowshowTime',...
    'response','responsedTime','isCorrect','RT','block'});
%specificTimeInfo = TimeInfo;
filename1 = fullfile('data', ...
    sprintf('AMT-phase_%s-sub_%03d-run_%d-time_%s.csv', ...
    phase, opts.id, run, datetime("now", "Format", "yyyyMMdd_HHmmss")));
filename2 = fullfile('data', ...
    sprintf('AMT-phase_%s-sub_%03d-run_%d-time_%s_distractTask.csv', ...
    phase, opts.id, run, datetime("now", "Format", "yyyyMMdd_HHmmss")));
%experimentEnd = GetSecs;
%experimentTime = experimentEnd-experimentStart;
writetable(Result, filename1);
writetable(distractTaskResult, filename2);
if run == 2
    responseMat = responseMat(49:96,:);
end
meanConACC = sum(responseMat(responseMat(:,6)~=-1,6))/length(find(responseMat(:,6)~=-1));
%meanConRT = sum(responseMat(responseMat(:,6)~=-1,3)-responseMat(responseMat(:,6)~=-1,2))/length(find(responseMat(:,6)~=-1));
meanPosACC = mean(responseMat(:,12));
%meanPosRT = mean(responseMat(responseMat(:,9)-responseMat(:,7)>0,9)-responseMat(responseMat(:,9)-responseMat(:,7)>0,7));
dispResult = [meanConACC,meanPosACC];