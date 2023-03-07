function store_data(data, id, project, run)
%STORE_DATA Produce side effect of storing given data.

filename_stem = generate_storename(id, project, run);
% the main file contains no timestamp
writetable(data, fullfile('data', sprintf('%s.csv', filename_stem)));
% a temporary copy with timestamp
writetable(data, fullfile('data', ...
    sprintf('%s(time-%s).csv', filename_stem, ...
    datetime("now", "Format", "yyyyMMdd-HHmmss"))));

end

function name = generate_storename(id, project, run)
%GENERATE_STORENAME Generate stem of store file names

config_filename = readtable(fullfile('common', 'config_filename.csv'), ...
    TextType="string");
config_matched = config_filename( ...
    config_filename.project == project & ...
    config_filename.run == run, :);
name = sprintf('sub-%03d_ses-%d_task-%s_dir-%s_run-%d_events', ...
    id, config_matched.session, config_matched.project_store, ...
    config_matched.dir, config_matched.run_store);
end

