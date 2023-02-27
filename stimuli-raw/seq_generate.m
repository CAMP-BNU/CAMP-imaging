clear clc
load('sequence.mat');
rng(1205);
seq_list = randsample(9,4);
cate_list = [randperm(4) randperm(4) randsample(4,1)];
ladin_seq_1 = {'seq_1','seq_2','seq_9','seq_3','seq_8','seq_4','seq_7','seq_6','seq_5'};
ladin_seq_2 = {'seq_2','seq_3','seq_1','seq_4','seq_9','seq_5','seq_8','seq_7','seq_6'};
ladin_seq_3 = {'seq_3','seq_4','seq_2','seq_5','seq_1','seq_6','seq_9','seq_8','seq_7'};
ladin_seq_4 = {'seq_4','seq_5','seq_3','seq_6','seq_2','seq_7','seq_1','seq_9','seq_8'};
ladin_seq_5 = {'seq_5','seq_6','seq_4','seq_7','seq_3','seq_8','seq_2','seq_1','seq_9'};
ladin_seq_6 = {'seq_6','seq_7','seq_5','seq_8','seq_4','seq_9','seq_3','seq_2','seq_1'};
ladin_seq_7 = {'seq_7','seq_8','seq_6','seq_9','seq_5','seq_1','seq_4','seq_3','seq_2'};
ladin_seq_8 = {'seq_8','seq_9','seq_7','seq_1','seq_6','seq_2','seq_5','seq_4','seq_3'};
ladin_seq_9 = {'seq_9','seq_1','seq_8','seq_2','seq_7','seq_3','seq_6','seq_5','seq_4'};
ladin_seq = {ladin_seq_1;ladin_seq_2;ladin_seq_3;ladin_seq_4;ladin_seq_5;ladin_seq_6;ladin_seq_7;ladin_seq_8;ladin_seq_9};
ladin_cate_1 = [1; 2; 4; 3];
ladin_cate_2 = [2; 3; 1; 4];
ladin_cate_3 = [3; 4; 2; 1];
ladin_cate_4 = [4; 1; 3; 2];
ladin_cate = [ladin_cate_1 ladin_cate_2 ladin_cate_3 ladin_cate_4];

for i=1:9
    cateMat(:,i) = ladin_cate(:,cate_list(i));
end
for i =1:4
    seqMat(i,:) = ladin_seq{seq_list(i),:};
end
for i = 1:9
    seqMat_formal(:,i) = seqMat(cateMat(:,i),i);
end
stim = zeros(36*12,1);
for seq = 1:9
    append_num = (seq-1)*5;
    for category = 1:4
        current_seq_range = (((seq-1)*4+category-1)*12+1:((seq-1)*4+category)*12);
        stim(current_seq_range(1:11)) = eval(seqMat_formal{category,seq})+append_num;
    end
end
run_id = [ones(12*12,1);2*ones(12*12,1);3*ones(12*12,1)];
block_id = zeros(36*12,1);
for run=1:3
    for block = 1:12
        current_seq_range = ((run-1)*12+block-1)*12+1:((run-1)*12+block)*12;
        block_id(current_seq_range) = block*ones(12,1);
    end
end
stim_type = cell(36*12,1);
trial_id = zeros(36*12,1);
for seq = 1:9
    for category = 1:4
        for trial = 1:12
            current_seq = ((seq-1)*4+category-1)*12+trial;
            trial_id(current_seq) = trial;
            switch cateMat(category,seq)
                case 1
                    stim_type{current_seq} = 'face';
                case 2
                    stim_type{current_seq} = 'object';
                case 3
                    stim_type{current_seq} = 'place';
                case 4
                    stim_type{current_seq} = 'word';
            end
        end
    end
end
targetType = for2back_check(stim);
cond = targetType(:,1);
cresp = targetType(:,2);
formal_seq_10_12 = table(run_id,block_id,stim_type,trial_id,stim,cond,cresp);
writetable(formal_seq_10_12, fullfile('..', 'stimuli', 'twoback', 'sequence.csv'));
