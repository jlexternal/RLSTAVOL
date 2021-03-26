% script gen_task

% Note: Generates the UNP condition by modulating the VARIANCE

clc
close all
clear all

rngseed = 'shuffle';
% set global random number stream
rng = RandStream('mt19937ar','Seed',rngseed);
RandStream.setGlobalStream(rng);

% Generate episodes for VOL

% drift/static mean generation parameters
cfg             = struct;
cfg.ngen        = 2e3;      % number of episodes to be generated
cfg.nepis       = 1e3;      % number of episodes desired
cfg.epimin      = 8;        % minimum episode length
cfg.epimax      = 24;       % maximum episode length
cfg.avgmin      = 0.55;     % minimum average value allowed
cfg.avgmax      = 0.65;     % maximum average value allowed
cfg.var_drift   = 0.05^2;   % drifting variance
fnr             = .25;      % desired false negative rate for REF 

epis_struct     = gen_drift(cfg);

epis_avg_up         = epis_struct.epis_avg; % static episode values
idx_lo              = epis_avg_up < .5;     
epis_avg_up(idx_lo) = 1-epis_avg_up(idx_lo);% make them all on the same side
epis_avg_ref        = mean(epis_avg_up);    % take the average for spread calculation based on FNR

f_min               = @(sig)abs(fnr-normcdf(.5,epis_avg_ref,sig));
vs                  = (fminbnd(f_min,1e-5,1))^2; % sampling variance for REF

% d. generate trajectories for REF and VOL
nt_all      = numel(epis_struct.epis_vol); % number of trials in entire episode generation
traj_all    = nan(3,nt_all); % sampled trajectory for task (dim 1: REF, VOL, UNP)

get_pr = @(m,v)betasmp(m,v); % function to sample from beta distr. w/ mean m and variance v

% generate sampled trajectories for REF and VOL
traj_all(1,:) = get_pr(epis_struct.epis_ref,vs); % REF trajectory
traj_all(2,:) = get_pr(epis_struct.epis_vol,vs); % VOL trajectory

% input structure for KF simulation on VOL condition
cfg         = struct;
cfg.epis    = epis_struct.epis_vol;
cfg.traj    = traj_all(2,:);
cfg.isvol   = true;
cfg.vs      = var(epis_struct.epis_ref-traj_all(1,:)); % effective measurement uncertainty (vs) for REF
cfg.vd      = epis_struct.vd_eff;
cfg.epistart = epis_struct.epistart;

% e. simulate the VOL condition for KF accuracy
sim_out_vol     = sim_KF(cfg);
acc_sim_vol_KF  = mean(sim_out_vol.pt);

fprintf('\nVolatile condition KF accuracy: %02f\n\n',acc_sim_vol_KF)

% f. simulate UNP episodes to determine spread value that matches difficulty to VOL
intval = 0.001;
vs_arr = vs:intval:0.1;

for ivs = 1:numel(vs_arr)
    
    % generate candidate UNP trajectory
    vs          = vs_arr(ivs); % choose generative sampling variance
    cfg.epis    = epis_struct.epis_ref;
    cfg.traj    = get_pr(epis_struct.epis_ref,vs);
    cfg.isvol   = false;
    cfg.vd      = 0;
    
    cfg.vs      = var(cfg.epis-cfg.traj); % effective sampling variance for KF
    
    % simulate KF on values of vs for the UNP condition
    sim_out_unp     = sim_KF(cfg);
    acc_sim_unp_KF  = mean(sim_out_unp.pt);
    
    fprintf('Trying... vs: %2f, acc: %2f\n',vs,acc_sim_unp_KF);
    
    % if accuracy matched perfectly
    if acc_sim_unp_KF-acc_sim_vol_KF == 0 
        vs_unp = vs_arr(ivs);
        break
    end
    
    % if accuracy matched within 1% margin of error
    if abs(acc_sim_unp_KF-acc_sim_vol_KF) < .01
        
        % decrease interval by 10%
        intval = 0.0001;
        
        disp('Decreasing interval size...\n')
        
        % UNP accuracy less than VOL
        if acc_sim_unp_KF-acc_sim_vol_KF < 0 
            % reduce vs by intervals
            vs_arr2 = vs_arr(ivs)-(intval*10):intval:vs_arr(ivs);
            
            for ivs2 = 1:numel(vs_arr2)
                vs       = vs_arr2(ivs2); % choose generative sampling variance
                cfg.traj = get_pr(epis_struct.epis_ref,vs);
                cfg.vs   = var(cfg.epis-cfg.traj); % effective sampling variance for KF

                % simulate KF on values of vs for the UNP condition
                sim_out_unp             = sim_KF(cfg);
                acc_sim_unp_KF2(ivs2)  = mean(sim_out_unp.pt);
                fprintf('Trying... vs: %2f, acc: %2f\n',vs_arr2(ivs2),acc_sim_unp_KF2(ivs2));
            end
            
        % UNP accuracy higher than VOL
        else
            % increase vs by intervals
            vs_arr2 = vs_arr(ivs):intval:vs_arr(ivs)+(intval*10);
            
            for ivs2 = 1:numel(vs_arr2)
                vs       = vs_arr2(ivs2); % choose generative sampling variance
                cfg.traj = get_pr(epis_struct.epis_ref,vs);
                cfg.vs   = var(cfg.epis-cfg.traj); % effective sampling variance for KF

                % simulate KF on values of vs for the UNP condition
                sim_out_unp            = sim_KF(cfg);
                acc_sim_unp_KF2(ivs2)  = mean(sim_out_unp.pt);
                fprintf('Trying... vs: %2f, acc: %2f\n',vs_arr2(ivs2),acc_sim_unp_KF2(ivs2));
            end
        end
        
        break
    end
end

[~,idx] = min(abs(acc_sim_unp_KF2-acc_sim_unp_KF));
vs_unp = vs_arr2(idx);
% generate trajectory for UNP condition
traj_all(3,:) = get_pr(epis_struct.epis_ref,vs_unp);

% g. choose 80 trials in total (5 episodes of lengths 8:4:24)
nepilen     = epis_struct.nepilen; 
nlens       = 8:4:24; 
nt_final    = sum(nlens);   % final trial length of any condition (i.e. 80)
nepis       = numel(nlens); % number of episodes for any condition (i.e. 5)
norder      = randsample(nepis,nepis); % randomize order of episode length

traj        = nan(3,nt_final); % final task sampled trajectory
epis        = nan(3,nt_final); % final task mean trajectory
epiorder    = zeros(1,nepis);
epiend      = zeros(1,nepis);
epistart    = epis_struct.epistart;

% aggregate all the mean/static drifts 
epis_all        = nan(3,nt_all);
epis_all(1,:)   = epis_struct.epis_ref;
epis_all(2,:)   = epis_struct.epis_vol;
epis_all(3,:)   = epis_struct.epis_ref;

for iepi = 1:nepis
    if iepi == 1
        epiorder(iepi) = 1;
    else
        epiorder(iepi) = epiorder(iepi-1)+nlens(norder(iepi-1));
    end
    epiend(iepi)   = epiorder(iepi)+ nlens(norder(iepi));
    
    % find episode w/ indicated length and add to array
    ind         = nepilen == nlens(norder(iepi));
    epi_idx     = randsample(find(ind == 1),1); % choose random episode of desired length within the trajectory
    
    for icond = 1:3
        traj(icond,epiorder(iepi):epiend(iepi)-1) = traj_all(icond,epistart(epi_idx):epistart(epi_idx)+nlens(norder(iepi))-1);
        epis(icond,epiorder(iepi):epiend(iepi)-1) = epis_all(icond,epistart(epi_idx):epistart(epi_idx)+nlens(norder(iepi))-1);
    end
    
    % flip episodes if their means are not on the correct side of .5
    if mod(iepi,2) == 1 && epis(1,epiorder(iepi)) < .5
        traj(:,epiorder(iepi):epiend(iepi)-1) = 1-traj(:,epiorder(iepi):epiend(iepi)-1);
        epis(:,epiorder(iepi):epiend(iepi)-1) = 1-epis(:,epiorder(iepi):epiend(iepi)-1);
    end
    if mod(iepi,2) == 0 && epis(1,epiorder(iepi)) > .5
        traj(:,epiorder(iepi):epiend(iepi)-1) = 1-traj(:,epiorder(iepi):epiend(iepi)-1);
        epis(:,epiorder(iepi):epiend(iepi)-1) = 1-epis(:,epiorder(iepi):epiend(iepi)-1);
    end
    
    if iepi == 1
        epiorder(iepi) = 1;
    else
        epiorder(iepi) = epiorder(iepi-1)+nlens(norder(iepi-1));
    end
    epiend(iepi)   = epiorder(iepi)+ nlens(norder(iepi));
    
end
epiend(end)= epiend(end) - 1;


% episode selection constraints based on true sampling variance 

%% visualize reward distribution
figure(2)
clf
title('Reward distributions (vs(UNP) > vs(REF))','FontSize',14)
hold on
for i = 1:3
    % make all trajectories have means above .5
    traj_pos = traj_all(i,:);
    traj_pos(epis_struct.sw_trs) = 1-traj_pos(epis_struct.sw_trs);
    
    % plot
    colors = get(gca,'ColorOrder');
    set(gca,'ColorOrderIndex',i);
    hfitNorm = histfit(traj_pos,30);
    hfitNorm(1).HandleVisibility = 'off';
    hfitNorm(2).HandleVisibility = 'off';
    hfitNorm(1).FaceAlpha = .5;
    hfitNorm(1).EdgeAlpha = 0;
    hfitNorm(2).Color = colors(i,:);
    
    hfitBeta = histfit(traj_pos,30,'beta');
    hfitBeta(1).HandleVisibility = 'off';
    hfitBeta(1).FaceAlpha = 0;
    hfitBeta(1).EdgeAlpha = 0;
    hfitBeta(2).Color = colors(i,:);
    hfitBeta(2).LineStyle = ':';
    hfitBeta(2).HandleVisibility = 'off';
    
    xline(mean(traj_pos),'Color',colors(i,:),'LineWidth',3);
    legend({'REF','VOL','UNP'});
end
xline(.5,'LineStyle','--','HandleVisibility','off');
xlim([0 1]);

%% visualize task to determine feasibility for humans (and not KF)
if true
    condstr = {'REF','VOL','UNP'};
    figure(1)
    clf
    for i = 1:3
        subplot(1,3,i);
        hold on
        xlim([0 nt_final]);
        ylim([0 1]);
        plot(traj(i,:))
        scatter(1:nt_final,traj(i,:));
        plot(epis(i,:),'LineWidth',2);
        for iepi = 1:5
            xline(epiorder(iepi));
        end
        yline(.5,'--','LineWidth',2);
        title(condstr(i));
    end
end



