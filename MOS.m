function [results,testParams] = MOS(testParams,varargin)
% MOS Perform a Mean Opinion Score, ITU P.800 [1] Annex B and Annex E
% 
% It is up to the user to ensure recording are in line line with B.1. This
% test aligns with the experimental design in B.3
% It is recommended that listeners use professional quality over-ear
% headphones (without internal filtering or effects), unless experimental
% design dictates otherwise (e.g. for conditions to match the use case).
p = inputParser;
p.addParamValue('doMOS',true);
p.addParamValue('doMOSle',false);
p.addParamValue('doMOSlp',false);
p.addParamValue('doCCR',false);
p.addParamValue('MOSscale',{'Excellent','Good','Fair','Poor','Bad'});
p.addParamValue('MOSlescale',{ ...
    'Complete relaxation possible; no effort required', ...
    'Attention necessary; no appreciable effort required', ...
    'Moderate effort required', ...
    'Considerable effort required', ...
    'No meaning understood with any feasible effort'});
p.addParamValue('MOSlpscale',{'Much louder than preferred', ...
    'Louder than preferred', ...
    'Preferred', ...
    'Quieter than preferred', ...
    'Much quieter than preferred'});
p.addParamValue('CCRscale',{ ...
    'Much Better', ...
    'Better', ...
    'Slightly Better', ...
    'About the Same', ...
    'Slightly Worse', ...
    'Worse', ...
    'Much Worse'});
p.parse(varargin{:});
doMOS = p.Results.doMOS;
doMOSle = p.Results.doMOSle;
doMOSlp = p.Results.doMOSlp;
doCCR = p.Results.doCCR;
MOSscale = p.Results.MOSscale;
MOSlescale  = p.Results.MOSlescale;
MOSlpscale = p.Results.MOSlpscale;
CCRscale = p.Results.CCRscale;

% B.3 recommends session length limited to 20 mins, absolute maximum 45mins
numTests = length(testParams);
% calc runtime
runMins = 0;
for tp=1:numTests
    TP = testParams{tp};
    if TP.skip
        continue
    end
    % estimate at listen to 10s per recording
    % MOS time
    runMins = runMins + 10 / 60;
    % CCR extra time
    if doCCR
        runMins = runMins + 10 / 60;
    end
end
if runMins > 45
    warning('Estimated runtime over critical recommended 45 mins');
    pause(2);
elseif runMins > 20
    warning('Estimated runtime over recommended 20 mins');
    pause(2);
end

% Shuffle, in alignment with [1] B.3
order = randperm(numTests);
fprintf('%i, ',order); % print the order in case of error you can manually get results back
fprintf('\n^^You can ignore these numbers.^^');
testParams = testParams(order);
results = cell(size(testParams,1),1);

% Begin Test
pause(1);
fprintf(repmat('\n',1,10))
fprintf('Est. runtime: %f mins\n',runMins);
fprintf('About to start test the test\n');
fprintf('Simply listen to the recording and answer the questions\n');
fprintf('To hear any recording again, simply press enter without typing a response\n');
fprintf('Press Enter to Begin\n');
pause

% milestones and jokes
milestones = [0.25 0.33 0.5 0.67 0.9];
milestonemsgs = {'You''re a quarter way there already!'...
    'That''s a third down.' 'Half down, half to go.' 'Getting Close!'...
    '90%% through, you''re nearly there'};
milestoneflgs = [0 0 0 0 0];
jokes = {'What''s the opposite of understand? Derstand?'...
    'Better to understand a little than to misunderstand a lot.'...
    '''One of the best hearing aids a man can have is an attentive wife.'' - GrouchoMarx'...
    'Dark humor is like food, some people dont have any'...
    'Words cannot express how limited my vocabulary is.'...
    'I''m not addicted to brake fluid, I can stop any time'...
    'War does not determine who is right - only who is left.'...
    'If 4 out of 5 people SUFFER from diarrhea... does that mean that one enjoys it?'...
    'A computer once beat me at chess, but it was no match for me at kick boxing.'...
    'The sole purpose of a child''s middle name, is so he can tell when he''s really in trouble.'...
    '- What did the buffalo say to his son as he left for college?\n    - Bison'...
    '- What do you call an alligator in a vast?\n- An investigator.'...
    'Algebra, stop asking us to find your x. She''s not coming back, so don''t ask y'...
    'I changed my iPod''s name to Titanic. It''s syncing now.'...
    'Jokes about German sausage are the wurst.'...
    'They told me I had type-A blood, but it was a Type-O.'...
    'Did you hear about the cross-eyed teacher?\n    She lost her job because she couldn?t control her pupils'};
times = zeros(size(testParams));
try
    for tp=1:numTests
        tic;
        TP = testParams{tp};
        progress = tp/numTests;

        % Progress Report
        fprintf('\n\n%i of %i (%.1f%%) at %s\n',tp,numTests,progress*100, ...
            datestr(sum(times)/3600/24,'MM:SS'));
        % Motivating message if reached milestone
        milestone = find(progress>=milestones,1,'last');
        if ~milestoneflgs(milestone)
            cprintf('comment',[milestonemsgs{milestone} '\n\n']);
            milestoneflgs(milestone) = true;
        end

        % skip if couldn't load the waveform
        if TP.skip
            result.CCR = '-';
            result.MOS = '-';
            result.MOSle = '-';
            result.MOSlp = '-';
            results{tp} = result;
            fprintf('You don''t have to do this test :)\n');
            continue
        end

        % start wavform a random position before 10s from end
        if length(TP.enhanWav) > 10*TP.FS
            startPos = randi(length(TP.enhanWav) - 10*TP.FS,1);
        else
            startPos = 1;
        end

        % normalise avg. power of waveform
        enhanWav = TP.enhanWav/rms(TP.enhanWav) * 0.1;
        if sum(abs(enhanWav/rms(enhanWav)*0.1)>1)/length(enhanWav) > 0.01
            warning('More than 1% clipping!');
        end
        enhanAP = audioplayer(enhanWav(startPos:end),TP.FS);
        if doCCR
            % normalise avg. power of waveform
            dirtyWav = TP.dirtyWav/rms(TP.dirtyWav) * 0.1;
            if sum(abs(dirtyWav/rms(dirtyWav)*0.1)>1)/length(dirtyWav) ...
                > 0.01
                warning('More than 1% clipping!');
            end
            disp('Rate the improvement from the unenhanced to the enhanced sound.');
            dirtyAP = audioplayer(dirtyWav(startPos:end),TP.FS);
            CCR = NaN;
            while ~any(CCR == -3:3)
                play(dirtyAP);
                fprintf('Playing the unenhanced waveform (Enter to continue)...\n')
                pause;
                stop(dirtyAP);
                play(enhanAP);
                fprintf('Playing the enhanced waveform...\n');
                fprintf('Rate the quality of the second compared to the quality of the first\n')
                for i=3:-1:-3
                    fprintf('%2i: %s\n',i,CCRscale{4-i});
                end
                CCR = str2double(input('>','s'));
                if ~any(CCR == -3:3)
                    stop(enhanAP);
                end
            end
            result.CCR = CCR;
        else
            result.CCR = '-';
        end
        if doMOS
            disp('Rate the quality of the speech.')
            result.MOS = doTest(MOSscale,enhanAP);
        else
            result.MOS = '-';
        end
        if doMOSle
            disp('Rate the Effort required to understand the meanings of sentences.')
            result.MOSle = doTest(MOSlescale,enhanAP);
        else
            result.MOSle = '-';
        end
        if doMOSlp
            disp('Rate the volume for this sound.')
            result.MOSlp = doTest(MOSlpscale,enhanAP);
        else
            result.MOSlp = '-';
        end
        results{tp} = result;

        % Entertainment to keep subject from frustration
        if randi(5,1)==1
            cprintf('k',['   ' jokes{randi(numel(jokes),1)} '\n']);
        end
        times(tp) = toc;
    end
    fprintf('Test complete, you did it!\n');
    cprintf('comment','Thank you very much\n');
catch err
    error('An error occurred, attempting to save results');
end

% Unshuffle
testParams(order) = testParams;
results(order) = results;
end

function score = doTest(scale,ap)
% Do MOS test
%   scale: scale values (cell string array)
%   ap: audioplayer with recording loaded
%   returns score, user input
score = NaN;
while ~any(score == 1:5)
    if ~isplaying(ap)
        play(ap)
        fprintf('Playing the waveform...\n')
    end
    for i=5:-1:1
        fprintf('%2i: %s\n',i,scale{6-i});
    end
    score = str2double(input('>','s'));
end
end