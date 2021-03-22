% Calculate task difficulty for VOL condition based on KF measures

clear all
close all
clc

% episode generation parameters
ngen        = 2e3;  % number of episodes to be generated
nepis       = 1e3;  % number of episodes desired
epimin      = 8;    % minimum episode length
epimax      = 24;   % maximum episode length
avgmin      = 0.55;
avgmax      = 0.75;

% variance parameters
var_drift   = 0.05^2;
var_smpl    = 0.1^2;

rngseed = 'shuffle';

% set global random number stream
rng = RandStream('mt19937ar','Seed',rngseed);
RandStream.setGlobalStream(rng);

% set task generation random number stream
rng_tsk = RandStream('mt19937ar','Seed',rngseed);

% FIRST STEP OF TASK GENERATION
fprintf('generating episodes\n');

get_pr = @(m,v)betasmp(m,v); % sample from beta distr. w/ mean m and variance v

pr_all = cell(ngen,1);
pr = zeros(1,epimax+2);

while true 
    % Generate mean-drift episodes
    for i = 1:ngen
        if mod(i,100) == 0
            fprintf('Generating %d of %d episodes...\n',i,ngen);
        end

        while true
            pr(:) = 0;
            pr(1) = get_pr(0.5,var_drift);

            % initialize episode value
            if pr(1) < 0.5
                pr(1) = 1-pr(1);
            end
            % create random walk from initial value
            for j = 2:epimax+2
                pr(j) = get_pr(pr(j-1),var_drift);
                if pr(j) < 0.5
                    break
                end
            end

            epilen = j-1;
            epiavg = mean(pr(1:j-1));
            if epilen >= epimin && ...          % episode length is at least at minimum length
               epilen <= epimax && ...          % episode length is at most at maximum length
               epiavg >= avgmin && ...          % average value is at least at minimum value
               epiavg <= avgmax && ...          % average value is at most at maximum value
               max(pr(1:j-1)) <= 0.90 && ...    % max value within episode does not exceed preset max
               max(abs(diff(pr(1:j)))) <= 0.10  % trial to trial differences are not overly great
                break
            end
        end
        pr_all{i} = pr(1:j-1);
    end

    % Filter through episodes whose median lies within some range
    xavg = cellfun(@median,pr_all);
    i = xavg >= 0.55 & xavg <= 0.65;
    pr_all = pr_all(i);
    
    % get desired number of episodes
    if numel(pr_all) > 1000
        pr_all = pr_all(1:1000);
        break
    else
        disp('1000 episodes within criteria not found. Running episode generation...\n');
    end
end
pr_all_vec      = horzcat(pr_all{:});

% Identify start/switch points 
nepilen     = cellfun(@numel,pr_all);
epistart    = nan(1,nepis);
epistart(1) = 1;
for i = 2:nepis
    epistart(i) = epistart(i-1)+nepilen(i-1);
end

epis        = pr_all_vec;
epis_vol    = epis;
epis_ref    = nan(1,nepis);

epis_avg    = nan(1,nepis); % average value of episode 
% invert values at switch points
for i = 1:nepis
    epis_avg(i) = mean(epis_vol(epistart(i):(epistart(i)+nepilen(i)-1)));
    
    % invert values for VOL condition
    if mod(i,2) == 0
        epis_vol(epistart(i):(epistart(i)+nepilen(i)-1)) = 1-epis_vol(epistart(i):(epistart(i)+nepilen(i)-1));
        epis_avg(i) = 1-epis_avg(i);
    end
    
    % create mean "drift" for the REF condition
    epis_ref(epistart(i):(epistart(i)+nepilen(i)-1)) = epis_avg(i);
end

% Get drifting variance
var_drift_ef = var(epis_vol(2:end)-epis_vol(1:end-1));
fprintf('True drift variance: %.4f\nEffective drift variance: %.4f\n',var_drift,var_drift_ef);

% Create latent trajectory for VOL condition
traj_vol = get_pr(epis_vol,var_smpl);
traj_ref = get_pr(epis_ref,var_smpl);

%%
% Kalman Filter for difficulty estimation
nt = numel(traj_vol);

% static parameters
vs_vol = var(epis_vol-traj_vol);
vd_vol = var_drift_ef;

vs_ref = var(epis_ref-traj_ref);
vd_ref = 0; % no drift for REF condition

% allocate variables
kt_vol = nan(1,nt); % kalman gain
vt_vol = nan(1,nt); % posterior variance
mt_vol = nan(1,nt); % estimated mean
rt_vol = nan(1,nt); % KF responses
pt_vol = nan(1,nt); % probability of correct KF responses (argmax)

kt_ref = nan(1,nt); % kalman gain
vt_ref = nan(1,nt); % posterior variance
mt_ref = nan(1,nt); % estimated mean
rt_ref = nan(1,nt); % KF responses
pt_ref = nan(1,nt); % probability of correct KF responses (argmax)

resp_up = false; % whether response is above .5 or below
iepi = 0;
% filter
for it = 1:nt
    if ismember(it,epistart)
        resp_up = ~resp_up;
        
        iepi = iepi + 1;
        % reset initial values for REF condition
        mt_ref(it) = mean(traj_ref);
        vt_ref(it) = var(traj_ref);
        kt_ref(it) = 1;
    else
        mt_ref(it) = mt_ref(it-1);
        vt_ref(it) = vt_ref(it-1);
        kt_ref(it) = kt_ref(it-1);
    end
    
    if it == 1
        mt_vol(1) = mean(traj_vol); % mean of latent trajectory
        vt_vol(1) = var(traj_vol);  % variance of latent trajectory
        kt_vol(1) = 1;
    else
        mt_vol(it) = mt_vol(it-1);
        vt_vol(it) = vt_vol(it-1);
        kt_vol(it) = kt_vol(it-1);
    end
    
    % get responses and correct response probabilities for the KF
    if resp_up
        rt_vol(it) = mt_vol(it) >= .5;
        pt_vol(it) = 1-normcdf(.5,mt_vol(it),vt_vol(it));
        
        rt_ref(it) = mt_ref(it) >= .5;
        pt_ref(it) = 1-normcdf(.5,mt_ref(it),vt_ref(it));
    else
        rt_vol(it) = mt_vol(it) < .5;
        pt_vol(it) = normcdf(.5,mt_vol(it),vt_vol(it));
        
        rt_ref(it) = mt_ref(it) < .5;
        pt_ref(it) = normcdf(.5,mt_ref(it),vt_ref(it));
    end
    
    % VOL KF update
    kt_vol(it) = vt_vol(it)/(vt_vol(it)+vs_vol);
    mt_vol(it) = mt_vol(it) + kt_vol(it)*(traj_vol(it)-mt_vol(it));
    vt_vol(it) = (1-kt_vol(it))*vt_vol(it)+vd_vol;
    
    % REF KF update
    kt_ref(it) = vt_ref(it)/(vt_ref(it)+vs_ref);
    mt_ref(it) = mt_ref(it) + kt_ref(it)*(traj_ref(it)-mt_ref(it));
    vt_ref(it) = (1-kt_ref(it))*vt_ref(it)+vd_ref;
end


% visuals for testing
if false
    ntt = 1:100; % range of trials to visualize
    figure(2);
    clf
    hold on
    plot(ntt,mt_vol(ntt),'b','LineWidth',2)
    plot(ntt,mt_vol(ntt)+sqrt(vt_vol(ntt)),'b--','HandleVisibility','off')
    plot(ntt,mt_vol(ntt)-sqrt(vt_vol(ntt)),'b--','HandleVisibility','off')
    plot(ntt,epis(ntt),'r')
    scatter(ntt,traj_vol(ntt),'r','LineWidth',3)
    yline(.5,':','HandleVisibility','off');
    legend({'Kalman mean','True mean','Sampled value'})
    hold off
end

%
figure(1)
bar([mean(pt_ref) mean(pt_vol)]);
ylabel('Average p(correct)')
xticklabels({'REF','VOL'})

%% Study performance vs sampling spread

vars_smpl   = (.1:.01:.3).^2; % spreads to check
nvars       = numel(vars_smpl);
nt          = numel(traj_vol);

kt_unp = nan(nvars,nt); % kalman gain
vt_unp = nan(nvars,nt); % posterior variance
mt_unp = nan(nvars,nt); % estimated mean
rt_unp = nan(nvars,nt); % KF responses
pt_unp = nan(nvars,nt); % probability of correct KF responses (argmax)

traj_unp = nan(nvars,nt);

for ivar = 1:nvars
    
    % make trajectory
    traj_unp(ivar,:)    = get_pr(epis_ref,vars_smpl(ivar));
    nt                  = numel(traj_unp(ivar,:));
    
    vs_unp = var(epis_ref-traj_unp(ivar,:)); % effective variance
    vd_unp = 0; % no drift for REF/UNP condition
    
    resp_up = false; % whether response is above .5 or below
    iepi    = 0;
    
    for it = 1:nt
        if ismember(it,epistart)
            resp_up = ~resp_up;

            iepi = iepi + 1;
            % reset initial values for UNP condition
            mt_unp(ivar,it) = mean(traj_unp(ivar,:));
            vt_unp(ivar,it) = var(traj_unp(ivar,:));
            kt_unp(ivar,it) = 1;
        else
            mt_unp(ivar,it) = mt_unp(ivar,it-1);
            vt_unp(ivar,it) = vt_unp(ivar,it-1);
            kt_unp(ivar,it) = kt_unp(ivar,it-1);
        end
        
        % get responses and correct response probabilities for the KF
        if resp_up
            rt_unp(ivar,it) = mt_unp(ivar,it) >= .5;
            pt_unp(ivar,it) = 1-normcdf(.5,mt_unp(ivar,it),vt_unp(ivar,it));
        else
            rt_unp(ivar,it) = mt_unp(ivar,it) < .5;
            pt_unp(ivar,it) = normcdf(.5,mt_unp(ivar,it),vt_unp(ivar,it));
        end
    
        % UNP KF update
        kt_unp(ivar,it) = vt_unp(ivar,it)/(vt_unp(ivar,it)+vs_unp);
        mt_unp(ivar,it) = mt_unp(ivar,it) + kt_unp(ivar,it)*(traj_unp(ivar,it)-mt_unp(ivar,it));
        vt_unp(ivar,it) = (1-kt_unp(ivar,it))*vt_unp(ivar,it)+vd_unp;
    end
end

% plot
figure(1)
bar(mean(pt_unp,2))
sds_str = sprintfc('%.2f',sqrt(vars_smpl));
xticklabels(sds_str)
xlabel('SDs')
ylabel('Mean p(correct)')
yline(mean(pt_vol),':','LineWidth',2);

% choose spread that matches difficulty of VOL
[~,idx] = min(abs(mean(pt_vol)-mean(pt_unp,2))); 
fprintf('SD(UNP) matching VOL difficulty : %.4f\n',sqrt(vars_smpl(idx)));
fprintf('SD(REF) = %.4f ; SD difficulty multiplier = %2.1f\n',sqrt(var_smpl),sqrt(vars_smpl(idx))/sqrt(var_smpl))

%%
% visualize exp and KF values

nepis_vis = 10;
nt = sum(nepilen(1:nepis_vis));
figure(2)
clf
sgtitle('Task and KF trajectories')
% VOL
subplot(3,3,1) %subplot(1,3,1)
title('VOL')
ylim([0 1]);
hold on
shadedErrorBar(1:nt,mt_vol(1:nt),sqrt(vt_vol(1:nt)),'lineprops',{'b','LineWidth',2},'patchSaturation',.1);
plot(1:nt,epis_vol(1:nt),'r')
scatter(1:nt,traj_vol(1:nt),'r.','LineWidth',3)
yline(.5,':','LineWidth',2,'HandleVisibility','off');
for i = 1:nepis_vis
    xline(epistart(i));
end
legend({'True mean','Sampled value','Kalman mean'})
hold off
% REF
subplot(3,3,2) %subplot(1,3,2)
title('REF')
ylim([0 1]);
hold on
plot(1:nt,epis_ref(1:nt),'r')
scatter(1:nt,traj_ref(1:nt),'r.','LineWidth',3)
yline(.5,':','LineWidth',2,'HandleVisibility','off');
for i = 1:nepis_vis
    shadedErrorBar(epistart(i):(epistart(i)+nepilen(i)-1),...
                    mt_ref(epistart(i):(epistart(i)+nepilen(i)-1)),...
                    sqrt(vt_ref(epistart(i):(epistart(i)+nepilen(i)-1))),...
                    'lineprops',{'b','LineWidth',2},'patchSaturation',.1);
    xline(epistart(i));
end
legend({'True mean','Sampled value','Kalman mean'})
hold off
% UNP
subplot(3,3,3) %subplot(1,3,3)
title('UNP')
ylim([0 1]);
hold on
plot(1:nt,epis_ref(1:nt),'r')
scatter(1:nt,traj_unp(idx,1:nt),'r.','LineWidth',3)
yline(.5,':','LineWidth',2,'HandleVisibility','off');
for i = 1:nepis_vis
    shadedErrorBar(epistart(i):(epistart(i)+nepilen(i)-1),...
                    mt_unp(idx,epistart(i):(epistart(i)+nepilen(i)-1)),...
                    sqrt(vt_unp(idx,epistart(i):(epistart(i)+nepilen(i)-1))),...
                    'lineprops',{'b','LineWidth',2},'patchSaturation',.1);
    xline(epistart(i));
end
legend({'True mean','Sampled value','Kalman mean'})

subplot(3,3,4)
plot(1:nt,vt_vol(1:nt))
ylim([0 .03])
ylabel('posterior variance')

subplot(3,3,5)
plot(1:nt,vt_ref(1:nt))
ylim([0 .03])

subplot(3,3,6)
plot(1:nt,vt_unp(idx,1:nt))
ylim([0 .03])

subplot(3,3,7)
plot(1:nt,kt_vol(1:nt))
ylabel('kalman gain')
ylim([0 1])

subplot(3,3,8)
plot(1:nt,kt_ref(1:nt))
ylim([0 1])

subplot(3,3,9)
plot(1:nt,kt_unp(idx,1:nt))
ylim([0 1])

hold off









