function all_layers = parseCsvExport(filename, num_layers)
%all_layers = parseCsvExport(filename, num_layers)
%This function reads in a specifically formatted CSV (obtained from ****
%[device name] produced by ***** [company name] and ouputs an appropriately
%formatted object for subsequent analysis.
%
% Function origionally written by Jonathan Oakley of Voxeleron
% (https://www.voxeleron.com/) on <31 July 2019>
%
% Function description written by Dan Bullock
% (https://github.com/DanNBullock/) on 22 Jan 2020

all_layers = [];

if ~exist('num_layers','var')
    num_layers = 8;
end

% We will figure these out from the first surface:
im_width = 0;
num_slices = 0;

layer_idx = 1;

fid = fopen(filename,'r');
tline = fgetl(fid);  % read line excluding newline character

while layer_idx<=num_layers && ischar(tline)
    % Output layer information:
    disp([num2str(layer_idx) ': Reading layer: ' tline]);
    surface = [];
    layer_count = 1;
    while true
        tline = fgetl(fid);
        if isletter(tline(1))
            break;
        end
        if ~ischar(tline)
            break;
        end
        % Parse this for values:
        tmp = regexp(tline,',','split');
        layer = zeros(length(tmp)-1,1);
        for i=1:length(tmp)-1
            layer(i) = str2num(tmp{i});
        end
        surface{layer_count} = layer;
        layer_count = layer_count + 1;
    end
    
    if ~ischar(tline) && isempty(surface)
        break;
    end
    
    if isempty(all_layers)
        num_slices = length(surface);
        im_width = size(layer,1);
        all_layers = zeros(im_width,num_slices,num_layers-1);
        for i=1:num_slices
            all_layers(:,i,layer_idx) = surface{i};
        end
    else
        for i=1:num_slices
            all_layers(:,i,layer_idx) = surface{i};
        end
    end
    
    layer_idx = layer_idx + 1;
end

fclose(fid);
disp(['Read ' num2str(layer_idx-1) ' layers']);
    
