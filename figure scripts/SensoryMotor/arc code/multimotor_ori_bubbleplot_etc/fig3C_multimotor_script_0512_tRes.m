clear all; close all; clc

%% folder setup
saveFigFlag = 1;

outputDir = GetOutputDataDir;
saveDir0 = fullfile(outputDir,'multimotor_allcells_motorseed_newclr_0513');
if ~exist(saveDir0, 'dir'), mkdir(saveDir0), end;

%% init

hfig = figure;
InitializeAppData(hfig);
ResetDisplayParams(hfig);

setappdata(hfig,'isMotorseed',1);

% i_fish = 8;
% setappdata(hfig,'isMotorseed',0);

%% run fish
range_fish = GetFishRange;%[1:3,5:18];
% M_thres_reg = zeros(3,18);
% M_numTopCorr = zeros(1,18);
% M_motorseedRegs = cell(1,18);
% M_compareMotorCellNumber = zeros(2,18);

%% set params!
isCellbased = true;
stimflag = '2';

% ClusterIDs = [6,2];

% stimflag = []; % for default set
% ClusterIDs = [6,1];
M_stimrange = GetStimRange(stimflag);

range_fish_valid = [];
for i_fish = range_fish
    if ~isempty(M_stimrange{i_fish})
        range_fish_valid = [range_fish_valid,i_fish]; %#ok<AGROW>
    end
end

tscriptstart = tic;
IM_full = cell(4,18);
M_fishrange_im = {[1:3,5:18],[1:3,5:18],[1:3,5:18],[1:3,5:18]};
for i_fish = range_fish_valid
    disp(['i_fish = ',num2str(i_fish)]);
    
    %% load data for chosen stim range
    stimrange = M_stimrange{i_fish};
    ClusterIDs = [2,1]; % load all
    [cIX_load,gIX_load,M,stim,behavior,M_0] = LoadSingleFishDefault(i_fish,hfig,ClusterIDs);

    %% get motor-tRes
    [tAvr_bh,tRes_bh] = GetTrialAvrLongTrace(hfig,behavior);
    
    vAvr_bh = [var(tAvr_bh(1,:)),var(tAvr_bh(2,:))];        
    c1 = corr(tRes_bh(1,:)',behavior(1,:)');
    c2 = corr(tRes_bh(2,:)',behavior(2,:)');
    motorcorr_bh = [c1,c2];

    %% Method 2: stimAvr + motor regs
    setID = 2;
    
    if isCellbased
        gIX = (1:length(cIX_load))';
        Data = M;
        bottomDir = fullfile(saveDir0,'stimAvr - cell based');
    else % cluster based
        gIX = gIX_load;
        C = FindClustermeans(gIX,M);
        Data = C;
        bottomDir = fullfile(saveDir0,'stimAvr - cluster based');
    end

    %% stim / motor regression
    if false
        Corr = corr(reg_sens',M_0');
        [stimcorr,IX_regtype] = max(Corr,[],1);

        Corr = corr(reg_motor',M_0');
        [motorcorr,IX_regtype] = max(Corr,[],1);
    else
        % stim
        [M_tAvr,M_tRes] = GetTrialAvrLongTrace(hfig,M_0);
        stimcorr = var(M_tAvr,0,2);
        
        %% left
        %     stimcorr = corr(reg_sens(1,:)',M_0');
        
        % vRes = var(M_tRes,0,2);
        % vTot = var(M_,0,2);
        %     [stimcorr,IX_regtype] = max(Corr,[],1);
        
        %     Reg = regressors(reg_range,:);
        motorcorr = corr(tRes_bh(1,:)',M_0')';
        %     [motorcorr,IX_regtype] = max(Corr,[],1);
        % make figures
        [M_figs1,M_im] = MultiMotorVisuals(hfig,stimcorr,motorcorr,cIX_load,gIX,[1,5],setID,vAvr_bh(1),motorcorr_bh(1));
        %     f = combineFiguresLR([M_figs{:}]);
        IM_full{1,i_fish} = M_im{1};
        IM_full{2,i_fish} = M_im{2};
        %     close(M_figs{2});
        
        %% right
        %     stimcorr = corr(reg_sens(2,:)',M_0');
        %     [stimcorr,IX_regtype] = max(Corr,[],1);
        
        %     Reg = regressors(reg_range,:);
        motorcorr = corr(tRes_bh(2,:)',M_0')';
        %     [motorcorr,IX_regtype] = max(Corr,[],1);
        % make figures
        [M_figs2,M_im] = MultiMotorVisuals(hfig,stimcorr,motorcorr,cIX_load,gIX,[1,5],setID,vAvr_bh(2),motorcorr_bh(2));
        %     f = combineFiguresLR([M_figs{:}]);
        IM_full{3,i_fish} = M_im{1};
        IM_full{4,i_fish} = M_im{2};
        %     close(M_figs{2});
        
        %%
        f = combineFiguresLR([M_figs1{:},M_figs2{:}]);
        figName = ['Fish' num2str(i_fish)];
        SaveFigureHelper(saveFigFlag, bottomDir, figName,f);
    end
end
toc(tscriptstart)

%% save as tiff stack
n_reg = 4;
M_reg_name = {'SM2D_L_anat','SM2D_R_anat','SM2D_L','SM2D_R'};
for i_set = 1:n_reg
    range_im = M_fishrange_im{i_set};
    tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_allfish.tiff']);
    IM = IM_full(i_set,range_im);
    
    SaveImToTiffStack(IM,tiffdir);
end

%%
for i_set = [1,3];
    range_im = M_fishrange_im{i_set};%[1:3,5:7];%[1:3,5:18];
    cellarray = IM_full(i_set,range_im);
    
    % adjust params for visualization
    k_scale = 0.5;%1/1.5;%M_k_scale{i_set};
    k_contrast = 1;%M_k_contrast{i_set};
    
    [h_anat,im_avr] = AverageAnatPlot(cellarray,k_contrast,k_scale);
    
    tiffdir = fullfile(outputDir,[M_reg_name{i_set},'_avr.tiff']);
    imwrite(im_avr, tiffdir, 'compression','none','writemode','overwrite');
end

%% compare params
% % outputDir = GetOutputDataDir;
% % saveDir0 = fullfile(outputDir,'multimotor_0228');
%
% % topDir = fullfile(saveDir0,'stimregs - cell based');
% % bottomDir  = fullfile(saveDir0,'stimAvr - cell based');
%
% newDir = fullfile(saveDir0,'stimregs vs stimAvr (cell based, new cmap)');
%
% compareFoldersTB(topDir,bottomDir,newDir);

