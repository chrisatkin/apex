function varargout = spinner(varargin)
%SPINNER create a 'spinner' from an edit box and two pushbuttons
% SPINNER(PROP1,VAL1,PROP2,VAL2,...) creates the spinner with the specified
%  property values.
%  Properties:
%    Position : pixel position rectangle, default [20 20 60 20]
%    Min : minimum value, default 0
%    Max : maximum value, default 1
%    StartValue : initial value, default 1
%    Step : increment value, default 0.1
%    Callback : callback (can be a string, function handle, 
%               or cell array with a function handle), default ''
%    Tag : name for spinner object.
% H = SPINNER returns the handle for the edit box that contains the value.
%  Access it's String or Value property to get the string or value from the
%  'spinner'.
% [H,H2] = SPINNER returns the handles for the pushbuttons in H2.
% S = SPINNER(OBJ) returns the spinner data for the figure.  If there are
%  multiple spinners in the figure, then passing in the figure handle will
%  return an array of structures.  Passing in the handle of one of the
%  uicontrols that comprise a particular spinner will return the structure
%  for that spinner only.
%
% Example:
% 
%    fig = figure;
%    h = spinner('Parent',fig,...
%                'Position',[100 100 60 40],...
%                'Min',0,...
%                'Max',1000000,...
%                'StartValue',1,...
%                'Step',100,...
%                'Callback',@(h,e));



% quick return, if they want the spinner info
if nargin == 1 && nargout == 1
    varargout{1} = spinnerdata(varargin{1});
    return
end
    



% list of valid properties
validprops = {'position';...
              'min';...
              'max';...
              'startvalue';...
              'step';...
              'parent';...
              'callback';...
              'tag'};
          
% default values              
pos = [20 20 60 20];
minimum = 0;
maximum = 1;
step = 0.1;
start_value = 1;
parent = [];
callback = '';
tag = 'spinner';

if mod(nargin,2) ~= 0
    error('Incorrect number of inputs.  Must be an even number of inputs.');
end

% parse inputs
for n = 1:2:nargin
    prop = lower(varargin{n});
    val = varargin{n+1};
    
    ind = strmatch(prop,validprops);
    if isempty(ind)
        ind = 0;
    end
    
    switch ind
        case 1 %Position
            if ~isnumeric(val) || any(size(val) ~= [1,4])
                error('Position must be numeric, 1 by 4 vector.')
            end
            pos = val;
        case 2 %Min
            if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                error('Min must be a finite numeric scalar.')
            end
            minimum = val;
        case 3 %Max       
            if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                error('Max must be a finite numeric scalar.')
            end
            maximum = val;
        case 4 %StartValue
            if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                error('StartValue must be a finite numeric scalar.')
            end
            start_value = val;
        case 5 %Step
            if ~isnumeric(val) || ~isfinite(val) || numel(val) ~= 1
                error('Step must be a finite numeric scalar.')
            end
            step = val;
        case 6 %Parent
            if isempty(val) || ~ishandle(val) || ~any(strcmp(get(val,'Type'),{'figure';'uipanel'}))
                parent = val;
            end
        case 7 %Callback
            if ~ischar(val) && ~isa(val,'function_handle') && ...
               (~iscell(val) || ...
                  (~ischar(val{1})  && ~isa(val{1},'function_handle')))
                  error(['Callback must be a string, function handle, ' ...
                          'or a cell array with a first element that is a ' ...
                          'string or function handle.']);
            end
            callback = val;
        case 8 %Tag
            if ~ischar(val)
                error('Tag must be a string.')
            end
            tag = val;
        otherwise
            error('Unrecognized property "%s".',varargin{n});
    end
end

% more error checking
if minimum >= maximum
    error('Min must be less than Max.');
end

if start_value <minimum || start_value > maximum
    error('StartValue must be between Min and Max.')
end

% Parent not specified, use current figure
if isempty(parent)
    parent = gcf;
end

% size for pushbuttons
push_width = 20;
push_height = round(pos(4)/2);
button_width = push_width;
if mod(button_width,2) ~= 0;
    button_width = push_width - 1;    
end

% put background color in proper orientation 1 by 1 by3
uicontrolcolor = reshape(get(0,'defaultuicontrolbackgroundcolor'),[1,1,3]);

% array for pushbutton's CData
button_size = 16;
mid = button_size/2;
push_cdata = repmat(uicontrolcolor,button_size,button_size);

% create arrow shape
for r = 4:11
    start = mid - r + 8 ;
    last = mid + r - 8;
    push_cdata(r,start:last,:) = 0;
end

% create uicontrols
h_edit = uicontrol('Units','pixels',...
                 'Position',pos,...
                 'Style','edit',...
                 'Tag',[tag '_edit'],...
                 'String',num2str(start_value),...
                 'Value',start_value,...
                 'Min',minimum,...
                 'Max',maximum,...
                 'Parent',parent,...
                 'HorizontalAlignment','left');
if ispc
    set(h_edit,'BackGroundColor',[1 1 1])
end
             
h_down = uicontrol('Units','pixels',...
                 'Position',[pos(1) + (pos(3) - push_width) - 2, pos(2) + 2, push_width, push_height - 2],...
                 'CData',flipdim(push_cdata,1),...
                 'Tag',[tag '_down'],...
                 'Parent',parent,...
                 'SelectionHighlight','off');
h_up = uicontrol('Units','pixels',...
                 'Position',[pos(1) + (pos(3) - push_width) - 2, pos(2) + push_height, push_width, pos(4) - push_height - 2],...
                 'CData',push_cdata,...
                 'Tag',[tag '_up'],...
                 'Parent',parent,...
                 'SelectionHighlight','off');
             
% structure with useful info                 
spinner_struct.edit = h_edit;
spinner_struct.down = h_down;
spinner_struct.up = h_up;
spinner_struct.step = step;
spinner_struct.start_value = start_value;
spinner_struct.last_valid_value = start_value;
spinner_struct.callback = callback;
spinner_struct.tag = tag;

% store useful info, SPINNERDATA is like a simple GUIDATA
spinnerdata(h_edit,spinner_struct);

% callbacks
set(h_down,'Callback',@increment_down);
set(h_up,'Callback',@increment_up);
set(h_edit,'KeyPressFcn',@edit_keypress);

%outputs
if(nargout)
    varargout{1} = h_edit;
    varargout{2} = [h_down; h_up];
end

% ---------------------------------------------------------
function edit_keypress(h,e)
%EDIT_KEYPRESS KeyPressFcn for the edit window

% get useful info
s = spinnerdata(h);

% get information about KeyPress event
c = e.Character;
k = e.Key;
str = get(h,'String');

% valid number characters
numbers = {'0';'1';'2';'3';'4';'5';'6';'7';'8';'9'};

if strcmp(k,'backspace')
    % if it's a backspace, remove the last character
    if numel(str) > 0
        str = str(1:end-1);
    end
elseif any(strcmp(c,numbers)) || strcmp(c,'.')
    % aonly allow number or '.'
    str = [str c];
end

% check the values
[v,str] = check_value(str,s);
set(h,'Value',v);

% switch the focus, then back, so setting the String has an effect.
uicontrol(s.up);
uicontrol(h);
set(h,'String',str);

% execute the callback
execute_callback(s);

% ---------------------------------------------------------
function execute_callback(s)
%EXECUTE_CALLBACK execute the callback

% only execute if there's something in the edit window
if ~isempty(get(s.edit,'String'))
    if ischar(s.callback)
        evalin('base',s.callback);
    elseif isa(s.callback,'function_handle')
        feval(s.callback,gcbo,[])
    elseif iscell(s.callback)
        feval(s.callback{:})
    end
end

% ---------------------------------------------------------
function [v,str] = check_value(str,s)
%CHECK_VALUE make sure the entry is a valid number

if ~isnumeric(str)
    % if it's a string, convert to get numeric value
    v = str2num(str);
else
    % otherwise, reassign the value, convert number to string
    v = str;
    str = num2str(v);
end

% return early if the string wasn't a valid number
if isempty(v) || isempty(str)
    return
end

minimum = get(s.edit,'Min');
maximum = get(s.edit,'Max');

% make sure value is in range
if v < minimum
    v = minimum;
    str = num2str(v);
elseif v > maximum;
    v = maximum;
    str = num2str(v);
end

% store the last valid value
s.last_valid_value = v;
spinnerdata(s.edit,s);


% ---------------------------------------------------------
function increment_down(h,e)
%INCREMENT_DOWN Callback for down pushbutton

%get useful info
s = spinnerdata(h);

% get string, convert to number, reduce by step
str = get(s.edit,'String');
v = str2num(str);
v = v-s.step;

% check the values
[v,str] = check_value(v,s);

% set the String and Value
set(s.edit,'String',num2str(v),'Value',v);

% execute the callbacks
execute_callback(s);

% ---------------------------------------------------------
function increment_up(h,e)
%INCREMENT_DOWN Callback for up pushbutton

%get useful info
s = spinnerdata(h);

% get string, convert to number, reduce by step
str = get(s.edit,'String');
v = str2num(str);
v = v+s.step;

% check the values
[v,str] = check_value(v,s);

% set the String and Value
set(s.edit,'String',num2str(v),'Value',v);

% execute the callbacks
execute_callback(s);

% ---------------------------------------------------------
function s = spinnerdata(h,val)
%SPINNERDATA store/return stored value

if ~strcmp(get(h,'Type'),'figure')
    fig = ancestor(h,'figure');
else 
    fig = h;
end

if nargin == 1 && nargout == 1
    s = getappdata(fig,get_spinnerdata_name);
    if numel(s) > 1
        for n = 1:length(s)
            hndls = [s(n).edit;s(n).down;s(n).up];
            if any(h == hndls)
                s = s(n);
                return
            end
        end
    end    
elseif nargin == 2
    s = getappdata(fig,get_spinnerdata_name);
    if isempty(s)
        setappdata(fig,get_spinnerdata_name,val);
    else
        edit_windows = [s.edit];
        ind = find(val.edit == edit_windows);
        if isempty(ind)
            s(end+1) = val;
        else
            s(ind) = val;
        end
        setappdata(fig,get_spinnerdata_name,s);
    end
end


% ---------------------------------------------------------
function str = get_spinnerdata_name
%GET_SPINNERDATA_NAME return name used for appdata field

str = 'SpinnerAppData';