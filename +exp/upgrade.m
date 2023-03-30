function varargout = upgrade(args)
%UPGRADE Fetch lastest release from github
%   This will just check if there is a newer version of this experiment and
%   fetch all the required files of this newer version from github.
%
%   Example usage:
%
%     % this will check if there is a new version only
%     exp.upgrade("InstallNow", "no")
%
%     % these two are identical, both check new version and install it
%     exp.upgrade
%     exp.upgrade("InstallNow", "yes")
%
%     % flag indicating newer version is found, latest version number and
%     % the status number are the three supported outputs respectively, and
%     % a status of 0 means succeeded, otherwise not
%     [foundnewer, latestver, status] = exp.upgrade(__);
arguments (Input)
    args.InstallNow {mustBeMember(args.InstallNow, ["yes", "no"])} = "yes"
end
% if a newer version has been found
foundnewer = false;
% return status, 0 means no error
status = 0;
curver = exp.version;
gh_host = 'https://github.com';
gh_handle = 'CAMP-BNU';
repo_name = 'CAMP-imaging';
path_repo = sprintf('%s/%s/%s', gh_host, gh_handle, repo_name);
url_release = sprintf('%s/releases', path_repo);
fprintf('Checking if there is a newer version...\n')
try
    % get the latest tag
    html_release = htmlTree(webread(url_release));
    % do some basic webscraping to extract all the tags of the repo
    latestver = html_release.findElement('section:first-child span.wb-break-all').extractHTMLText;
    if string(latestver) > string(curver)
        foundnewer = true;
        switch args.InstallNow
            case "yes"
                fprintf('A new version (%s) of expriment is found, will try to upgrade now.\n', latestver)
                % download the files of the latest version to temp dir
                page_newver = sprintf('%s/archive/refs/tags/%s.zip', path_repo, latestver);
                temp_newzip = fullfile(tempdir, 'new.zip');
                fprintf('Start downloading...')
                websave(temp_newzip, page_newver);
                unzip(temp_newzip, tempdir)
                % copy the upzipped files to working directory
                fprintf('Upgrading...')
                copy_folder = fullfile(tempdir, sprintf('%s-%s', repo_name, latestver));
                copyfile(copy_folder, '.')
                fprintf('Completed.\n')
                % remove all files we generated in temp dir
                delete(temp_newzip)
                rmdir(copy_folder, 's')
            case "no"
                fprintf('A new version (%s) of expriment is found, please run `%s` to upgrade.\n', latestver, mfilename)
        end
    else
        fprintf('You are awesome! Current version (%s) you used is the latest.\n', curver)
    end
catch ME
    % turn error as meaning warning
    if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
        status = 1;
        warning('Experiment:Upgrade:NotFound', ...
            'Upgrade failed! Some of the requested web pages not found.')
    elseif strcmp(ME.identifier, 'MATLAB:webservices:UnknownHost')
        status = 2;
        warning('Experiment:Upgrade:NetFailure', ...
            'Upgrade failed! Please check your network and make sure you have access to %s.', gh_host)
    else
        status = 3;
        warning('Experiment:Upgrade:InstallError', ...
            'Upgrade failed! Something unexpected happened.')
    end
end
% output if required
if nargout > 0
    varargout{1} = foundnewer;
end
if nargout > 1
    varargout{2} = latestver;
end
if nargout > 2
    varargout{3} = status;
end
end
