function targetType = for2back_check(stimuli_seq)
trial_num = 11;
targetType = cell(length(stimuli_seq),2);
block_num = length(stimuli_seq)/trial_num;
for block = 0:block_num-1
    for i = block*trial_num+1:(block+1)*trial_num
        if i == block*trial_num+1 | i == block*trial_num+2
            targetType{i,1}  = 'filler';
            targetType{i,2}  = 'none';
        elseif sum(stimuli_seq(block*trial_num+1:i-1) == stimuli_seq(i))
            samimageSeq = find(stimuli_seq(block*trial_num+1:i-1) == stimuli_seq(i))+block*trial_num;
            %if samimageSeq == i-1 || samimageSeq == i-3
             %   targetType{i,1}  = 'lure';
              %  targetType{i,2}  = 'right';
            %elseif samimageSeq == i-2
             %   targetType{i,1}  = 'same';
             %   targetType{i,2}  = 'left';
             if sum(samimageSeq == i-2)
                 targetType{i,1}  = 'same';
                 targetType{i,2}  = 'same';
             else
                 targetType{i,1}  = 'lure';
                 targetType{i,2}  = 'diff';
            end
        else
            targetType{i,1}  = 'diff';
            targetType{i,2}  = 'diff';
        end
    end
end
end