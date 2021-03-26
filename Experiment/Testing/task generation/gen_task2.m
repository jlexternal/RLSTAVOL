% script gen_task

% Note: Generates the UNP condition by modulating the MEAN
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

epis_struct         = gen_drift(cfg);
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

% f. simulate UNP episodes to determine MEAN value that matches difficulty to VOL
intval      = 0.001;
intinc      = 0.001;        % how much to increment the interval size by
isleveltwo  = false;        % whether to decrease interval size
ctr_inttwo  = 0;            % enumerations of interval 2nd levl processing    
intcand     = nan(1,10);    % candidate intervals for 2nd levl processing
acccand     = nan(1,10);    % abs(difference in VOL and UNP accuracies) for candidate intervals

while true
    
    % Generate candidate UNP trajectory
    
    % need to decrease the difference between REF mean and 0.5 by the interval
    epis_cand   = epis_struct.epis_ref;
    
    epis_cand(~epis_struct.sw_trs)  = epis_cand(~epis_struct.sw_trs)-intval;   % decrease mean towards .5
    epis_cand(epis_struct.sw_trs)   = epis_cand(epis_struct.sw_trs)+intval;    % increase mean towards .5
    
    if min(epis_cand(~epis_struct.sw_trs)) < .5 || max(epis_cand(epis_struct.sw_trs)) > .5
        fprintf('Means of the positive choice are below 0.5 and difficulty of UNP has not been matched to VOL!\n');
        error('Task logic broken.');
    end
    
    cfg.epis    = epis_cand;
    cfg.traj    = get_pr(epis_cand,vs);
    cfg.isvol   = false;
    cfg.vd      = 0;
    cfg.vs      = var(cfg.epis-cfg.traj); % effective sampling variance for KF
    
    % simulate KF on values of vs for the UNP condition
    sim_out_unp     = sim_KF(cfg);
    acc_sim_unp_KF  = mean(sim_out_unp.pt);
    
    fprintf('Trying... intval: %.4f, acc: %.4f\n',intval,acc_sim_unp_KF);
    
    % try 10 finer values when accuracy matched within 1% margin of error
    if isleveltwo
        ctr_inttwo              = ctr_inttwo + 1;
        intcand(ctr_inttwo+1)   = intval;
        acccand(ctr_inttwo+1)   = abs(acc_sim_unp_KF-acc_sim_vol_KF);
        if ctr_inttwo == 9
            break
        end
    end
    
    % if accuracy matched perfectly
    if acc_sim_unp_KF-acc_sim_vol_KF == 0 
        fprintf('Modulate mean by %d\n',intval);
        intcand = intval;
        break
    end
    
    % if accuracy matched within 1% margin of error
    if abs(acc_sim_unp_KF-acc_sim_vol_KF) < .01 && ~isleveltwo
        intcand(1) = intval;
        acccand(1) = abs(acc_sim_unp_KF-acc_sim_vol_KF);
        
        % decrease interval by 10%
        intval2 = 0.0001;
        disp('Decreasing interval size...\n')
        % UNP accuracy less than VOL
        if acc_sim_unp_KF-acc_sim_vol_KF < 0 
            int_away = true;    % interval away from .5
        % UNP accuracy higher than VOL
        else
            int_away = false;   % interval toward .5
        end
        isleveltwo = true;
    end
    
    % how much and in which direction to change the interval by
    if ~isleveltwo
        intval = intval + intinc;
    else
        if int_away
            intval = intval - intval2;
        else
            intval = intval + intval2;
        end
    end
end

% find the interval size that matches the desired difficulty level
[~,idx] = min(acccand);
fprintf('Matching interval decrease : %02f\n',intcand(idx))
intval = intcand(idx);

% calculate FNR of UNP condition
epis_pos_unp = epis_struct.epis_ref;
epis_pos_unp(epis_struct.sw_trs) = 1-epis_pos_unp(epis_struct.sw_trs);
epis_pos_unp = epis_pos_unp - intval;
traj_pos_unp = get_pr(epis_pos_unp,vs);
[a,b] = betapar(mean(traj_pos_unp),var(traj_pos_unp));
fnr_unp = betacdf(.5,a,b);
clearvars epis_pos_unp traj_pos_unp a b

%%
% g. choose 80 trials in total (5 episodes of lengths 8:4:24)
nepilen     = epis_struct.nepilen; 
nlens       = 8:4:24; 
nt_final    = sum(nlens);   % final trial length of any condition (i.e. 80)
nepis       = numel(nlens); % number of episodes for any condition (i.e. 5)
norder      = randsample(nepis,nepis); % randomize order of episode length

traj        = nan(3,nt_final); % final task sampled trajectory
epis        = nan(3,nt_final); % final task mean drift values
epiorder    = zeros(1,nepis);
epiend      = zeros(1,nepis);
epistart    = epis_struct.epistart;

% aggregate all the mean/static drifts 
epis_all        = nan(3,nt_all);
epis_all(1,:)   = epis_struct.epis_ref;
epis_all(2,:)   = epis_struct.epis_vol;
epis_all(3,~epis_struct.sw_trs) = epis_struct.epis_ref(~epis_struct.sw_trs)-intval;
epis_all(3,epis_struct.sw_trs)  = epis_struct.epis_ref(epis_struct.sw_trs)+intval;

% choose episodes satisfying criteria
for iepi = 1:nepis
    if iepi == 1
        epiorder(iepi) = 1;
    else
        epiorder(iepi) = epiorder(iepi-1)+nlens(norder(iepi-1));
    end
    epiend(iepi)   = epiorder(iepi)+ nlens(norder(iepi))-1;
    
    % find episode w/ indicated length and add to array
    ind         = nepilen == nlens(norder(iepi));
    epi_idx     = randsample(find(ind == 1),1); % choose random episode of desired length within the trajectory
    for icond = 1:3
        epis(icond,epiorder(iepi):epiend(iepi)) = epis_all(icond,epistart(epi_idx):epistart(epi_idx)+nlens(norder(iepi))-1);
    end
    
    % flip episodes if their means are not on the correct side of .5
    if mod(iepi,2) == 1 && epis(1,epiorder(iepi)) < .5
        epis(:,epiorder(iepi):epiend(iepi)) = 1-epis(:,epiorder(iepi):epiend(iepi));
    end
    if mod(iepi,2) == 0 && epis(1,epiorder(iepi)) > .5
        epis(:,epiorder(iepi):epiend(iepi)) = 1-epis(:,epiorder(iepi):epiend(iepi));
    end
    
    if iepi == 1
        epiorder(iepi) = 1;
    else
        epiorder(iepi) = epiorder(iepi-1)+nlens(norder(iepi-1));
    end
    epiend(iepi)   = epiorder(iepi)+ nlens(norder(iepi)) - 1;
    
end
epiend(end)= epiend(end);

% block sampling criteria based on satisfying FNR
traj_pos    = nan(size(traj));
tolval      = .01; % tolerance difference beteween desired and true FNR

for icond = [1 3]
    if icond == 1
        fnr_goal = fnr;
    else
        fnr_goal = fnr_unp;
    end
    
    loop_ctr = 1;
    while true
        traj(icond,:)       = get_pr(epis(icond,:),vs);
        traj_pos(icond,:)   = traj(icond,:);
        % calculate positive trajectory for fnr verification
        for iepi = 1:nepis
            if mod(iepi,2) == 0
                traj_pos(icond,epistart(iepi):epiend(iepi)) = 1-traj_pos(icond,epistart(iepi):epiend(iepi));
            end
        end
        % get fnr of sampled block
        [a,b]       = betapar(mean(traj_pos(icond,:)),var(traj_pos(icond,:)));
        fnr_smpl    = betacdf(.5,a,b);
        if abs(fnr_smpl - fnr_goal) <= tolval
            break
        end
        
        loop_ctr = loop_ctr + 1;
        % catch potential infinite loop cycle
        if loop_ctr > 10000
            disp('Loops is in it''s 10000th iteration... may be stuck...')
        end
    end
end
traj(2,:) = get_pr(epis(2,:),vs); % get VOL condition trajectory

% visualize task to determine feasibility for humans (and not KF)
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

%% visualize reward distribution
figure(2)
clf
title('Reward distributions (mean(UNP) < mean(REF))','FontSize',14)
hold on
for i = 1:3
    traj_pos = get_pr(epis_all(i,:),vs);
    % plot
    colors = get(gca,'ColorOrder');
    set(gca,'ColorOrderIndex',i);
    hfitBeta                        = histfit(traj_pos,30,'beta');
    hfitBeta(1).HandleVisibility    = 'off';
    hfitBeta(1).FaceAlpha           = 0.5;
    hfitBeta(1).EdgeAlpha           = 0;
    hfitBeta(2).Color               = colors(i,:);
    hfitBeta(2).LineStyle           = ':';
    hfitBeta(2).HandleVisibility    = 'off';
    
    xline(mean(traj_pos),'Color',colors(i,:),'LineWidth',3);
    legend({'REF','VOL','UNP'});
end
xline(.5,'LineStyle','--','HandleVisibility','off');
xlim([0 1]);



