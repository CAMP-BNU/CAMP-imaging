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
ladin_seq_9 = {'seq_9','seq_`','seq_8','seq_2','seq_7','seq_3','seq_6','seq_5','seq_4'};
ladin_seq = {ladin_seq_1;ladin_seq_2;ladin_seq_3;ladin_seq_4;ladin_seq_5;ladin_seq_6;ladin_seq_7;ladin_seq_8;ladin_seq_9};
ladin_cate_1 = [1 2 4 3];
ladin_cate_2 = [2 3 1 4];
ladin_cate_3 = [1 2 4 3];
ladin_cate_4 = [2 3 1 4];
ladin_cate = {ladin_face ladin_object ladin_place ladin_word};
for i =1:4
    seqMat(i,:) = ladin_seq{seq_list(i),:};
end
for i=1:9
    cateMat(:,i) = ladin_cate{:,cate_list(i)};
end
stim = zeros(36*11,1);
for seq = 1:9
    append_num = (seq-1)*5;
    for category = 1:4
        current_seq_range = (((seq-1)*4+category-1)*11+1:((seq-1)*4+category)*11);
        stim(current_seq_range) = eval(seqMat{category,seq})+append_num;
    end
end
run_id = [ones(12*11,1);2*ones(12*11,1);3*ones(12*11,1)];
block_id = zeros(36*11,1);
for run=1:3
    for block = 1:12
        current_seq_range = ((run-1)*12+block-1)*11+1:((run-1)*12+block)*11;
        block_id(current_seq_range) = block*ones(11,1);
    end
end
stim_type = cell(36*11,1);
trial_id = zeros(36*11,1);
for seq = 1:9
   
    for category = 1:4
        for trial = 1:11
        current_seq = (((seq-1)*4+category-1)*11+trial;
        stim_type(current_seq_range) = cateMat(category,seq);
        end
    end
end

