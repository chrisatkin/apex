function list = dir_contents(target)
% Return a list of the contents of a directory, excluding . and ..

% Get EVERYTHING in the directory
dir_list = dir(target);

% Get only the files
dir_list = {dir_list(~[dir_list.isdir]).name};

% Remove . and ..
list = dir_list(~(strcmp('.', dir_list) | strcmp('..', dir_list)));