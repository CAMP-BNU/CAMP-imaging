function [status,dispResult] = start_amt(phase, run, opts)

arguments
    phase {mustBeTextScalar, mustBeMember(phase, ["prac", "test"])} = "prac"
    run {mustBeInteger, mustBePositive} = 1
    opts.id (1, 1) {mustBeInteger, mustBeNonnegative} = 0
    opts.SkipSyncTests (1, 1) {mustBeNumericOrLogical} = false
end

%% screen setting

%experimentStart = GetSecs;
Screen('Preference','SkipSyncTests',double(opts.SkipSyncTests));

PsychDefaultSetup(2);

screenNumber = max(Screen('Screens'));

bgColor = [255 255 255];

[wPtr, rect] = Screen('OpenWindow',screenNumber,bgColor);
[xCenter, yCenter] = WindowCenter(wPtr);
ifi = Screen('GetFlipInterval', wPtr);
Screen('TextFont',wPtr,'SimHei');
Screen('TextSize',wPtr,round(0.06*RectHeight(rect)));

Priority(1);

Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

black = BlackIndex(screenNumber);

%% basic setting of the task

%实验流程的基本设置
trialNum = 12;%每个block的trial数
blockNum = 8;%总共多少block
presentTime = 2;%每个object呈现2s
sampledelayTime = 2;%每个object之间的间隔

%刺激数
objectNum=12;

%context设置
contextTexture = cell(1,4);
for context = 1:4
    fileName = [pwd '/stimuli/amt/context/context' num2str(context) '.jpg'];
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
contextInfo = '森林=1,公路=2,雪山=3,海底=4';
minimalinterval = 0.2;

%practice设置
pracblockNum = 4;
feedbackTime = 1;
correctColor = [0 255 0];
wrongColor = [255 0 0];

%sample阶段矩形与矩阵设置
posNum = 6;
crossWidth = 2;
crossColor = black;
crossLengthPixels = 20;
crossLines = [-crossLengthPixels crossLengthPixels 0 0; 0 0 -crossLengthPixels crossLengthPixels];%注视点设置
rectlineColor = black;
rectSize = [RectHeight(rect)*300/1080,RectHeight(rect)*300/1080];%每个矩形的长和宽
rectInterval = [0,0];%矩阵中矩形之间没有间隔
matrixRowNumber = 4;%矩形构成的矩阵一行有多少矩形
matrixColumnNumber = 3;%矩形构成的矩阵一列有多少矩形
object_rect_seq = [4,7,2,11,6,9];%object的pos编号对应的rect的编号，pos=1对应的就是object_position_seq（1）
prac_object_rect_seq = randperm(matrixRowNumber*matrixColumnNumber,posNum);
rectlineWidth = 2;
matrixTopLine = yCenter-rectSize(2)*matrixColumnNumber*0.5-rectInterval(2)*(matrixColumnNumber-1)*0.5;%矩阵最上面的边界
matrixLeftLine = xCenter-rectSize(1)*matrixRowNumber*0.5-rectInterval(1)*(matrixRowNumber-1)*0.5;%最左侧的边界
matrixBottomLine = matrixTopLine+rectSize(2)*matrixColumnNumber;
matrixRightLine = matrixLeftLine+rectSize(1)*matrixRowNumber;
RectsEdge = [matrixLeftLine matrixTopLine matrixRightLine matrixBottomLine];
Rects = NaN(4,matrixRowNumber*matrixColumnNumber);
for i=1:matrixRowNumber
    recentLeftLine = matrixLeftLine+(i-1)*(rectInterval(1)+rectSize(1));
    recentRightLine = recentLeftLine+rectSize(1);
    for p=1:matrixColumnNumber
        recentTopLine = matrixTopLine+(p-1)*(rectInterval(2)+rectSize(2));
        recentBottomLine = recentTopLine+rectSize(2);
        rectSeq = (i-1)*matrixColumnNumber + p;
        Rects(:,rectSeq) = [recentLeftLine; recentTopLine;recentRightLine;recentBottomLine];
    end
end
clear rectSeq recentLeftLine recentRightLine recentTopLine recentBottomLine i
%probe阶段位置设置
testSampleLoc = [xCenter-rectSize(1)*0.5,yCenter-rectSize(2)*0.5,xCenter+rectSize(1)*0.5,yCenter+rectSize(2)*0.5];

%按键设置
leftKey = KbName('1!');
rightKey = KbName('2@');
upKey = KbName('3#');
downKey = KbName('4$');

con1Key = KbName('1!');
con2Key = KbName('2@');
con3Key = KbName('3#');
con4Key = KbName('4$');

exitKey = KbName('Escape');
startKey = KbName('s');
earlyExit = 0;
exit = 0;

%载入practice和formal阶段的相关序列
load(fullfile('sequence', 'amt', 'formal_experiment_information.mat'))
load(fullfile('sequence', 'amt', 'practice_information.mat'))
rectsNum = length(Rects);

%% practice

while ~earlyExit
    if phase == "prac"

        baseLineMat = zeros(1,6);%trial,arrowtype,Onset,duration,RT,iscorrect,block
        responseMat = zeros(trialNum*pracblockNum,12);%onset,duration,onset,duration,onset,duration,RT,iscorrect,onset,duration,RT,iscorrect
        baseline_trial_seq = 0;
        %呈现指导语
        for ins = 1:3
            insPic = fullfile('instr', 'amt', sprintf('ins%d.jpg', ins));
            pic = imread(insPic);
            insTextture =  Screen('MakeTexture',wPtr,pic);
            Screen('DrawTexture',wPtr,insTextture);
            Screen('Flip',wPtr);

            while 1
                [ ~ , keycode] = KbStrokeWait();
                if keycode(KbName('s'))%按s继续
                    break
                elseif keycode(exitKey)
                    earlyExit = 1;
                    break
                end
            end
            if earlyExit == 1
                break
            end
        end
        if earlyExit == 1
            break
        end


        ListenChar(2);
        HideCursor;
        instractor = '下面将进行联系记忆实验的练习，准备好后按s开始';
        DrawFormattedText(wPtr,double(instractor),'center','center',[0 0 0]);
        Screen('Flip',wPtr);

        while 1
            [ currentTime , keycode] = KbStrokeWait();
            if keycode(KbName('s'))%按s开始
                StartTime = currentTime;
                break
            elseif keycode(exitKey)
                earlyExit = 1;
                break
            end
        end
        if earlyExit==1
            break
        end
        Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
        [~,delayStartTime] = Screen('Flip',wPtr);

        %绘制所有sample的texture
        pracsampleTextture = cell(1,objectNum);
        for obj = 1:12
            object_pic_name = [pwd '/stimuli/amt/object/' num2str(obj+12) '.jpg'];
            pic = imread(object_pic_name);
            pracsampleTextture{obj} =  Screen('MakeTexture',wPtr,pic);
        end
        clear pic obj object_pic_name

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
                [~,sampleDispTime] = Screen('Flip',wPtr,delayStartTime+sampledelayTime-ifi);
                responseMat(trialSeq,1) = sampleDispTime-StartTime;

                Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
                [~,delayStartTime] = Screen('Flip',wPtr,sampleDispTime+presentTime-ifi);
                responseMat(trialSeq,2) = delayStartTime-sampleDispTime;
            end

            currentTime = GetSecs;
            baseline_task_start = 0;

            while currentTime<baselineTaskduration+sampledelayTime-1.5*ifi+delayStartTime
                if baseline_task_start ~=0
                    Screen('Flip',wPtr);
                end
                baseline_trial_seq = baseline_trial_seq+1;
                baseLineMat(baseline_trial_seq,:) = zeros(1,6);
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
                else
                    [~,arrowStartTime] = Screen('Flip',wPtr,responseTime+baselineTaskinterval-ifi);
                end
                baseLineMat(baseline_trial_seq,3) = arrowStartTime-StartTime;

                resp_made = 0;
                while ~resp_made
                    [key_pressed, currentTime, keycode] = KbCheck(-1);
                    if key_pressed && (currentTime-responseTime)>shortestinterval
                        if ~resp_made
                            if keycode(leftKey)
                                response = 1;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(rightKey)
                                response = 2;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(upKey)
                                response = 3;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(downKey)
                                response = 4;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(exitKey)
                                earlyExit = 1;
                                break
                            else
                                response = -1;
                                responseTime = currentTime;
                                resp_made = 1;
                            end
                        end
                    end
                    if currentTime >= baselineTaskduration+sampledelayTime-1.5*ifi+delayStartTime
                        response = 0;
                        responseTime = currentTime;
                        break
                    end
                end
                if earlyExit == 1
                    break
                end
                baseLineMat(baseline_trial_seq,4) = responseTime-arrowStartTime;
                if response>0
                    baseLineMat(baseline_trial_seq,5) = (response == arrowDir);
                elseif response==0
                    baseLineMat(baseline_trial_seq,5) = -1;
                else
                    baseLineMat(baseline_trial_seq,5) = -2;
                end
                baseLineMat(baseline_trial_seq,6) = block;
            end
            if earlyExit == 1
                break
            end

            firstTrial = 1;
            for trial = 1:12
                trialSeq = (block-1)*12+trial;
                %绘制sample
                Screen('DrawTexture',wPtr,pracsampleTextture{pracprobeMat(trialSeq,1)-12},[],testSampleLoc);

                if firstTrial == 1
                    firstTrial = 0;
                    [~,probeStart] = Screen('Flip',wPtr,delayStartTime++baselineTaskduration+sampledelayTime-ifi);
                else
                    [~,probeStart] = Screen('Flip',wPtr,feedback2StartTime+feedbackTime-ifi);
                end

                DrawFormattedText(wPtr,double(contextInfo),'center','center',[0 0 0]);
                [~,test1Start] = Screen('Flip',wPtr,probeStart+probeDispTime-ifi);


                resp_made = 0;
                while 1
                    [key_pressed, currentTime, keycode] = KbCheck(-1);
                    if key_pressed
                        if ~resp_made
                            if keycode(con1Key)
                                choosedContext = 1;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(con2Key)
                                choosedContext = 2;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(con3Key)
                                choosedContext = 3;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(con4Key)
                                choosedContext = 4;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(exitKey)
                                earlyExit = 1;
                                break
                            else
                                choosedContext = -1;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            end

                        end
                    end
                    if currentTime >= test1Start+contestTestTime-ifi
                        break
                    end
                end
                if earlyExit == 1
                    break
                end
                if resp_made == 0
                    choosedContext = 0;
                    t1responseTime = 0;
                end

                if choosedContext == pracprobeMat(trialSeq,3) && choosedContext>0
                    conisCorrect = 1;
                    feedback = '正确';
                    feedbackColor = correctColor;
                elseif choosedContext>0
                    conisCorrect = 0;
                    feedback = '错误';
                    feedbackColor = wrongColor;
                elseif choosedContext<0
                    conisCorrect = -2;
                    feedback = '按错键了!';
                    feedbackColor = wrongColor;
                else
                    conisCorrect = -1;
                    feedback = '请尽快反应!';
                    feedbackColor = wrongColor;
                end
                DrawFormattedText(wPtr,double(feedback),'center','center',feedbackColor);
                feedback1StartTime = Screen('Flip', wPtr);


                randomStartSeq = startposList(trial);
                randomStartRect = Rects(:,randomStartSeq)';
                Screen('FillRect',wPtr,currentRectColor,randomStartRect);
                Screen('FrameRect',wPtr,rectlineColor,Rects,rectlineWidth);
                Screen('FrameRect',wPtr,rectlineColor,RectsEdge,rectlineWidth*2);
                [~,test2Start] = Screen('Flip',wPtr,feedback1StartTime+feedbackTime-ifi);

                currentChoosedSeq = randomStartSeq;
                firstInput = 1;
                t2responseTime = 0;
                test2firstInput = 0;
                while 1
                    [key_pressed,currentTime, keycode] = KbCheck(-1);
                    if key_pressed && (currentTime-t2responseTime)>minimalinterval
                        if firstInput
                            test2firstInput = currentTime;
                            firstInput = 0;
                        end
                        if keycode(upKey)
                            currentChoosedSeq = mod(currentChoosedSeq-1,rectsNum);
                            if mod(currentChoosedSeq,matrixColumnNumber) == 0
                                currentChoosedSeq = currentChoosedSeq+matrixColumnNumber;
                            end
                            t2responseTime = currentTime;
                        elseif keycode(downKey)
                            currentChoosedSeq = mod(currentChoosedSeq+1,rectsNum);
                            if mod(currentChoosedSeq,matrixColumnNumber) == 1
                                currentChoosedSeq = currentChoosedSeq-matrixColumnNumber;
                            end
                            t2responseTime = currentTime;
                        elseif keycode(leftKey)
                            currentChoosedSeq = mod(currentChoosedSeq-matrixColumnNumber,rectsNum);
                            t2responseTime = currentTime;
                        elseif keycode(rightKey)
                            currentChoosedSeq = mod(currentChoosedSeq+matrixColumnNumber,rectsNum);
                            t2responseTime = currentTime;
                        elseif keycode(exitKey)
                            earlyExit = 1;
                            break
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
                if earlyExit == 1
                    break
                end

                if currentChoosedSeq == prac_object_rect_seq(pracprobeMat(trialSeq,2))
                    posisCorrect = 1;
                    feedback = '正确';
                    feedbackColor = correctColor;
                else
                    posisCorrect = 0;
                    feedback = '错误';
                    feedbackColor = wrongColor;
                end
                DrawFormattedText(wPtr,double(feedback),'center','center',feedbackColor);
                feedback2StartTime = Screen('Flip', wPtr);

                responseMat(trialSeq,3) = probeStart-StartTime;
                responseMat(trialSeq,4) = test1Start-probeStart;
                responseMat(trialSeq,5) = test1Start--StartTime;
                responseMat(trialSeq,6) = feedback1StartTime-test1Start;
                responseMat(trialSeq,7) = t1responseTime-test1Start;
                responseMat(trialSeq,8) = conisCorrect;
                responseMat(trialSeq,9) = test2Start-StartTime;
                responseMat(trialSeq,10) = feedback2StartTime-test2Start;
                responseMat(trialSeq,11) = test2firstInput-test2Start;
                responseMat(trialSeq,12) = posisCorrect;

            end

            if earlyExit == 1
                break
            end

            meanBlockBaselineACC = length(baseLineMat((baseLineMat(:,6)==block & baseLineMat(:,5)==1)))/length(baseLineMat((baseLineMat(:,6)==block & baseLineMat(:,5)~=-1)));
            meanBlockBaselineRT = mean(baseLineMat((baseLineMat(:,6)==block & baseLineMat(:,5)~=-1),4));
            BlockConisCorrect = responseMat((block*trialNum-trialNum+1):block*trialNum,8);
            meanBlockConACC = length(find(BlockConisCorrect==1))/length(BlockConisCorrect);
            meanBlockPosACC = mean(responseMat((block*trialNum-trialNum+1):block*trialNum,12));
            feedback = ['本轮您在朝向判断任务中的正确率为' num2str(meanBlockBaselineACC) ',反应时为' num2str(meanBlockBaselineRT) '.\n\n'...
                '您背景回忆的正确率为' num2str(meanBlockConACC) '\n\n' '您位置回忆的正确率为' num2str(meanBlockPosACC) '\n\n' '请等待主试按键继续'];
            DrawFormattedText(wPtr,double(feedback),'center','center',[0 0 0]);
            Screen('Flip',wPtr);

            while 1
                [ ~ , keycode] = KbStrokeWait(-1);
                if keycode(KbName('s'))%按s继续
                    break;
                elseif keycode(exitKey)
                    earlyExit = 1;
                    break
                end
            end
            if earlyExit == 1
                break
            end

            if block~=pracblockNum
                Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
                [~,delayStartTime] = Screen('Flip',wPtr);
            end

        end
        if earlyExit ~=1
            finished = '您已完成本练习，按任意键退出';
        else
            finished = '您已终止本练习，按任意键退出';
        end
        DrawFormattedText(wPtr,double(finished),'center','center',[0 0 0]);
        Screen('Flip',wPtr);
        KbStrokeWait;
        exit= 1;
    end
    if exit == 1
        break
    end



    %% formal experiment

    if phase == "test"
        
        firstbaselineTask = 1;
        baseLineMat = zeros(1,6);%trial,arrowtype,Onset,duration,RT,iscorrect,block
        responseMat = zeros(trialNum*blockNum,12);%onset,duration,onset,duration,onset,duration,RT,iscorrect,onset,duration,RT,iscorrect
        ListenChar(2);
        HideCursor;

        %绘制所有sample的texture
        sampleTextture = cell(1,objectNum);
        for obj = 1:objectNum
            object_pic_name = [pwd '/stimuli/amt/object/' num2str(obj) '.jpg'];
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

        for block = block_array(1:length(block_array))

            startposList = Shuffle([5*ones(1,trialNum/2),8*ones(1,trialNum/2)]);

            for trial = 1:12

                trialSeq = (block-1)*trialNum + trial;

                if (block ==1 || block ==blockNum/2+1) && trial == 1
                    if run == 1
                        instractor = '下面将进行联系记忆实验的正式测试';
                    else
                        instractor = '下面将进行联系记忆实验的第二个run';
                    end
                    DrawFormattedText(wPtr,double(instractor),'center','center',[0 0 0]);
                    Screen('Flip',wPtr);
                end

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

                if (block ==1 || block ==blockNum/2+1) && trial == 1
                    while 1
                        [ currentTime , keycode] = KbStrokeWait(-1);
                        if keycode(startKey)%按s开始
                            StartTime = currentTime;
                            break;
                        elseif keycode(exitKey)
                            earlyExit = 1;
                            break
                        end
                    end
                end
                if earlyExit == 1
                    break
                end

                [~,sampleDispTime] = Screen('Flip',wPtr,StartTime+true_sample_mat(trialSeq,8));
                responseMat(trialSeq,1) = sampleDispTime-StartTime;

                Screen('DrawLines', wPtr, crossLines, crossWidth, crossColor,[xCenter,yCenter],2);
                [~,delayStartTime] = Screen('Flip',wPtr,StartTime+true_sample_mat(trialSeq,9));
                responseMat(trialSeq,2) = delayStartTime-sampleDispTime;

            end
            if earlyExit == 1
                break
            end


            if firstbaselineTask
                firstbaselineTask = 0;
                baseline_trial_seq = 0;
            end
            baseline_task_start = 0;
            currentTime = GetSecs;

           while currentTime<baselineTaskduration+sampledelayTime-0.5*ifi+delayStartTime
                if baseline_task_start ~=0
                    Screen('Flip',wPtr);
                end
                baseline_trial_seq = baseline_trial_seq+1;
                baseLineMat(baseline_trial_seq,:) = zeros(1,6);
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
                    [~,arrowStartTime] = Screen('Flip',wPtr,delayStartTime+sampledelayTime);
                else
                    [~,arrowStartTime] = Screen('Flip',wPtr,responseTime+baselineTaskinterval);
                end
                baseLineMat(baseline_trial_seq,3) = arrowStartTime-StartTime;

                resp_made = 0;
                while ~resp_made
                    [key_pressed, currentTime, keycode] = KbCheck(-1);
                    if key_pressed && (currentTime-responseTime)>shortestinterval
                        if ~resp_made
                            if keycode(leftKey)
                                response = 1;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(rightKey)
                                response = 2;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(upKey)
                                response = 3;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(downKey)
                                response = 4;
                                responseTime = currentTime;
                                resp_made = 1;
                            elseif keycode(exitKey)
                                earlyExit = 1;
                                break
                            else
                                response = -1;
                                responseTime = currentTime;
                                resp_made = 1;
                            end
                        end
                    end
                    if currentTime >= baselineTaskduration+sampledelayTime-0.5*ifi+delayStartTime
                        response = 0;
                        responseTime = currentTime;
                        break
                    end
                end
                if earlyExit == 1
                    break
                end
                baseLineMat(baseline_trial_seq,4) = responseTime-arrowStartTime;
                if response>0
                    baseLineMat(baseline_trial_seq,5) = (response == arrowDir);
                elseif response==0
                    baseLineMat(baseline_trial_seq,5) = -1;
                else
                    baseLineMat(baseline_trial_seq,5) = -2;
                end
                baseLineMat(baseline_trial_seq,6) = block;
            end
            if earlyExit == 1
                break
            end


            for trial = 1:12
                trialSeq = (block-1)*trialNum + trial;

                %绘制sample
                Screen('DrawTexture',wPtr,sampleTextture{trueprobeMat(trialSeq,1)},[],testSampleLoc);


                [~,probeStart] = Screen('Flip',wPtr,StartTime+trueprobeMat(trialSeq,5));


                DrawFormattedText(wPtr,double(contextInfo),'center','center',[0 0 0]);
                [~,test1Start] = Screen('Flip',wPtr,StartTime+trueprobeMat(trialSeq,6));

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
                            if keycode(con1Key)
                                choosedContext = 1;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(con2Key)
                                choosedContext = 2;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(con3Key)
                                choosedContext = 3;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(con4Key)
                                choosedContext = 4;
                                resp_made = 1;
                                t1responseTime = currentTime;
                            elseif keycode(exitKey)
                                earlyExit = 1;
                                break
                            end
                        end
                    end
                    if currentTime >= test1Start+contestTestTime-0.5*ifi
                        break
                    end
                end
                if earlyExit == 1
                    break
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

                [~,test2Start] = Screen('Flip',wPtr,StartTime+trueprobeMat(trialSeq,7));

                currentChoosedSeq = randomStartSeq;
                firstInput = 1;
                t2responseTime = 0;
                test2firstInput = 0;
                while 1
                    [key_pressed,currentTime, keycode] = KbCheck(-1);
                    if key_pressed && (currentTime-t2responseTime)>minimalinterval
                        if firstInput
                            test2firstInput = currentTime;
                            firstInput = 0;
                        end
                        if keycode(upKey)
                            currentChoosedSeq = mod(currentChoosedSeq-1,rectsNum);
                            if mod(currentChoosedSeq,matrixColumnNumber) == 0
                                currentChoosedSeq = currentChoosedSeq+matrixColumnNumber;
                            end
                            t2responseTime = currentTime;
                        elseif keycode(downKey)
                            currentChoosedSeq = mod(currentChoosedSeq+1,rectsNum);
                            if mod(currentChoosedSeq,matrixColumnNumber) == 1
                                currentChoosedSeq = currentChoosedSeq-matrixColumnNumber;
                            end
                            t2responseTime = currentTime;
                        elseif keycode(leftKey)
                            currentChoosedSeq = mod(currentChoosedSeq-matrixColumnNumber,rectsNum);
                            t2responseTime = currentTime;
                        elseif keycode(rightKey)
                            currentChoosedSeq = mod(currentChoosedSeq+matrixColumnNumber,rectsNum);
                            t2responseTime = currentTime;
                        elseif keycode(exitKey)
                            earlyExit = 1;
                            break
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
                    if currentTime>=test2Start+positionTestTime-0.5*ifi
                        break
                    end
                end
                if earlyExit ==1
                    break
                end
                if currentChoosedSeq == object_rect_seq(trueprobeMat(trialSeq,2))
                    posisCorrect = 1;
                else
                    posisCorrect = 0;
                end

                responseMat(trialSeq,3) = probeStart-StartTime;
                responseMat(trialSeq,4) = test1Start-probeStart;
                responseMat(trialSeq,5) = test1Start-StartTime;
                responseMat(trialSeq,6) = test2Start-test1Start;
                responseMat(trialSeq,7) = t1responseTime-test1Start;
                responseMat(trialSeq,8) = conisCorrect;
                responseMat(trialSeq,9) = test2Start-StartTime;
                responseMat(trialSeq,10) = currentTime-test2Start;
                responseMat(trialSeq,11) = test2firstInput-test2Start;
                responseMat(trialSeq,12) = posisCorrect;
            end
        end
        if earlyExit == 1
            break
        end
    end
    instr_ending = char(strjoin(readlines(fullfile('common', 'instr_ending.txt'), ...
        "EmptyLineRule", "skip"), "\n"));
    DrawFormattedText(wPtr, double(instr_ending), 'center', 'center');
    Screen('Flip', wPtr);
    while 1
        [~, key_code] = KbStrokeWait(-1);
        if key_code(exitKey)
            exit = 1;
            break
        end
    end
    if exit==1 
        break
    end
end
Screen('CloseAll');  %Close all the screens
sca;
ListenChar;
ShowCursor;

%%结果记录
%载入practice和formal阶段的相关序列
load(fullfile('sequence', 'amt', 'resultTemplate.mat'))
switch phase
    case 'prac'
        ResultTable = practiceresulttemplate;
    case 'test'
        if run == 1
            ResultTable = run1resulttemplate;
        else
            ResultTable = run2resulttemplate;
        end
end
if run==1
    for block = 1:4
        for testphase = 1:2
            ResultTable((block-1)*48 + (testphase-1)*12+1:(block-1)*48+testphase*12,9:10) = array2table(responseMat((block-1)*12+1:block*12,2*testphase-1:2*testphase));
        end
    end
    for block = 1:4
        for testphase = 3:4
            ResultTable((block-1)*48 + (testphase-1)*12+1:(block-1)*48+testphase*12,9:12) = array2table(responseMat((block-1)*12+1:block*12,4*(testphase-1)-3:4*(testphase-1)));
        end
    end
else
    for block = 5:8
        for testphase = 1:2
            ResultTable((block-5)*48 + (testphase-1)*12+1:(block-5)*48+testphase*12,9:10) = array2table(responseMat((block-1)*12+1:block*12,2*testphase-1:2*testphase));
        end
    end
    for block = 5:8
        for testphase = 3:4
            ResultTable((block-5)*48 + (testphase-1)*12+1:(block-5)*48+testphase*12,9:12) = array2table(responseMat((block-1)*12+1:block*12,4*(testphase-1)-3:4*(testphase-1)));
        end
    end
end
for distrial = 1:size(baseLineMat,1)
    distratorresulttemplate(1,[1 3 4 5 9 10 11 12]) = array2table([run baseLineMat(distrial,[6 1 2 3 4 4 5])]);
    ResultTable(192+distrial,:) = distratorresulttemplate;
end


filename = fullfile('data', ...
    sprintf('AMT-phase_%s-sub_%03d-run_%d-time_%s.csv', ...
    phase, opts.id, run, datetime("now", "Format", "yyyyMMdd_HHmmss")));

if phase == "test"
    utils.store_data(ResultTable, opts.id, "amt", run);
else
    writetable(ResultTable, filename);
end
if run == 2
    responseMat = responseMat(49:96,:);
end
meanConACC = sum(responseMat(responseMat(:,8)~=-1,8))/length(find(responseMat(:,8)~=-1));
meanPosACC = mean(responseMat(:,12));
dispResult = [meanConACC,meanPosACC];

if earlyExit == 1
    status = 2;
else
    status = 0;
end