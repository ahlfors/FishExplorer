% batch run full-clustering on all fish, sweep param with 2-fold CV

data_masterdir = GetCurrentDataDir();

% range_fish = [5,6,7];
% M_ClusGroup = [2,2,2,2];
% M_Cluster = [1,1,1,1];
range_fish = 8:9;
% M_ClusGroup = 2;
% M_Cluster = 3;
M_stim = 1;
% M_fish_set = [1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2];

%%
M_param = 5:5:100;%0.3:0.1:0.8;

Param_nClus = zeros(length(M_param),length(range_fish));
Param_CVscore = zeros(length(M_param),length(range_fish));
Param_CVscore_raw = cell(length(M_param),length(range_fish));

%     thres_split = M_param(k_param);
%     setappdata(hfig,'thres_split',thres_split);

for k_fish = 1:length(range_fish),
    i_fish = range_fish(k_fish);
    disp(i_fish);
    LoadFullFish(hfig,i_fish,0);
    absIX = getappdata(hfig,'absIX');
    
    %% partitions for CV
    timelists = getappdata(hfig,'timelists');
    timelists_names = getappdata(hfig,'timelists_names');
    periods = getappdata(hfig,'periods');
    if length(periods)>1,
        timelistsCV = cell(length(M_stim),2);
        
        k_stim = 1;
%         for k_stim = 1:length(M_stim),
        i_stim = M_stim(k_stim);
        TL = timelists{i_stim};
        period = periods(i_stim);
        nrep = size(TL,2)/periods(i_stim); % integer
        n = floor(nrep/2);
        timelistsCV{k_stim,1} = TL(1):TL(n*period);
        timelistsCV{k_stim,2} = TL(1+n*period):TL(2*n*period);
%           end
    end
    
    for k_param = 1:length(M_param),
        numK2 = M_param(k_param);
        
        Score = zeros(1,2);%(length(M_stim),2);
        %%
        NumClus = zeros(1,2);
        CIX = cell(1,2);
        GIX = cell(1,2);
        for k = 1:2, % CV halves
            i_ClusGroup = 2;
            i_Cluster = k+4;
            [cIX,gIX] = LoadCluster_Direct(i_fish,i_ClusGroup,i_Cluster,absIX);
            
            tIX = timelistsCV{k_stim,k};
            M_0 = GetTimeIndexedData_Default_Direct(hfig,[],tIX,'isAllCells');

            isWkmeans = 0;
            [cIX,gIX] = AutoClustering(cIX,gIX,absIX,i_fish,M_0,isWkmeans,numK2);

            NumClus(k) = length(unique(gIX));
            CIX{k} = cIX;
            GIX{k} = gIX;
        end
        % plot cell-matching figure
        Score(1) = HungarianCV(NumClus(1),NumClus(2),CIX{1},CIX{2},GIX{1},GIX{2});% true,timelists_names{i_stim});
        Score(2) = HungarianCV(NumClus(2),NumClus(1),CIX{2},CIX{1},GIX{2},GIX{1});% true,timelists_names{i_stim});
        Param_CVscore(k_param,k_fish) = mean(Score);
        Param_CVscore_raw{k_param,k_fish} = Score;
        
        nClus1 = length(unique(GIX{1}));
        nClus2 = length(unique(GIX{2}));
        Param_nClus(k_param,k_fish) = mean([nClus1,nClus2]);        

    end
end

%%
figure;
subplot(2,1,1)
plot(M_param*20,Param_nClus)
% legend('Fish8','Fish9');
xlabel('total k for kmeans')
ylabel('# of auto-clusters')
subplot(2,1,2)
plot(M_param*20,Param_CVscore)
ylim([0,1])
legend('Fish8','Fish9');
xlabel('total k for kmeans')
ylabel('CV (overlapping cell %)')