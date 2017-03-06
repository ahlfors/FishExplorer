
% fig2: simple visuals: sensory correlation, motor correlations
% plots a pair of regressors
% in a double colormap, and batch saves figures.

% compare to fig2A_correlation_1reg_with_hist for more details

clear all; close all; clc

%% Setup
% folder setup
saveFigFlag = 0;

outputDir = GetOutputDataDir;
saveDir = [];
saveDir{1} = fullfile(outputDir,'sensory&motor_0219','PT_LR_stimrangePT');
setDir(saveDir{1}); % make folder if doesn't exist
% saveDir{2} = fullfile(outputDir,'sensory&motor_0219','OMR_LR');
% setDir(saveDir{2}); % make folder if doesn't exist
saveDir{2} = fullfile(outputDir,'sensory&motor_0219','motor_LR_stimrangePT');
setDir(saveDir{2}); % make folder if doesn't exist

% params
M_stimmotorflag = [1,0]; % 1 for stim and 0 for motor
M_reg_range = {[8,9],[1,2]}; % [2,3] for phototaxis; left/right pairs
M_reg_thres = {0.5,0.5};
n_reg = length(M_reg_thres);

%% Init load
hfig = figure;
InitializeAppData(hfig);
ResetDisplayParams(hfig);

%% Load fish
range = 8;%GetFishRange;
for i_fish = range
    ClusterIDs = GetClusterIDs('all');
%     stimrange = 1;
    % [cIX,gIX,M] = LoadSingleFishDefault(i_fish,hfig,ClusterIDs,stimrange);
    [cIX,gIX,M,stim,behavior,M_0] = LoadSingleFishDefault(i_fish,hfig,ClusterIDs);
    
    %% Load stim/motor
    for i_set = 1:n_reg,
        reg_range = M_reg_range{i_set}; % left/right pair
        reg_thres = M_reg_thres{i_set};
        
        % get stim/motor regressors
        if M_stimmotorflag(i_set),
            fishset = getappdata(hfig,'fishset');
            [~,names,regressors] = GetStimRegressor(stim,fishset,i_fish);
        else
            isMotorseed = 0;
            setappdata(hfig,'isMotorseed',isMotorseed);
            [~,~,behavior] = UpdateTimeIndex(hfig);
            
            [~,names,regressors] = GetMotorRegressor(behavior,i_fish);
        end
        
        % code adapted from 'best regressor regression' code 'AllRegsRegression'
        Reg = regressors(reg_range,:);
        Corr = corr(Reg',M_0');
        [corr_max,IX_regtype] = max(Corr,[],1);
        cIX = find(corr_max>reg_thres)';
        gIX_offset = IX_regtype(cIX)';
        clrIX = MapXto1Dcolormap(corr_max(cIX),[reg_thres,1],64);
        gIX = clrIX+(gIX_offset-1)*64;
        numK = length(unique(gIX));
        
        %% make double colormap - ??
        clr1 = [1,0,0];
        clr2 = [0,1,1];
        numC = 64;
        clrmap1 = Make1DColormap([clr1*reg_thres*0.5;clr1],numC);
        clrmap2 = Make1DColormap([clr2*reg_thres*0.5;clr2],numC);
        clrmap = [clrmap1;clrmap2];
        
        %% make figure
        I = LoadCurrentFishForAnatPlot(hfig,cIX,gIX,clrmap);
        DrawCellsOnAnat(I);
        
        % add 2 colorbars
%         AddColorbarToAnat(clrmap,cmin,cmax)
%         colormap(clrmap1);
%         caxis([reg_thres,1])
%         colorbar('Location','manual','Position',[0.8,0.7,0.05,0.15],'Units','normalized')
        ax = axes('Position',[0.75,0.8,0.05,0.15],'Units','normalized');
        DrawCustomColorbar(clrmap1,[reg_thres,1],2,ax);
        
        ax = axes('Position',[0.9,0.8,0.05,0.15],'Units','normalized');
        DrawCustomColorbar(clrmap2,[reg_thres,1],2,ax);
        
        %% save figure
        savefolder = fullfile(saveDir{i_set},['regthres' num2str(reg_thres)]);
        figName = ['Fish' num2str(i_fish)];
        SaveFigureHelper(saveFigFlag, savefolder, figName);
        
    end
end