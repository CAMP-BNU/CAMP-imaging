
function [sum_num,distance,dis_times] = check_sequence(T)
cate_list = {'face','object','place','word'};
distance = zeros(4,45);
dis_times = zeros(4,45);
for cate = 1:4
    for stim = 1:45
        same_item_seq = find(T{:,5} == stim & strcmp(cellstr(T{:,3}),cate_list{cate}));
        dis_times(cate,stim) = length(same_item_seq);
        if dis_times(cate,stim) == 2
            distance(cate,stim) = same_item_seq(2)-same_item_seq(1);
        else
            distance(cate,stim) = 1;
        end
    end
end
a=max(max(distance));
for cate = 1:4
    for distance_value=1:a
        sum_num(cate,distance_value) = length(find(distance(cate,:)==distance_value));
    end
end
sum_num(5,:) = sum(sum_num);
end