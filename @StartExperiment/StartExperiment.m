classdef StartExperiment < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        Menu                    matlab.ui.container.Menu
        menu_create_user        matlab.ui.container.Menu
        menu_load_user          matlab.ui.container.Menu
        Menu_2                  matlab.ui.container.Menu
        menu_upload_data        matlab.ui.container.Menu
        menu_copy_data          matlab.ui.container.Menu
        Panel                   matlab.ui.container.Panel
        start_fixation          matlab.ui.control.Button
        PTBPanel                matlab.ui.container.Panel
        switch_skip_sync_tests  matlab.ui.control.Switch
        SwitchLabel             matlab.ui.control.Label
        tab_all_tests           matlab.ui.container.TabGroup
        tab_day_one             matlab.ui.container.Tab
        panel_resting1          matlab.ui.container.Panel
        resting1_run1           matlab.ui.control.Button
        panel_assocmem          matlab.ui.container.Panel
        assocmem_run1           matlab.ui.control.Button
        assocmem_run2           matlab.ui.control.Button
        panel_movie1            matlab.ui.container.Panel
        movie1_run1             matlab.ui.control.Button
        movie1_run2             matlab.ui.control.Button
        panel_struct1           matlab.ui.container.Panel
        struct1                 matlab.ui.control.Button
        tab_day_two             matlab.ui.container.Tab
        panel_resting2          matlab.ui.container.Panel
        resting2_run1           matlab.ui.control.Button
        panel_twoback           matlab.ui.container.Panel
        twoback_run1            matlab.ui.control.Button
        twoback_run2            matlab.ui.control.Button
        twoback_run3            matlab.ui.control.Button
        panel_movie2            matlab.ui.container.Panel
        movie2_run1             matlab.ui.control.Button
        movie2_run2             matlab.ui.control.Button
        panel_struct2           matlab.ui.container.Panel
        struct2                 matlab.ui.control.Button
        panel_user              matlab.ui.container.Panel
        button_modify           matlab.ui.control.Button
        Label_6                 matlab.ui.control.Label
        label_user_dob          matlab.ui.control.Label
        label_user_sex          matlab.ui.control.Label
        Label_3                 matlab.ui.control.Label
        label_user_name         matlab.ui.control.Label
        Label                   matlab.ui.control.Label
        label_user_id           matlab.ui.control.Label
        Label_7                 matlab.ui.control.Label
    end

    
    properties (Access = private)
        % user information
        user 
        user_confirmed = false

        % users and progress history
        users_history
        progress_history

        % progress management
        % session means the first and the second day
        % project means each sub project in each day
        % note each time should complete only one session
        session_active % current ongoing session
        project_active % current ongoing project
        project_progress % completed items for ongoing project
        session_init % initiative session, supposed to be completed

        % ptb parameters
        skip_sync_tests = false
    end
    
    properties (Access = private, Constant)
        % experiment properties
        exp_name = "CAMP-IMAGING"

        % make sure this name is part of the panel
        project_names = ["resting1", "assocmem", "movie1", "struct1", ...
            "resting2", "twoback", "movie2", "struct2"]
        project_runs = [1, 2, 2, 1, 1, 3, 2, 1]
        sessions = [4, 4];

        % data files (csv format)
        progress_file = fullfile(".db", "progress.txt")
        user_file = fullfile(".db", "user.txt")
    end
    
    methods (Access = public)

        function push_user(app, user)
            app.user = user;
            app.label_user_id.Text = string(app.user.id);
            app.label_user_name.Text = string(app.user.name);
            app.label_user_sex.Text = app.user.sex;
            app.label_user_dob.Text = string(app.user.dob, 'yyyy-MM-dd');
            if user.id ~= 0
                app.log_user()
            end
        end

        function register_user(app, user)
            app.push_user(user)
            app.user_confirmed = true;
            app.proceed_next()
        end

        function load_user(app, user)
            % update progress
            progress = app.progress_history(app.progress_history.user_id == user.id, :);
            app.project_active = progress.project_active;
            app.project_progress = progress.project_progress;
            app.session_active = progress.session_active;
            app.session_init = progress.session_active;

            % update ui
            for i = 1:app.project_active - 1
                panel_project = app.("panel_" + app.project_names(i));
                panel_project.Enable = "on";
                for btn = panel_project.Children'
                    btn.Enable = "off";
                end
            end
            panel_active = app.("panel_" + app.project_names(app.project_active));
            panel_active.Enable = "on";
            btns_active = panel_active.Children';
            for i = 1:app.project_progress
                btns_active(i).Enable = "off";
            end

            % remove current user from users and progress history
            app.users_history(app.users_history.id == user.id, :) = [];
            app.progress_history(app.progress_history.user_id == user.id, :) = [];

            % update user info to user panel
            app.push_user(user)
            app.user_confirmed = true;
        end

        function log_progress(app)
            progress = table( ...
                app.user.id, app.session_active, app.project_active, app.project_progress, ...
                'VariableNames', ...
                ["user_id", "session_active", "project_active", "project_progress"]);
            writetable(vertcat(app.progress_history, progress), ...
                app.progress_file)
        end

        function log_user(app)
            writetable( ...
                vertcat(app.users_history, struct2table(app.user)), ...
                app.user_file)
        end
    end
    
    methods (Access = private)
        
        function initialize(app)
            if exist(app.progress_file, "file")
                app.progress_history = readtable(app.progress_file, "TextType", "string");
            else
                app.progress_history = table();
            end
            if exist(app.user_file, "file")
                opts = detectImportOptions(app.user_file);
                % make sure name and sex is read as string
                text_cols = ismember(opts.VariableNames, ["name", "sex"]);
                opts.VariableTypes(text_cols) = {'string', 'string'};
                app.users_history = readtable(app.user_file, opts);
            else
                app.users_history = table();
            end

            % reset everything as factory setting
            app.panel_user.Enable = "on";
            app.button_modify.Enable = "off";
            app.label_user_id.Text = "待创建";
            app.label_user_name.Text = "待创建";
            app.label_user_sex.Text = "待创建";
            app.label_user_dob.Text = "待创建";
            app.user_confirmed = false;
            app.session_active = 1;
            app.session_init = 1;
            app.project_active = 0;
            app.project_progress = 0;

            % disable all childrens in test tabs, but enable their children
            tabs = app.tab_all_tests.Children';
            for tab = tabs
                for panel = tab.Children'
                    panel.Enable = "off";
                    for btn = panel.Children'
                        btn.Enable = "on";
                        btn.BackgroundColor = [0.96, 0.96, 0.96];
                        btn.Tooltip = "";
                    end
                end
            end
        end

        function proceed_next(app)
            if app.project_active ~= 0 
                app.project_progress = app.project_progress + 1;
            end
            if app.project_active == 0 || ...
                    app.project_progress == app.project_runs(app.project_active)
                app.proceed_next_project()
            end
            if app.user.id ~= 0
                % user of id 0 is left for tests
                app.log_progress()
            end
        end

        function proceed_next_project(app)
            % set active session as 0 when all completed            
            if app.project_active == length(app.project_names)
                app.session_active = 0;
                return
            end
            % cumulative completed projects for sessions
            cum_ses_proj = cumsum(app.sessions);
            if app.project_active == cum_ses_proj(app.session_active)
                app.session_active = app.session_active + 1;
            end
            app.project_active = app.project_active + 1;
            app.project_progress = 0;
            app.("panel_" + app.project_names(app.project_active)).Enable = "on";
        end

        function display_stimuli(app, event)
            proj_name_active = app.project_names(app.project_active);
            result = [];
            if contains(proj_name_active, regexpPattern("resting|struct"))
                [status, exception] = exp.start_fixation("Mode", "auto", "SkipSyncTests", app.skip_sync_tests);
            elseif contains(proj_name_active, "movie")
                run_id = (app.session_active - 1) * 2 + app.project_progress + 1;
                [status, exception] = exp.start_movie(run_id, "id", app.user.id, "SkipSyncTests", app.skip_sync_tests);
            elseif contains(proj_name_active, "twoback")
                [status, exception, recordings] = exp.start_twoback("test", app.project_progress + 1, "id", app.user.id, "SkipSyncTests", app.skip_sync_tests);
                result = mean(recordings.acc(~ismember(recordings.cond, ["filler", "rest"])), 'omitnan');
                if isnan(result)
                    result = 0;
                end
            else
                exception = [];
                try
                    [status, result] = exp.start_amt("test", app.project_progress + 1, ...
                        "id", app.user.id, "SkipSyncTests", app.skip_sync_tests);
                catch exception
                    status = 1;
                end
            end
            app.check_progress(status, exception, event.Source, result)
        end
        
        function check_progress(app, status, exception, component, result)
            if status == 2
                selection = uiconfirm(app.UIFigure, ...
                    '本流程似乎已经提前退出，请确认是否完成？', ...
                    '确认完成情况', ...
                    'Icon', 'warning', ...
                    'Options', {'已完成', '未完成'}, ...
                    'DefaultOption', '未完成');
                is_completed = selection == "已完成";
            else
                is_completed = status == 0;
            end
            component.Tooltip = "";
            app.report_status(status, exception, component)
            if is_completed
                if ~isempty(result)
                    if length(result) == 1
                        tooltip = sprintf("正确率：%.1f%%。", result * 100);
                    else
                        tooltip = arrayfun(@(type, pc) sprintf("%s正确率：%.1f%%", type, pc), ...
                            ["背景", "位置"], result * 100);
                    end
                    app.append_tooltip(component, tooltip)
                end
                component.Enable = "off";
                app.proceed_next()
            end
        end

        function report_status(app, status, exception, component)
            if status ~= 0
                if isempty(exception)
                    component.BackgroundColor = "yellow";
                    if status == 2
                        app.append_tooltip(component, "最近一次运行提前退出!")
                    end
                else
                    component.BackgroundColor = "red";
                    uialert(app.UIFigure, getReport(exception), ...
                        '出错了', 'Interpreter', 'html');
                end
            else
                component.BackgroundColor = "green";
            end
        end

        function result = check_session_confirm(app)
            result = true;
            if app.user_confirmed && ...
                    app.session_active ~= 0 && ...
                    app.session_active == app.session_init
                selection = uiconfirm(app.UIFigure, ...
                    '当前被试还未完成今天的全部项目，仍然继续？', ...
                    '确认完成情况', ...
                    'Icon', 'warning', ...
                    'Options', {'点错了，返回', '继续'});
                if selection == "点错了，返回"
                    result = false;
                end
            end
        end

        function append_tooltip(~, component, tooltip)
            if component.Tooltip ~= ""
                tooltip = [component.Tooltip, tooltip];
            end
            component.Tooltip = tooltip;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.initialize()
            app.switch_skip_sync_tests.Value = "关闭";
        end

        % Menu selected function: menu_create_user
        function menu_create_userSelected(app, event)
            if ~app.check_session_confirm()
                return
            end
            app.initialize()
            % disable whole user panel when editing user
            app.panel_user.Enable = "off";
            CreateOrModifyUser(app, "create", ...
                "UsersHistory", app.users_history);
        end

        % Button pushed function: button_modify
        function button_modifyButtonPushed(app, event)
            % disable whole user panel when editing user
            app.panel_user.Enable = "off";
            CreateOrModifyUser(app, "modify", ...
                "UsersHistory", app.users_history, ...
                "User", app.user);
        end

        % Menu selected function: menu_load_user
        function menu_load_userMenuSelected(app, event)
            if isempty(app.users_history)
                uialert(app.UIFigure, '没有可导入的被试，请先创建用户。', ...
                    '导入警告', 'Icon', 'warning')
                return
            end
            if ~app.check_session_confirm()
                return
            end
            app.initialize()
            % disable whole user panel when editing user
            app.panel_user.Enable = "off";
            LoadUser(app, app.users_history, app.progress_history);
        end

        % Value changed function: switch_skip_sync_tests
        function switch_skip_sync_testsValueChanged(app, event)
            switch app.switch_skip_sync_tests.Value
                case "打开"
                    app.skip_sync_tests = true;
                case "关闭"
                    app.skip_sync_tests = false;
            end
        end

        % Button pushed function: assocmem_run1, assocmem_run2, 
        % ...and 11 other components
        function projectStartButtonPushed(app, event)
            app.display_stimuli(event)
        end

        % Button pushed function: start_fixation
        function start_fixationButtonPushed(app, event)
            [status, exception] = exp.start_fixation("Mode", "auto", "SkipSyncTests", app.skip_sync_tests);
            app.report_status(status, exception, event.Source)
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            if ~app.check_session_confirm()
                return
            end
            delete(app)
        end

        % Menu selected function: menu_copy_data
        function menu_copy_dataSelected(app, event)
            dest = uigetdir();
            if dest == 0 
                return
            end
            if strcmp(dest, pwd)
                uialert(app.UIFigure, '不能拷贝到软件的运行目录，已取消拷贝', ...
                    '目录问题', 'Icon', 'warning')
                return
            end
            outfile = fullfile(dest, ...
                sprintf('%s-%s.zip', ...
                app.exp_name, ...
                datetime("now", "Format", "yyyyMMdd_HHmmss")));
            try
                zip(outfile, {'.db', 'data'})
                uialert(app.UIFigure, sprintf('已将数据拷贝至%s', outfile), ...
                    '拷贝成功', 'Icon', 'success')
            catch exception
                uialert(app.UIFigure, getReport(exception), ...
                        '拷贝出错', 'Interpreter', 'html');
            end
        end

        % Menu selected function: menu_upload_data
        function menu_upload_dataMenuSelected(app, event)
            uialert(app.UIFigure, '暂未支持，开发中...', '开发中', 'Icon', 'info')
            return
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 500];
            app.UIFigure.Name = '测评操作台';
            app.UIFigure.Icon = 'logo.png';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create Menu
            app.Menu = uimenu(app.UIFigure);
            app.Menu.Text = '用户';

            % Create menu_create_user
            app.menu_create_user = uimenu(app.Menu);
            app.menu_create_user.MenuSelectedFcn = createCallbackFcn(app, @menu_create_userSelected, true);
            app.menu_create_user.Accelerator = 'N';
            app.menu_create_user.Text = '新建';

            % Create menu_load_user
            app.menu_load_user = uimenu(app.Menu);
            app.menu_load_user.MenuSelectedFcn = createCallbackFcn(app, @menu_load_userMenuSelected, true);
            app.menu_load_user.Accelerator = 'L';
            app.menu_load_user.Text = '导入';

            % Create Menu_2
            app.Menu_2 = uimenu(app.UIFigure);
            app.Menu_2.Text = '数据';

            % Create menu_upload_data
            app.menu_upload_data = uimenu(app.Menu_2);
            app.menu_upload_data.MenuSelectedFcn = createCallbackFcn(app, @menu_upload_dataMenuSelected, true);
            app.menu_upload_data.Text = '上传';

            % Create menu_copy_data
            app.menu_copy_data = uimenu(app.Menu_2);
            app.menu_copy_data.MenuSelectedFcn = createCallbackFcn(app, @menu_copy_dataSelected, true);
            app.menu_copy_data.Text = '拷贝至...';

            % Create panel_user
            app.panel_user = uipanel(app.UIFigure);
            app.panel_user.TitlePosition = 'centertop';
            app.panel_user.Title = '用户信息';
            app.panel_user.FontName = 'Microsoft YaHei UI';
            app.panel_user.FontSize = 16;
            app.panel_user.Position = [53 266 250 215];

            % Create Label_7
            app.Label_7 = uilabel(app.panel_user);
            app.Label_7.FontName = 'Microsoft YaHei UI';
            app.Label_7.Position = [55 148 29 22];
            app.Label_7.Text = '编号';

            % Create label_user_id
            app.label_user_id = uilabel(app.panel_user);
            app.label_user_id.HorizontalAlignment = 'center';
            app.label_user_id.FontName = 'Microsoft YaHei UI';
            app.label_user_id.Position = [134 148 41 22];
            app.label_user_id.Text = '待创建';

            % Create Label
            app.Label = uilabel(app.panel_user);
            app.Label.FontName = 'Microsoft YaHei UI';
            app.Label.Position = [55 114 29 22];
            app.Label.Text = '姓名';

            % Create label_user_name
            app.label_user_name = uilabel(app.panel_user);
            app.label_user_name.HorizontalAlignment = 'center';
            app.label_user_name.FontName = 'Microsoft YaHei UI';
            app.label_user_name.Position = [114 114 80 22];
            app.label_user_name.Text = '待创建';

            % Create Label_3
            app.Label_3 = uilabel(app.panel_user);
            app.Label_3.FontName = 'Microsoft YaHei UI';
            app.Label_3.Position = [55 80 29 22];
            app.Label_3.Text = '性别';

            % Create label_user_sex
            app.label_user_sex = uilabel(app.panel_user);
            app.label_user_sex.HorizontalAlignment = 'center';
            app.label_user_sex.FontName = 'Microsoft YaHei UI';
            app.label_user_sex.Position = [134 80 41 22];
            app.label_user_sex.Text = '待创建';

            % Create label_user_dob
            app.label_user_dob = uilabel(app.panel_user);
            app.label_user_dob.HorizontalAlignment = 'center';
            app.label_user_dob.FontName = 'Microsoft YaHei UI';
            app.label_user_dob.Position = [117 46 76 22];
            app.label_user_dob.Text = '待创建';

            % Create Label_6
            app.Label_6 = uilabel(app.panel_user);
            app.Label_6.FontName = 'Microsoft YaHei UI';
            app.Label_6.Position = [55 47 29 22];
            app.Label_6.Text = '生日';

            % Create button_modify
            app.button_modify = uibutton(app.panel_user, 'push');
            app.button_modify.ButtonPushedFcn = createCallbackFcn(app, @button_modifyButtonPushed, true);
            app.button_modify.Tooltip = {'修改当前用户信息。'};
            app.button_modify.Position = [84 15 63 23];
            app.button_modify.Text = '修改信息';

            % Create tab_all_tests
            app.tab_all_tests = uitabgroup(app.UIFigure);
            app.tab_all_tests.Position = [357 35 406 446];

            % Create tab_day_one
            app.tab_day_one = uitab(app.tab_all_tests);
            app.tab_day_one.Title = '第一天';

            % Create panel_struct1
            app.panel_struct1 = uipanel(app.tab_day_one);
            app.panel_struct1.TitlePosition = 'centertop';
            app.panel_struct1.Title = '结构像';
            app.panel_struct1.FontName = 'Microsoft YaHei UI';
            app.panel_struct1.FontSize = 16;
            app.panel_struct1.Position = [73 24 260 83];

            % Create struct1
            app.struct1 = uibutton(app.panel_struct1, 'push');
            app.struct1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.struct1.Position = [84 20 100 23];
            app.struct1.Text = '开始';

            % Create panel_movie1
            app.panel_movie1 = uipanel(app.tab_day_one);
            app.panel_movie1.TitlePosition = 'centertop';
            app.panel_movie1.Title = '电影观看';
            app.panel_movie1.FontName = 'Microsoft YaHei UI';
            app.panel_movie1.FontSize = 16;
            app.panel_movie1.Position = [73 125 260 84];

            % Create movie1_run2
            app.movie1_run2 = uibutton(app.panel_movie1, 'push');
            app.movie1_run2.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.movie1_run2.Position = [145 21 66 23];
            app.movie1_run2.Text = '第二轮';

            % Create movie1_run1
            app.movie1_run1 = uibutton(app.panel_movie1, 'push');
            app.movie1_run1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.movie1_run1.Position = [46 21 66 23];
            app.movie1_run1.Text = '第一轮';

            % Create panel_assocmem
            app.panel_assocmem = uipanel(app.tab_day_one);
            app.panel_assocmem.TitlePosition = 'centertop';
            app.panel_assocmem.Title = '联系记忆任务';
            app.panel_assocmem.FontName = 'Microsoft YaHei UI';
            app.panel_assocmem.FontSize = 16;
            app.panel_assocmem.Position = [73 223 260 87];

            % Create assocmem_run2
            app.assocmem_run2 = uibutton(app.panel_assocmem, 'push');
            app.assocmem_run2.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.assocmem_run2.Position = [147 21 66 23];
            app.assocmem_run2.Text = '第二轮';

            % Create assocmem_run1
            app.assocmem_run1 = uibutton(app.panel_assocmem, 'push');
            app.assocmem_run1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.assocmem_run1.Position = [48 21 66 23];
            app.assocmem_run1.Text = '第一轮';

            % Create panel_resting1
            app.panel_resting1 = uipanel(app.tab_day_one);
            app.panel_resting1.TitlePosition = 'centertop';
            app.panel_resting1.Title = '准备与静息态';
            app.panel_resting1.FontName = 'Microsoft YaHei UI';
            app.panel_resting1.FontSize = 16;
            app.panel_resting1.Position = [73 326 260 75];

            % Create resting1_run1
            app.resting1_run1 = uibutton(app.panel_resting1, 'push');
            app.resting1_run1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.resting1_run1.Position = [82 15 96 23];
            app.resting1_run1.Text = '开始';

            % Create tab_day_two
            app.tab_day_two = uitab(app.tab_all_tests);
            app.tab_day_two.Title = '第二天';

            % Create panel_struct2
            app.panel_struct2 = uipanel(app.tab_day_two);
            app.panel_struct2.TitlePosition = 'centertop';
            app.panel_struct2.Title = '结构像';
            app.panel_struct2.FontName = 'Microsoft YaHei UI';
            app.panel_struct2.FontSize = 16;
            app.panel_struct2.Position = [74 24 260 83];

            % Create struct2
            app.struct2 = uibutton(app.panel_struct2, 'push');
            app.struct2.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.struct2.Position = [83 20 100 23];
            app.struct2.Text = '开始';

            % Create panel_movie2
            app.panel_movie2 = uipanel(app.tab_day_two);
            app.panel_movie2.TitlePosition = 'centertop';
            app.panel_movie2.Title = '电影观看';
            app.panel_movie2.FontName = 'Microsoft YaHei UI';
            app.panel_movie2.FontSize = 16;
            app.panel_movie2.Position = [73 123 260 84];

            % Create movie2_run2
            app.movie2_run2 = uibutton(app.panel_movie2, 'push');
            app.movie2_run2.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.movie2_run2.Position = [149 21 66 23];
            app.movie2_run2.Text = '第二轮';

            % Create movie2_run1
            app.movie2_run1 = uibutton(app.panel_movie2, 'push');
            app.movie2_run1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.movie2_run1.Position = [50 21 66 23];
            app.movie2_run1.Text = '第一轮';

            % Create panel_twoback
            app.panel_twoback = uipanel(app.tab_day_two);
            app.panel_twoback.TitlePosition = 'centertop';
            app.panel_twoback.Title = '工作记忆任务';
            app.panel_twoback.FontName = 'Microsoft YaHei UI';
            app.panel_twoback.FontSize = 16;
            app.panel_twoback.Position = [73 223 260 87];

            % Create twoback_run3
            app.twoback_run3 = uibutton(app.panel_twoback, 'push');
            app.twoback_run3.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.twoback_run3.Position = [182 16 66 23];
            app.twoback_run3.Text = '第三轮';

            % Create twoback_run2
            app.twoback_run2 = uibutton(app.panel_twoback, 'push');
            app.twoback_run2.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.twoback_run2.Position = [100 16 66 23];
            app.twoback_run2.Text = '第二轮';

            % Create twoback_run1
            app.twoback_run1 = uibutton(app.panel_twoback, 'push');
            app.twoback_run1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.twoback_run1.Position = [18 16 66 23];
            app.twoback_run1.Text = '第一轮';

            % Create panel_resting2
            app.panel_resting2 = uipanel(app.tab_day_two);
            app.panel_resting2.TitlePosition = 'centertop';
            app.panel_resting2.Title = '准备与静息态';
            app.panel_resting2.FontName = 'Microsoft YaHei UI';
            app.panel_resting2.FontSize = 16;
            app.panel_resting2.Position = [73 326 260 74];

            % Create resting2_run1
            app.resting2_run1 = uibutton(app.panel_resting2, 'push');
            app.resting2_run1.ButtonPushedFcn = createCallbackFcn(app, @projectStartButtonPushed, true);
            app.resting2_run1.Position = [82 15 95 23];
            app.resting2_run1.Text = '开始';

            % Create PTBPanel
            app.PTBPanel = uipanel(app.UIFigure);
            app.PTBPanel.TitlePosition = 'centertop';
            app.PTBPanel.Title = 'PTB参数';
            app.PTBPanel.FontName = 'Microsoft YaHei UI';
            app.PTBPanel.FontSize = 16;
            app.PTBPanel.Position = [53 141 250 112];

            % Create SwitchLabel
            app.SwitchLabel = uilabel(app.PTBPanel);
            app.SwitchLabel.HorizontalAlignment = 'center';
            app.SwitchLabel.Tooltip = {'一般情况下，打开此设置会减少出错，不过会减少时间精确性。'};
            app.SwitchLabel.Position = [77 16 77 22];
            app.SwitchLabel.Text = '跳过同步检测';

            % Create switch_skip_sync_tests
            app.switch_skip_sync_tests = uiswitch(app.PTBPanel, 'slider');
            app.switch_skip_sync_tests.Items = {'关闭', '打开'};
            app.switch_skip_sync_tests.ValueChangedFcn = createCallbackFcn(app, @switch_skip_sync_testsValueChanged, true);
            app.switch_skip_sync_tests.Position = [92 53 45 20];
            app.switch_skip_sync_tests.Value = '关闭';

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.Title = '备用';
            app.Panel.FontName = 'Microsoft YaHei UI';
            app.Panel.FontSize = 16;
            app.Panel.Position = [53 35 250 97];

            % Create start_fixation
            app.start_fixation = uibutton(app.Panel, 'push');
            app.start_fixation.ButtonPushedFcn = createCallbackFcn(app, @start_fixationButtonPushed, true);
            app.start_fixation.Position = [74 24 100 23];
            app.start_fixation.Text = '呈现注视点';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = StartExperiment

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end