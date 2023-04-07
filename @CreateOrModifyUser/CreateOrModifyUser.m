classdef CreateOrModifyUser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        Panel           matlab.ui.container.Panel
        button_cancel   matlab.ui.control.Button
        button_confirm  matlab.ui.control.Button
        ui_user_dob     matlab.ui.control.DatePicker
        Label_4         matlab.ui.control.Label
        ui_user_sex     matlab.ui.control.DropDown
        Label_3         matlab.ui.control.Label
        ui_user_name    matlab.ui.control.EditField
        Label_2         matlab.ui.control.Label
        ui_user_id      matlab.ui.control.NumericEditField
        Label           matlab.ui.control.Label
    end

    
    properties (Access = private)
        calling_app % the main app calls current app
        calling_type % can be "modify" or "create"
        user % a struct store user information
        users_history
    end
    
    methods (Access = private)
        
        function update_user(app, user)
            app.user = user;
            for user_property = string(fieldnames(user))'
                app.("ui_user_" + user_property).Value = user.(user_property);
            end
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, main_app, method, opts)
            arguments
                app
                main_app
                method {mustBeMember(method, ["create", "modify"])}
                opts.UsersHistory
                opts.User
            end
            app.calling_app = main_app;
            app.calling_type = method;
            app.users_history = opts.UsersHistory;
            if method == "modify"
                app.update_user(opts.User)
            end
        end

        % Button pushed function: button_confirm
        function button_confirmPushed(app, event)
            app.user = struct( ...
                'id', app.ui_user_id.Value, ...
                'name', string(app.ui_user_name.Value), ...
                'sex', string(app.ui_user_sex.Value), ...
                'dob', app.ui_user_dob.Value);
            if app.ui_user_id.Value == 0
                selection = uiconfirm(app.UIFigure, ...
                    '编号0不能用于正式测试，是否修改？', ...
                    '确认用户编号', ...
                    'Icon', 'warning', 'Options', {'是', '否'});
                if selection == "是"
                    return
                end
            elseif ~isempty(app.users_history) && ...
                    ismember(app.user.id, app.users_history.id)
                uialert(app.UIFigure, ...
                    '当前编号用户已存在，请修改', ...
                    '确认用户编号', ...
                    'Icon', 'warning');
                return
            end
            if ~isempty(app.users_history)
                cur_user = struct2table(app.user);
                matched = ismember(removevars(app.users_history, "id"), ...
                    removevars(cur_user, "id"));
                if any(matched)
                    uialert(app.UIFigure, ...
                        sprintf('当前用户已使用别的编号：%d，请修改', ...
                        app.users_history.id(matched)), ...
                        '确认用户信息', ...
                        'Icon', 'warning');
                    return
                end
            end
            switch app.calling_type
                case "create"
                    app.calling_app.register_user(app.user)
                case "modify"
                    app.calling_app.push_user(app.user)
            end
            app.calling_app.button_modify.Enable = "on";
            app.calling_app.panel_user.Enable = "on";
            delete(app)
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.calling_app.panel_user.Enable = "on";
            delete(app)
        end

        % Button pushed function: button_cancel
        function button_cancelPushed(app, event)
            app.calling_app.panel_user.Enable = "on";
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [350 200 300 300];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.Title = '用户信息';
            app.Panel.FontName = 'Microsoft YaHei UI';
            app.Panel.FontSize = 16;
            app.Panel.Position = [25 25 250 250];

            % Create Label
            app.Label = uilabel(app.Panel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.FontName = 'Microsoft YaHei UI';
            app.Label.Position = [54 177 29 22];
            app.Label.Text = '编号';

            % Create ui_user_id
            app.ui_user_id = uieditfield(app.Panel, 'numeric');
            app.ui_user_id.Limits = [0 Inf];
            app.ui_user_id.RoundFractionalValues = 'on';
            app.ui_user_id.ValueDisplayFormat = '%.0f';
            app.ui_user_id.HorizontalAlignment = 'center';
            app.ui_user_id.Tooltip = {'请输入整数'};
            app.ui_user_id.Position = [98 177 100 22];

            % Create Label_2
            app.Label_2 = uilabel(app.Panel);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.FontName = 'Microsoft YaHei UI';
            app.Label_2.Position = [54 143 29 22];
            app.Label_2.Text = '姓名';

            % Create ui_user_name
            app.ui_user_name = uieditfield(app.Panel, 'text');
            app.ui_user_name.HorizontalAlignment = 'center';
            app.ui_user_name.FontName = 'Microsoft YaHei UI';
            app.ui_user_name.Placeholder = '请输入';
            app.ui_user_name.Position = [98 143 100 22];

            % Create Label_3
            app.Label_3 = uilabel(app.Panel);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.FontName = 'Microsoft YaHei UI';
            app.Label_3.Position = [54 109 29 22];
            app.Label_3.Text = '性别';

            % Create ui_user_sex
            app.ui_user_sex = uidropdown(app.Panel);
            app.ui_user_sex.Items = {'男', '女'};
            app.ui_user_sex.FontName = 'Microsoft YaHei UI';
            app.ui_user_sex.Position = [98 109 100 22];
            app.ui_user_sex.Value = '男';

            % Create Label_4
            app.Label_4 = uilabel(app.Panel);
            app.Label_4.HorizontalAlignment = 'right';
            app.Label_4.FontName = 'Microsoft YaHei UI';
            app.Label_4.Position = [54 75 29 22];
            app.Label_4.Text = '生日';

            % Create ui_user_dob
            app.ui_user_dob = uidatepicker(app.Panel);
            app.ui_user_dob.Position = [97 75 100 22];

            % Create button_confirm
            app.button_confirm = uibutton(app.Panel, 'push');
            app.button_confirm.ButtonPushedFcn = createCallbackFcn(app, @button_confirmPushed, true);
            app.button_confirm.Position = [54 30 50 23];
            app.button_confirm.Text = '确认';

            % Create button_cancel
            app.button_cancel = uibutton(app.Panel, 'push');
            app.button_cancel.ButtonPushedFcn = createCallbackFcn(app, @button_cancelPushed, true);
            app.button_cancel.Position = [162 30 50 23];
            app.button_cancel.Text = '取消';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CreateOrModifyUser(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

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