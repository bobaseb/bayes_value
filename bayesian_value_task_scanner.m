function DATA = bayesian_value_task()
% script for the experiment in:
% De Martino, B., Bobadilla-Suarez, S., Noguchi, T., Sharot, T., & Love, B. C. (2017). Social information is integrated into value and confidence judgments according to its reliability. Journal of Neuroscience, 37(25), 16066-6074.
% Loosely based on a script from Benedetto De Martino & Steve Fleming (thanks to both)
%
%requires the cogent package, visang.m (not my code), & the stimuli 

% The major output from this script is a multi-leveled structure called
% DATA.
%               Modified by Sebastian Bobadilla
close all;
clc;
clear all;

addpath(genpath(cd));
fprintf('Configuring Cogent and setting up experiment parameters...\n');
global cogent
%% Demographics

subNo = input('Participant number\n');

if mod(subNo,2) == 0
  scaleFlip = 2; %if subNo is even start with scale reversed on first two blocks
else
  scaleFlip = 1; %if subNo is odd start with normal scale on first two blocks
end 

DATA.params.scaleFlip = scaleFlip;
DATA.params.age = input('\nAge\n');
DATA.params.sex = input('\nGender (M or F)\n', 's');
sessionX = input('Which session, one or two?');


DATA.params.scrdist_mm = input('\nDistance from screen in mm\n'); %WE NEED TO MEASURE THIS

sure = input('Sure? Continue 0, Abort 1: ' );
if sure == 1
    disp('Check variables again! aborting...');
    clear all; return;  % abort experiment if initial inputs are wrong
elseif sure ==0
end

if size(DATA.params.scrdist_mm) == 0
    DATA.params.scrdist_mm = 750; %default to this distance if left blank
    fprintf('\n\nWARNING: defaulting to a distance of %1.2f cm\n', DATA.params.scrdist_mm/10);
    
end
wait(0.5);

DATA.params.scrwidth = 520; %screen width in mm? WE NEED TO MEASURE THIS
DATA.params.scrwidth_deg = visang(DATA.params.scrdist_mm, [], DATA.params.scrwidth); % horizontal screen dimension in degrees
%DATA.params.imdegsize = 8; %size of image in visual degrees
DATA.params.pixperdeg = 1600/DATA.params.scrwidth_deg; %assuming a resolution of 1280 pixels CHECK THIS!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% COGENT: CONFIGURATION
% display parameters
screenMode = 0;                 % 0 for small window, 1 for full screen, 2 for second screen if attached
screenRes = 4;                  % 6 = 1280 x 1024 resolution
white = [1 1 1];                % foreground colour
black = [0 0 0];                % background colour
fontName = 'Arial';         % font parameters
fontSize = 25;
number_of_buffers = 6;          % how many offscreen buffers to create
rand('seed',sum(100*clock));
% call config_... to set up cogent environment, before starting cogent
config_display(screenMode, screenRes, white, black, fontName, fontSize, number_of_buffers);   % open graphics window
%config_display(screenMode, screenRes, black, white, fontName, fontSize, number_of_buffers);   % open graphics window
config_keyboard;                % this enables collection of keyboard responses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_cogent;
preparestring('Welcome to the this experiment!',1,0,200);
preparestring('Your task is to indicate how much you like every product on a scale from 1 to 5',1,0,150);
preparestring('After each judgment please indicate how confident you are in your estimate',1,0,50);
%preparestring('1 = low confidence, 6 = high confidence',1,0,0);
preparestring('PRESS ANY KEY TO START',1,0,-150);
drawpict(1);
waitkeydown(inf);

% Store params
%DATA.params.pixperdeg = pixperdeg;
%DATA.params.scrwidth_deg = scrwidth_deg;
DATA.params.stimuli = 1:210;
%DATA.params.stimuliSub = 1:3;

if sessionX == 1
    DATA.times.rating = 216000;
    DATA.times.conf = 216000;
    DATA.times.description = 4002;
elseif sessionX == 2
    DATA.times.rating = 6960;
    DATA.times.conf = 4002;
end

DATA.times.confirm = 522;
DATA.times.fix = 522;

%scan params
DATA.scan.scanPort = 1;
DATA.scan.dummy = 5;
DATA.scan.nslice = 36;
DATA.scan.TR = 87; %TR in ms

% convert timings to scans
DATA.times.ratingScan = (DATA.times.rating/DATA.scan.TR); 
DATA.times.confScan = (DATA.times.conf/DATA.scan.TR);
DATA.times.confirmScan = (DATA.times.confirm/DATA.scan.TR);


% Run trials
stimFlip=[ones(1,105) ones(1,105).*2];
stimFlip = stimFlip(randperm(length(stimFlip)));
DATA.params.stimFlip = stimFlip;
nstim = length(DATA.params.stimuli);
trialList = (1:nstim)';
trialList(:,1) = trialList(randperm(length(trialList))',1);
trials = 50;
j = 1;

for block = 1:4
    if block == 4 %this makes the last block longer, changes from 50 to 60 trials
        DATA.times.fixScan = repmat([6 9 12 15 17],1,12);
        DATA.times.fixScan = DATA.times.fixScan(randperm(length(DATA.times.fixScan)));    
        trials = 52.5;
    else
        DATA.times.fixScan = repmat([6 9 12 15 17],1,10);
        DATA.times.fixScan = DATA.times.fixScan(randperm(length(DATA.times.fixScan)));
    end
    
    if  block >= 3 && scaleFlip == 1 %flips scale orientation on last two blocks
    scaleFlip = 2; 
    elseif block >= 3 && scaleFlip == 2
    scaleFlip = 1; 
    end 
    DATA.trialList = trialList(j:trials*block,:);
    [DATA.trialSlice, DATA.trialTime] = waitslice(DATA.scan.scanPort,DATA.scan.dummy*DATA.scan.nslice+1);
    DATA = runTrials(DATA,sessionX,scaleFlip,stimFlip);
    datafile = sprintf('BayesVal_sub%d_session%d_block%d', subNo, sessionX, block);
    save(datafile,'DATA');
    fprintf('Data saved in %s\n',datafile);
    j = (trials*block)+1;
end

stop_cogent;
return

function DATA = runTrials(DATA,sessionX,scaleFlip,stimFlip)
%% type II response screen
pixperdeg = DATA.params.pixperdeg;
imsize= pixperdeg*DATA.params.scrwidth_deg;
cgmakesprite(2,imsize,imsize,0,0,0);
fig_pos = [-5,-3,-1,1,3,5] * pixperdeg;
cgfont('Arial',25);
cgsetsprite(2)
cgtext('1',fig_pos(1),0);
cgtext('2',fig_pos(2),0);
cgtext('3',fig_pos(3),0);
cgtext('4',fig_pos(4),0);
cgtext('5',fig_pos(5),0);
cgtext('6',fig_pos(6),0);

trialList = DATA.trialList;
cwd = pwd;
for i = 1:length(trialList)
    try
    % Make confidence screen
    cgmakesprite(4,imsize,imsize,1,1,0);
    cgsetsprite(4)
    cgpenwid(pixperdeg*.1);
    cgpencol(1,1,1)
    cgdraw(-pixperdeg, -pixperdeg, pixperdeg, -pixperdeg);
    cgdraw(-pixperdeg, -pixperdeg, -pixperdeg, pixperdeg);
    cgdraw(-pixperdeg, pixperdeg, pixperdeg, pixperdeg);
    cgdraw(pixperdeg, pixperdeg, pixperdeg, -pixperdeg);
    cgtrncol(4,'y')
    cgpencol(1,1,1)
    
    % Load pics into buffers 3
    clearpict(3);
    cgpenwid(pixperdeg./20);
    
      if stimFlip(i) == 1
      loadpict([sprintf('%d_2a',DATA.params.stimuli(DATA.trialList(i,1))) '.jpg'],4,125,150,300,90);
      loadpict([sprintf('%d_3a',DATA.params.stimuli(DATA.trialList(i,1))) '.jpg'],4,125,-25,300,200);
      elseif stimFlip(i) == 2
      loadpict([sprintf('%d_2a',DATA.params.stimuli(DATA.trialList(i,1))) '.jpg'],4,-200,150,300,90);
      loadpict([sprintf('%d_3a',DATA.params.stimuli(DATA.trialList(i,1))) '.jpg'],4,-200,-25,300,200);
      end

    cgpenwid(pixperdeg*.1);
    if stimFlip(i) == 1
    loadpict([sprintf('%d_1a',DATA.params.stimuli(DATA.trialList(i,1))) '.jpg'],4,-250,0,300,300);
    elseif stimFlip(i) == 2
    loadpict([sprintf('%d_1a',DATA.params.stimuli(DATA.trialList(i,1))) '.jpg'],4,175,0,300,300);
    end
    
    %loadpict('92test.jpg',4,-275,-15,300,300); %tester
    cd(cwd);
    %% Display stimuli
    DATA.slice.fix(i) = DATA.trialSlice;
    DATA.timeScan.fix(i) = DATA.trialTime;
     
    cgsetsprite(0);
    clearkeys;
    cgfont('Arial',25);
    cgtext('+',0,0);
    cgflip(1,1,1);
    [DATA.slice.rating(i), DATA.timeScan.rating(i)] = waitslice(DATA.scan.scanPort, DATA.slice.fix(i) + DATA.times.fixScan(i));
    
    cgdrawsprite(3,0,100);
    cgflip(1,1,1);
    rateStart = time;
    %% PARAMETERS for VAS scale
    VASwidth=1000;
    VASheight=400;
    arrowwidth=20;
    arrowheight=20;
    scaleStep = 4;%was 2
    xpos = (rand*120*1.6)-(100*0.8);
    DATA.xpos(i) = xpos;
    %xpos = 0;               %starting x pos of arrow
    ypos_bdm = -200;        %starting y pos of arrow
    ypos = 0;
    
    keymap=getkeymap;
    confirmkey=keymap.Space;
    rightkey=keymap.Right;
    leftkey=keymap.Left;
    
    cgmakesprite (5, VASwidth, VASheight, 1, 1, 1);    %make white ratesprite%%
    cgsetsprite (5);                        %ready sprite to draw into
    cgalign ('c', 'c');                     %center alignment
    cgpencol (0, 0, 0);                     %black on white background%%
    cgrect (0, 0, 800, 4);                  %draw horizontal line
    cgrect (-400, 0, 4, 15);                %draw left major tick
    cgrect (400, 0, 4, 15);                 %draw right major tick
    for tick = 1:6
        cgrect (160* (tick - 3.5), 0, 2, 15);  %draw minor ticks
    end;
    
    %make yellow stars
    if scaleFlip == 1
        loadpict('starsForScale.jpg',5,0,30,800,30);
    elseif scaleFlip == 2
        loadpict('starsForScaleFlipped.jpg',5,0,30,800,30);
    end
    %      starwidth=30;
    %      starheight=30;
    %      loadpict('star.jpg',5,-320,30,starwidth,starheight);%1 star
    %      loadpict('star.jpg',5,-160-(starwidth/2),30,starwidth,starheight); loadpict('star.jpg',5,-160+(starwidth/2),30,starwidth,starheight); %2 stars
    %      loadpict('star.jpg',5,0-starwidth,30,starwidth,starheight); loadpict('star.jpg',5,0,30,starwidth,starheight); loadpict('star.jpg',5,0+starwidth,30,starwidth,starheight);%3 stars
    %      loadpict('star.jpg',5,160-(starwidth*1.5),30,starwidth,starheight); loadpict('star.jpg',5,160-(starwidth/2),30,starwidth,starheight); %4 stars (first 2)
    %      loadpict('star.jpg',5,160+(starwidth/2),30,starwidth,starheight); loadpict('star.jpg',5,160+(starwidth*1.5),30,starwidth,starheight); %4 stars (second 2)
    %      loadpict('star.jpg',5,320-(starwidth*2),30,starwidth,starheight); loadpict('star.jpg',5,320-(starwidth),30,starwidth,starheight); loadpict('star.jpg',5,320,30,starwidth,starheight); %5 stars (first 3)
    %      loadpict('star.jpg',5,320+(starwidth),30,starwidth,starheight); loadpict('star.jpg',5,320+(starwidth*2),30,starwidth,starheight); %5 stars (last 2)
    
    cgfont('Arial',25);
    cgmakesprite (6, arrowwidth, arrowheight, 1, 1, 1);               %make arrowsprite%
    cgsetsprite (6);
    cgpencol (0, 0, 0);                     %black arrow%
    cgpolygon ([-0.5 0 0.5]*arrowwidth, [-0.5 0.5 -0.5].*arrowheight);
    
    %Make red arrowsprite
    cgmakesprite (9, arrowwidth, arrowheight, 1, 1, 1);               %make red arrowsprite
    cgsetsprite (9);
    cgpencol (1, 0, 0);                     %red arrow%% (1, 0, 0) is red color
    cgpolygon ([-0.5 0 0.5]*arrowwidth, [-0.5 0.5 -0.5].*arrowheight);
    cgmakesprite (7, VASwidth, VASheight, 1, 1, 1);    %make black full ratesprite for later use
    cgpencol (0, 0, 0); %change pen color back into white
    key.down.ID = 0;
    key.direction = 0;
    clearkeys;
    key.down.ID = 0;
    
    
    while (time-rateStart) <= DATA.times.rating
        cgfont('Arial',35);
        cgsetsprite (7);                % ready whole ratingsprite to draw into
        cgdrawsprite (5, 0, 0);         % draw ratingscale
        cgdrawsprite (6, xpos, -12);    % draw ratingarrow
        cgtext ('Product Rating', 0, 125);  %loadpict('star.png',5,-250,50,50,50);            %write anchors ******same anchors or new ones???***********************
        cgsetsprite (0);
        cgdrawsprite(4,0,100);          % Draw product again
        cgdrawsprite (7, 0, ypos_bdm, VASwidth*0.7, VASheight*0.7);     % draw ratingsprite onto offscreen
        cgflip (1,1,1);            % show offscreen (black background)
        readkeys;
        [key.down.ID, key.down.time] = lastkeydown;
        [key.up.ID, key.up.time] = lastkeyup;
        if key.down.ID == key.up.ID     % was key pressed & released?
            if key.down.ID == rightkey
                key.direction = 0;      % then define direction as zero
                xpos = xpos + scaleStep;         % go one step into direction of keypress
                if xpos > 400
                    xpos = 400;
                end;
            elseif key.down.ID == leftkey
                key.direction = 0;
                xpos = xpos - scaleStep;
                if xpos < -400
                    xpos = -400;
                end;
            end;
        elseif key.down.ID == rightkey  % if key is pressed and held then define direction
            key.direction = scaleStep;
        elseif key.down.ID == leftkey
            key.direction = -scaleStep;
        elseif (key.up.ID == rightkey) | (key.up.ID == leftkey) % if key is released only - then stop movement
            key.direction = 0;
        end;
        
        xpos = xpos + key.direction;        % update xpos
        if xpos > 400
            xpos = 400;
        elseif xpos < -400
            xpos = -400;
        end;
        clearkeys;
        
        if sessionX == 1
        if key.down.ID == confirmkey
            break
        end
        end
    end;
    
    % Show confirmation arrow
    
    cgsetsprite (7);                % ready whole ratingsprite to draw into
    cgdrawsprite (5, 0, 0);         % draw ratingscale
    cgdrawsprite (9, xpos, -12);    % draw ratingarrow
    cgtext ('Product Rating', 0, 125);
    cgsetsprite (0);
    cgdrawsprite(4,0,100);          % Draw food again
    cgdrawsprite (7, 0, ypos_bdm, VASwidth*0.7, VASheight*0.7);     % draw ratingsprite onto offscreen
    cgflip (1,1,1);
    
    rateEnd = time;
    [DATA.slice.confidence(i), DATA.timeScan.confidence(i)] = waitslice(DATA.scan.scanPort, DATA.slice.rating(i) + DATA.times.ratingScan + DATA.times.confirmScan);

    %DATA.rating(i) = xpos;
    if scaleFlip == 1
        DATA.rating(i) = 5/8.*(xpos+400);
        DATA.xpos(i) = 5/8.*(DATA.xpos(i)+400);
    elseif scaleFlip == 2
        DATA.rating(i) = -5/8*(xpos-400);
        DATA.xpos(i) = -5/8*(DATA.xpos(i)-400);
    end
    DATA.ratingTime(i) = rateEnd-rateStart;
    xpos = 0;   % reset xpos
    %% Rate confidence
    %%% response to confidence task
    %DATA.times.conf = 6000;
    bg = 1;
    
    cgmakesprite (16, VASwidth, VASheight, bg, bg, bg);    %make white ratesprite
    cgsetsprite (16);                        %ready sprite to draw into
    cgalign ('c', 'c');                     %center alignment
    cgpencol (0, 0, 0);                     %white on grey background
    cgrect (0, 0, 500, 4);                  %draw horizontal line
    cgrect (-250, 0, 4, 15);                %draw left major tick
    cgrect (250, 0, 4, 15);                 %draw right major tick
    tickMark = [-150 -50 50 150];
    for tick = 1:4
        cgrect (tickMark(tick), 0, 2, 15);  %draw minor ticks
    end;
    
    cgmakesprite (17, arrowwidth, arrowheight, bg, bg, bg);               %make white arrowsprite
    cgsetsprite (17);
    cgpencol (0, 0, 0);                     %black arrow
    cgpolygon ([-0.5 0 0.5]*arrowwidth, [-0.5 0.5 -0.5].*arrowheight);
    cgmakesprite (19, arrowwidth, arrowheight, bg, bg, bg);               %make red arrowsprite
    cgsetsprite (19);
    cgpencol (1, 0, 0);                     %black arrow%% (1, 0, 0) is red color
    cgpolygon ([-0.5 0 0.5]*arrowwidth, [-0.5 0.5 -0.5].*arrowheight);
    cgmakesprite (18, VASwidth, VASheight, bg, bg, bg);    %make big ratesprite for later use
    cgfont('Arial',25);
    cgpencol(0,0,0);
    %% Get confidence using VAS scale
    rateStart = time;
    % Start xpos at the centre
    xpos = (rand*120)-60;
    DATA.xpos_conf(i) = xpos;
    key.down.ID = 0;
    key.direction = 0;
    clearkeys;
    key.down.ID = 0;
    numPress = 0;   % count presses
    while (time-rateStart) <= DATA.times.conf
        cgsetsprite (18);                % ready whole ratingsprite to draw into
        cgdrawsprite (16, 0, 0);         % draw ratingscale
        cgdrawsprite (17, xpos, ypos-12);    % draw ratingarrow
        cgfont('Arial',25);
        if scaleFlip == 1
            cgtext ('Lower', -320, -35);                %write anchors
            cgtext ('Higher', 320, -35);
        elseif scaleFlip == 2
            cgtext ('Higher', -320, -35);                %write anchors
            cgtext ('Lower', 320, -35);
        end
        cgfont('Arial',35);
        cgtext('Confidence Rating', 0, 125);
        cgfont('Arial',25);
        cgsetsprite (0);
        cgdrawsprite (18, 0, ypos, VASwidth*0.7, VASheight*0.7);     % draw ratingsprite onto offscreen
        cgflip (bg,bg,bg);            % show offscreen (black background)
        readkeys;
        [key.down.ID, key.down.time] = lastkeydown;
        [key.up.ID, key.up.time] = lastkeyup;
        if key.down.ID == key.up.ID     % was key pressed & released?
            if key.down.ID == rightkey
                key.direction = 0;      % then define direction as zero
                xpos = xpos + 2;         % go one step into direction of keypress
                if xpos > 250
                    xpos = 250;
                end;
            elseif key.down.ID == leftkey
                key.direction = 0;
                xpos = xpos - 2;
                if xpos < -250
                    xpos = -250;
                end;
            end;
        elseif key.down.ID == rightkey  % if key is pressed and held then define direction
            key.direction = 3;
        elseif key.down.ID == leftkey
            key.direction = -3;
        elseif (key.up.ID == rightkey) | (key.up.ID == leftkey) % if key is released only - then stop movement
            numPress = numPress+1;
            key.direction = 0;
        end;
        
        xpos = xpos + key.direction;        % update xpos
        if xpos > 250
            xpos = 250;
        elseif xpos < -250
            xpos = -250;
        end;
        clearkeys;
        
        if sessionX == 1
        if key.down.ID == confirmkey
            break
        end
        end
    end;
    rateEnd = time;
    if scaleFlip == 1
        DATA.xpos_conf(i) = DATA.xpos_conf(i)+250;
        con = xpos+250;
    elseif scaleFlip == 2
        DATA.xpos_conf(i) = -(DATA.xpos_conf(i)-250);
        con = -(xpos-250);
    end
    t2 = rateEnd-rateStart;
    
    % Show confirmation arrow
    cgsetsprite (18);                % ready whole ratingsprite to draw into
    cgdrawsprite (16, 0, 0);         % draw ratingscale
    cgdrawsprite (19, xpos, ypos-12);    % draw red rating arrow
    cgfont('Arial',25);
    if scaleFlip == 1
        cgtext ('Lower', -320, -35);                %write anchors
        cgtext ('Higher', 320, -35);
    elseif scaleFlip == 2
        cgtext ('Higher', -320, -35);                %write anchors
        cgtext ('Lower', 320, -35);
    end
    cgfont('Arial',35);
    cgtext('Confidence Rating', 0, 125);
    cgfont('Arial',25);
    cgsetsprite (0);
    cgdrawsprite (18, 0, ypos, VASwidth*0.7, VASheight*0.7);     % draw ratingsprite onto offscreen
    cgflip (bg,bg,bg);            % show offscreen (background)
    [DATA.slice.end(i), DATA.timeScan.end(i)] = (DATA.scan.scanPort, DATA.slice.confidence(i) +  DATA.times.confScan +DATA.times.confirmScan);

    DATA.responses.typeII.con(i) = con;
    DATA.responses.typeII.press(i) = numPress;
    if ~isempty(t2)
        DATA.responses.typeII.RT(i)= t2(1);
    else
        DATA.responses.typeII.RT(i)= NaN;
    end
    
    catch ME
    break
    end

     DATA.trialSlice = DATA.slice.end(i);
     DATA.trialTime = DATA.timeScan.end(i);
    
end
clearpict(1);
preparestring('End of block. Please take a break.',1,0,0);
preparestring('Press any key to continue.',1,0,-100);
drawpict(1);
% Wait for keypress before continuing
waitkeydown(inf);
clearpict
clearpict(1);
