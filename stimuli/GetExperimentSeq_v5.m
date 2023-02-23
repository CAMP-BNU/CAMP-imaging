%% read the subject number from the command window
clear; clc; 


%% screen setting

rng(1205);

Screen('Preference','SkipSyncTests',1); 

PsychDefaultSetup(2);

screenNumber = max(Screen('Screens'));

white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);
bgColor = [128 128 128];

[wPtr, rect] = Screen('OpenWindow',screenNumber,bgColor);
[xCenter, yCenter] = WindowCenter(wPtr);
[screenXpixels, screenYpixels] = Screen('WindowSize', wPtr);
[width, height] = Screen('DisplaySize', screenNumber);
ifi = Screen('GetFlipInterval', wPtr);
Screen('TextFont',wPtr,'SimHei');
Screen('TextSize',wPtr,round(0.06*RectHeight(rect)));

Priority(1);

Screen('BlendFunction',wPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA); 

%% basic setting of the task


%实验流程的基本设置
trialNum = 12;%每个block的trial数
blockNum = 8;%总共多少block
runNum = 2;%总共多少run
presentTime = 2;%每个object呈现2s
sampledelayTime = 2;%每个object之间的间隔
samplePhaseTime = 48;
probePhaseTime = 96;

%baseline task阶段的基本设置
baselineTaskduration =12;%总共进行多久的baseline task
baselineTaskinterval = 0.2;%trial之间的间隔


%刺激数
objectNum=12;
posNum = 6;
contextNum = 4;
repeatTime = trialNum*blockNum/objectNum;

%刺激呈现和测试的相关参数
presentTime = 2;%每个object呈现2s
sampledelayTime = 2;
probeDispTime = 4;
contestTestTime = 1.5;
pracpositionTestTime = 2.5;
positionTestTime = 2.5;

%生成实际的刺激序列
load('trialMat.mat');
load('trialObjectList.mat')
%true_object_repeat_situation = zeros(repeatTime,objectNum);
%for obj=1:objectNum
%    true_object_repeat_situation(:,obj) = randperm(repeatTime)';
%end
%true_trial_object_situation = zeros(blockNum,objectNum);
% for block=1:blockNum
%     true_trial_object_situation(block,:) = randperm(trialNum);
% end
true_sample_mat = zeros(trialNum*blockNum,8);
for block = 1:blockNum
    seqrange = ((block-1)*12+1:block*12);
    for trial = 1:trialNum
        run = ceil(trial/(trialNum*blockNum/runNum));
        trial_in_block = mod(trial,trialNum);
        if trial_in_block == 0
            trial_in_block = trialNum;
        end
        seq = find(trialMat(seqrange) == trialObjectList((block-1)*12+trial))+(block-1)*12;
        true_sample_mat((block-1)*12+trial,1:6) = [run block trial_in_block trialMat(seq,:)];
    end
end
sampleDispTime = zeros(blockNum/runNum*trialNum,2);
for block = 1:blockNum/runNum
    for trial = 1:trialNum
        sampleDispTime((block-1)*trialNum+trial,1) = (block-1)*(samplePhaseTime+baselineTaskduration+probePhaseTime)+(trial-1)*(presentTime+sampledelayTime);
        sampleDispTime((block-1)*trialNum+trial,2) = sampleDispTime((block-1)*trialNum+trial,1)+2;
    end
end
true_sample_mat(1:blockNum/runNum*trialNum,7:8) = sampleDispTime;
true_sample_mat(blockNum/runNum*trialNum+1:blockNum*trialNum,7:8) = sampleDispTime;
clear trial run block trial_in_block object repeatType trial_mat_seq pos context seq seqrange sampleDispTime
 
%生成prac的刺激序列
prac_sample_con = Shuffle([ones(1,3),2*ones(1,3),3*ones(1,3),4*ones(1,3)])';
prac_sample_pos = [randperm(6) randperm(6)]';
prac_sample_obj = ((1:12)+12)';
prac_sample_mat = [prac_sample_obj prac_sample_pos prac_sample_con];
prac_sample_con = Shuffle([ones(1,6),2*ones(1,6)])';
prac_sample_pos = [randperm(6) randperm(6)]';
prac_sample_obj = ((1:12)+12)';
prac_sample_mat = [prac_sample_mat;[prac_sample_obj prac_sample_pos prac_sample_con]];
clear prac_sample_con prac_sample_pos prac_sample_obj

%sample阶段矩形与矩阵设置
crossWidth = 2; 
crossColor = black;
crossLengthPixels = 20;
crossLines = [-crossLengthPixels crossLengthPixels 0 0; 0 0 -crossLengthPixels crossLengthPixels];%注视点设置
rectlineColor = black;
rectSize = [300,300];%每个矩形的长和宽
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

%生成实际的probe序列
trueprobeMat = zeros(trialNum*blockNum,3);%object,(choice_pos,choice_con)*4,true answer
for block = 1:blockNum
    if block == blockNum
        objecttestSeq = randperm(objectNum);
    else%依据下一个block的learning阶段的序列进行测试，避免测试阶段呈现的object和下一阶段learning阶段的object距离过近
        blockDispSeqFirstHalf = trialObjectList(block*trialNum+1:block*trialNum+0.5*trialNum);
        blockDispSeqSecondHalf = trialObjectList((block+0.5)*trialNum+1:(block+1)*trialNum);
        objecttestSeq = [blockDispSeqFirstHalf(randperm(0.5*trialNum));blockDispSeqSecondHalf(randperm(0.5*trialNum))];
    end
    trueprobeMat(((block-1)*trialNum+1):block*trialNum,1) = objecttestSeq;
    for trial = 1:trialNum
        seq = find(true_sample_mat(((block-1)*trialNum+1):block*trialNum,4)==objecttestSeq(trial))+(block-1)*trialNum;
        trueprobeMat((block-1)*trialNum+trial,2) = true_sample_mat(seq,5);
        trueprobeMat((block-1)*trialNum+trial,3) = true_sample_mat(seq,6);
    end
end
probeDispTimeMat = zeros(blockNum/runNum*trialNum,3);
for block = 1:blockNum/runNum
    for trial = 1:trialNum
        probeDispTimeMat((block-1)*trialNum+trial,1) = (block-1)*(samplePhaseTime+baselineTaskduration+probePhaseTime)+samplePhaseTime+baselineTaskduration+(trial-1)*(contestTestTime+positionTestTime+probeDispTime);
        probeDispTimeMat((block-1)*trialNum+trial,2) = probeDispTimeMat((block-1)*trialNum+trial,1)+probeDispTime;
        probeDispTimeMat((block-1)*trialNum+trial,3) = probeDispTimeMat((block-1)*trialNum+trial,2)+contestTestTime;
    end
end
trueprobeMat(1:blockNum/runNum*trialNum,4:6) = probeDispTimeMat;
trueprobeMat(blockNum/runNum*trialNum+1:blockNum*trialNum,4:6) = probeDispTimeMat;
clear block objecttestSeq seq probeDispTimeMat

%生成practice的probe序列
feedbackTime = 1;
pracobjecttestSeq = randperm(objectNum)';
pracprobeMat(1:trialNum,1) = pracobjecttestSeq+12;
pracobjecttestSeq = randperm(objectNum)';
pracprobeMat(trialNum+1:2*trialNum,1) = pracobjecttestSeq+12;
for block=0:1
    seq_range = (1:12)+block*12;
    for trial = 1:trialNum
        trialseq = trial+block*12;
        seq = find(prac_sample_mat(seq_range,1)==pracprobeMat(trialseq,1))+block*12;
        pracprobeMat(trialseq,2) = prac_sample_mat(seq,2);
        pracprobeMat(trialseq,3) = prac_sample_mat(seq,3);
    end
end
pracprobeMat(13:24,:) = pracprobeMat(randsample((13:24),12),:);

Screen('CloseAll');  %Close all the screens
sca;

save 'practice_information.mat' pracprobeMat prac_sample_mat
save 'formal_experiment_information.mat' true_sample_mat trueprobeMat
save 'rect_location_information.mat' Rects RectsEdge object_rect_seq rectlineWidth matrixRowNumber matrixColumnNumber prac_object_rect_seq testSampleLoc