classdef StartPractice < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure  matlab.ui.Figure
        LabelPC   matlab.ui.control.Label
        Button    matlab.ui.control.Button
        Label     matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: Button
        function ButtonPushed(app, event)
            [status, exception, recordings] = exp.start_twoback("prac", "SkipSyncTests", true, "SaveData", false);
            if status ~= 0
                if status == 2
                    uialert(app.UIFigure, '用户提前退出了，将不更新正确率', ...
                        '确认完成情况', 'Icon', 'warning')
                end
                if ~isempty(exception)
                    uialert(app.UIFigure, getReport(exception), ...
                        '出错了', 'Interpreter', 'html');
                end
                return
            end
            pc = mean(recordings.acc(recordings.cond ~= "filler"), 'omitnan');
            app.LabelPC.Text = sprintf('上一次正确率：%.1f%%', pc * 100);
            app.LabelPC.Visible = "on";
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [300 300 350 200];
            app.UIFigure.Name = 'MATLAB App';

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'center';
            app.Label.FontName = 'Microsoft YaHei UI';
            app.Label.FontSize = 18;
            app.Label.Position = [138 134 77 24];
            app.Label.Text = '准备部分';

            % Create Button
            app.Button = uibutton(app.UIFigure, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.FontName = 'Microsoft YaHei UI';
            app.Button.Position = [126 77 100 23];
            app.Button.Text = '练习一次';

            % Create LabelPC
            app.LabelPC = uilabel(app.UIFigure);
            app.LabelPC.HorizontalAlignment = 'center';
            app.LabelPC.FontName = 'Microsoft YaHei UI';
            app.LabelPC.Visible = 'off';
            app.LabelPC.Position = [102 45 148 22];
            app.LabelPC.Text = '上一次正确率：        ';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = StartPractice

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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