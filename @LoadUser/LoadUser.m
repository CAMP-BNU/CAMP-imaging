classdef LoadUser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure  matlab.ui.Figure
        Button_2  matlab.ui.control.Button
        Button    matlab.ui.control.Button
        UITable   matlab.ui.control.Table
    end

    
    properties (Access = private)
        users_history
        progress_history
        calling_app
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp, users_history, progress_history)
            app.calling_app = mainApp;
            app.users_history = users_history;
            app.UITable.Data = app.users_history;
            app.progress_history = progress_history;
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
            if isempty(app.UITable.Selection)
                uialert(app.UIFigure, '还未选择用户，请选择一个用户', ...
                    '未选择', 'Icon', 'warning')
                return
            end
            user = table2struct(app.users_history(app.UITable.Selection, :));
            if app.progress_history.session_active(app.progress_history.user_id == user.id) == 0
                choice = uiconfirm(app.UIFigure, ...
                    '已选择被试已完成全部项目，仍然导入？', ...
                    '导入确认', ...
                    'Icon', 'warning', ...
                    'Options', {'重新选择', '继续导入'});
                if choice == "重新选择"
                    return
                end
            end
            app.calling_app.load_user(user)
            app.calling_app.panel_user.Enable = "on";
            app.calling_app.button_modify.Enable = "on";
            delete(app)
        end

        % Button pushed function: Button_2
        function Button_2Pushed(app, event)
            app.calling_app.panel_user.Enable = "on";
            delete(app)
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
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
            app.UIFigure.Position = [100 100 500 400];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'编号'; '姓名'; '性别'; '生日'};
            app.UITable.RowName = {};
            app.UITable.SelectionType = 'row';
            app.UITable.Multiselect = 'off';
            app.UITable.Position = [51 99 400 250];

            % Create Button
            app.Button = uibutton(app.UIFigure, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Position = [124 41 100 23];
            app.Button.Text = '导入';

            % Create Button_2
            app.Button_2 = uibutton(app.UIFigure, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2Pushed, true);
            app.Button_2.Position = [283 41 100 23];
            app.Button_2.Text = '取消';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = LoadUser(varargin)

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