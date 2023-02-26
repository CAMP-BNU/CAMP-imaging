classdef StartPractice < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        label_amt_pc      matlab.ui.control.Label
        button_amt        matlab.ui.control.Button
        label_twoback_pc  matlab.ui.control.Label
        button_twoback    matlab.ui.control.Button
        Label             matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: button_twoback
        function button_twobackPushed(app, event)
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
            app.label_twoback_pc.Text = sprintf('上一次正确率：%.1f%%', pc * 100);
            app.label_twoback_pc.Visible = "on";
        end

        % Button pushed function: button_amt
        function button_amtButtonPushed(app, event)
            try 
                [~, ~, result] = exp.start_amt("prac", SkipSyncTests=true);
            catch exception
                if ~isempty(exception)
                    uialert(app.UIFigure, getReport(exception), ...
                        '出错了', 'Interpreter', 'html');
                end
                return
            end
            text = arrayfun(@(type, pc) sprintf("%s正确率：%.1f%%", type, pc), ...
                            ["背景", "位置"], result * 100);
            app.label_amt_pc.Text = ["上一次表现：", text];
            app.label_amt_pc.Visible = "on";
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

            % Create button_twoback
            app.button_twoback = uibutton(app.UIFigure, 'push');
            app.button_twoback.ButtonPushedFcn = createCallbackFcn(app, @button_twobackPushed, true);
            app.button_twoback.FontName = 'Microsoft YaHei UI';
            app.button_twoback.Position = [198 77 100 23];
            app.button_twoback.Text = '工作记忆练习';

            % Create label_twoback_pc
            app.label_twoback_pc = uilabel(app.UIFigure);
            app.label_twoback_pc.HorizontalAlignment = 'center';
            app.label_twoback_pc.FontName = 'Microsoft YaHei UI';
            app.label_twoback_pc.Visible = 'off';
            app.label_twoback_pc.Position = [174 45 148 22];
            app.label_twoback_pc.Text = '';

            % Create button_amt
            app.button_amt = uibutton(app.UIFigure, 'push');
            app.button_amt.ButtonPushedFcn = createCallbackFcn(app, @button_amtButtonPushed, true);
            app.button_amt.Position = [51 77 100 23];
            app.button_amt.Text = '联系记忆练习';

            % Create label_amt_pc
            app.label_amt_pc = uilabel(app.UIFigure);
            app.label_amt_pc.HorizontalAlignment = 'center';
            app.label_amt_pc.FontName = 'Microsoft YaHei UI';
            app.label_amt_pc.Visible = 'off';
            app.label_amt_pc.Position = [27 22 148 45];
            app.label_amt_pc.Text = '';

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