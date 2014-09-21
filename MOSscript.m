% Prepares data for MOS evaluation, then runs the MOS function
%
% In each data location, "DAT_LOC", is a file 

clear all; close all;

%%% USER DEFINED - CHANGE THESE VARIABLES TO SUIT TEST

% Define test variation params (strings)
aName = 'testNo'; aVals = {'5' '7' '8' '9' '10'};
bName = 'Input.SNR'; bVals = {'00'};
cName = 'algorithm'; cVals = {'MMSE' 'IDBM' ...
    'phonemeMMSE' 'phonemeIDBM' ...
    'phonememohammadiaSupervised' 'phonememohammadiaOnline' ...
    'phonememodifiedSupervised' 'phonememodifiedOnline' ...
    'mohammadiaSupervised' 'mohammadiaOnline'};
dName = 'utterances/phns'; dVals = {'001' '005' '080' '100'};

% Set format such that this function will return the wav file to test
%enhanfile = @(a,b,c,d) sprintf( ...
%    '/Volumes/Gillman 1/Thesis/testdat/%s/enhanced/%s_%sut%sdB.wav', ...
%    a,c,d,b);
enhanfile1 = @(a,b,c,d) sprintf( ...
    '/users/ash/documents/thesisdata/testdat/%s/enhanced/%s_%sut%sdB.wav', ...
    a,c,d,b);
enhanfile2 = @(a,b,c,d) sprintf( ...
    '/users/ash/documents/thesisdata/testdat/%s/enhanced/%s_%sph%sdB.wav', ...
    a,c,d,b);
% Set format such that this function will return the unenhanced version of
% the sound
dirtyfile = @(a,b,c,d) sprintf( ...
    '/users/ash/documents/thesisdata/testdat/%s/test_dirty%sdB.wav', ...
    a,num2str(str2double(b)));
outcsv = '/users/ash/documents/thesisdata/testdat/MOSscores.csv';

% Tests to run
doMOS = true;
doMOSle = true;
doMOSlp = false;
doCCR = true;

%%% SCRIPT

% Form a matrix combining rows of all possible combinations of var params
[n,m,l,k] = ndgrid(1:length(aVals), 1:length(bVals), 1:length(cVals), ...
    1:length(dVals));
combs = [n(:) m(:) l(:) k(:)];

testLength = size(combs,1); % number of test points

fprintf('Test will run over %i test points\n',testLength)

TPs = cell(testLength,1);
count = 0;
for tp=1:testLength
    comb = combs(tp);
    a=aVals{combs(tp,1)}; b=bVals{combs(tp,2)};
    c=cVals{combs(tp,3)}; d=dVals{combs(tp,4)};
    
    % get files
    dirty = dirtyfile(a,b,c,d);
    if exist(enhanfile1(a,b,c,d),'file') ~= 0
        enhan = enhanfile1(a,b,c,d);
    elseif exist(enhanfile2(a,b,c,d),'file') ~= 0
        enhan = enhanfile2(a,b,c,d);
    else
        fprintf('error, cannot load for %s %s, %s %s, %s %s, %s %s\n', ...
            aName,a,bName,b,cName,c,dName,d);
        disp(enhanfile1(a,b,c,d))
        disp(enhanfile2(a,b,c,d))
        TP.skip=true;
        TP.a=a; TP.b=b; TP.c=c; TP.d=d;
        TPs{tp} = TP;
        continue
    end
    count = count + 1;
    TP.skip=false;
    
    % read files
    [dirtyWav,FS1] = wavread(dirty);
    [enhanWav,FS2] = wavread(enhan);
    
    if (FS1 ~= FS2)
        warning('Files have different sampling frequencies')
    end
    
    % Created Test Point structure
    TP.dirty = dirty;
    TP.enhan = enhan;
    TP.dirtyWav = dirtyWav;
    TP.enhanWav = enhanWav;
    TP.FS = FS1;
    TP.a=a; TP.b=b; TP.c=c; TP.d=d;
    TPs{tp} = TP;
end
fprintf(repmat('\n',1,5))
fprintf('loaded %i of %i\n',count,testLength);

% Start test
id = input('Welcome. Please enter your id given by examiner: ','s');
results = MOS(TPs,'doMOS',doMOS,'doMOSle',doMOSle,'doMOSlp',doMOSlp,'doCCR',doCCR);

% Save results to file. Appends, so that multiple users can be tested
needsHeader = ~exist(outcsv,'file');
fid = fopen(outcsv,'a+');
if needsHeader
    fprintf(fid,'ID,%s,%s,%s,%s,MOS,MOSle,MOSlp,CCR\n', ...
        aName,bName,cName,dName);
end
for i=1:testLength
    fprintf(fid,'%s,%s,%s,%s,%s,%i,%i,%i,%i\n', ...
        id,TPs{i}.a,TPs{i}.b,TPs{i}.c,TPs{i}.d, ...
        results{i}.MOS,results{i}.MOSle,results{i}.MOSlp,results{i}.CCR);
end
fclose(fid);