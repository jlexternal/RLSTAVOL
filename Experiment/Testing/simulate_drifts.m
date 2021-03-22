
clear all
close all
clc

ngen        = 1e3;  % number of episodes to be generated
tau_fluc    = 3;    % drifting coherence
epimin      = 8;    % minimum episode length
epimax      = 24;   % maximum episode length


var_drift = 0.05^2;

avgmin    = 0.55;
avgmax    = 0.75;

rngseed = 'shuffle';

% set global random number stream
rng = RandStream('mt19937ar','Seed',rngseed);
RandStream.setGlobalStream(rng);

% set task generation random number stream
rng_tsk = RandStream('mt19937ar','Seed',rngseed);

% FIRST STEP OF TASK GENERATION
% generate episodes
fprintf('generating episodes\n');

get_pr = @(m,v)betasmp(m,v); % sample from beta distr. w/ mean m and variance v

pr_all = cell(ngen,1);
pr = zeros(1,epimax+2);

% Generate mean-drift episodes
for i = 1:ngen
    if mod(i,10) == 0
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

%{
figure;
plot(cat(2,pr_all{3},1-pr_all{10},pr_all{40},1-pr_all{50}))
%}

% TEST: get drifting variance

pr_all_vec      = horzcat(pr_all{:});
var_drift_ef    = var(pr_all_vec(2:end)-pr_all_vec(1:end-1));

fprintf('True drift variance: %.4f\nEffective drift variance: %.4f\n',var_drift,var_drift_ef);

%% Choose episodes for task

% Select 5 episodes until 80 trials are accumulated (from 24,20,16,12,8)
nepilen     = cellfun(@numel,pr_all);

nlens   = 8:4:24;
ntrl    = sum(nlens);
nepis   = numel(nlens);
norder  = randsample(nepis,nepis);

epis = [];
epistart = zeros(1,nepis);
epiend   = zeros(1,nepis);
epiavg   = zeros(1,nepis);

for i = 1:nepis
    % find episode w/ indicated length and add to array
    ind         = nepilen == nlens(norder(i));
    epi_cat     = pr_all{randsample(find(ind == 1),1)}; 
    epis        = cat(2,epis,epi_cat); 
    
    epiavg(i)   = mean(epi_cat);
    if i == 1
        epistart(i) = 1;
    else
        epistart(i) = epistart(i-1)+nlens(norder(i-1));
    end
    epiend(i)   = epistart(i)+ nlens(norder(i));
    
    % visualize episodes
    figure(1);
    xlim([0 ntrl]);
    plot(epis)
    hold on
    xline(epistart(i));
end
epiend(end)= epiend(end) - 1;

%% Make sessions

var_ref = .1^2;
var_vol = var_ref;
var_unp = 1.5*var_ref;

% 1/ Volatile session
epi_vol = epis;
epiavg_vol = epiavg;

% invert values at switch points
for i = 1:nepis
    if mod(i,2) == 0
        epi_vol(epistart(i):epistart(i)+nlens(norder(i))) = 1-epi_vol(epistart(i):epistart(i)+nlens(norder(i)));
        epiavg_vol(i) = 1-epiavg(i);
    end
end

% add unpredictability to drift
traj_vol = get_pr(epi_vol,var_vol); % sample volatile trajectory

% get pdfs at each point in drift
y = 0:.001:1;
pdf_vol = nan(numel(y),ntrl);
pdf_means_vol = nan(1,ntrl);
for i = 1:ntrl
    pdf_vol(:,i) = betafun(y,epi_vol(i),var_vol);
    pdf_vol(:,i) = pdf_vol(:,i)/sum(pdf_vol(:,i));
    [~,idx] = min(abs(pdf_vol(:,i)-sum(bsxfun(@times,y',pdf_vol(:,i))))); %find mean
    pdf_means_vol(i) = y(idx);
end

% 2/ Reference session

% create reference session from means in volatile session
epi_ref = zeros(size(epi_vol));
for i = 1:nepis
    epi_ref(epistart(i):epiend(i)) = epiavg_vol(i);
end
traj_ref = get_pr(epi_ref,var_ref);

% get pdfs
pdf_ref = nan(numel(y),ntrl);
pdf_means_ref = nan(1,ntrl);
for i = 1:ntrl
    pdf_ref(:,i) = betafun(y,epi_ref(i),var_ref);
    [~,idx] = min(abs(pdf_ref(:,i)-sum(bsxfun(@times,y',pdf_ref(:,i)))));
    pdf_means_ref(i) = y(idx);
end

% 3/ Unpredictable session

% create unpredictable session from means in reference session
traj_unp = get_pr(epi_ref,var_unp);

% get pdfs
pdf_unp = nan(numel(y),ntrl);
for i = 1:ntrl
    pdf_unp(:,i) = betafun(y,epi_ref(i),var_unp);
end

% Plotting
figure(1);
clf
% plot volatile session
subplot(1,3,1);
hold on
pdf_plot_vol = imagesc(1:ntrl,y,pdf_vol);
%pdf_plot.AlphaData = .5;
plot(epi_vol,'red','LineWidth',2)
title('VOL session')
ylim([0 1])
xlim([0 ntrl])
for i = 1:5
    xline(epistart(i));
    plot([epistart(i) epiend(i)],[epiavg_vol(i) epiavg_vol(i)],'--red','LineWidth',2);
    std(traj_vol(epistart(i):epiend(i)),1)
end
yline(.5,'--','Color','white','LineWidth',1.5);
scatter(1:ntrl,traj_vol,'r','filled','LineWidth',1.5,'MarkerEdgeColor','white'); % plot sampled points around drift
scatter(1:ntrl,pdf_means_vol,'x','MarkerEdgeColor','black')
hold off

% plot reference session
subplot(1,3,2);
hold on
pdf_plot_ref = imagesc(1:ntrl,y,pdf_ref);
plot(epi_ref,'red','LineWidth',2);
title('REF session')
ylim([0 1])
xlim([0 ntrl])
scatter(1:ntrl,traj_ref,'r','filled','LineWidth',1.5,'MarkerEdgeColor','white');
scatter(1:ntrl,pdf_means_ref,'x','MarkerEdgeColor','black')
yline(.5,'--','Color','white','LineWidth',1.5);
hold off

% plot unpredictable session
subplot(1,3,3);
hold on
pdf_plot_unp = imagesc(1:ntrl,y,pdf_unp);
plot(epi_ref,'red','LineWidth',2);
title('UNP session')
ylim([0 1])
xlim([0 ntrl])
scatter(1:ntrl,traj_unp,'r','filled','LineWidth',1.5,'MarkerEdgeColor','white');
yline(.5,'--','Color','white','LineWidth',1.5);
hold off


%% Run standard KF for optimal performance measures

nt = numel(traj_vol);

% static parameters
vs = var(epi_vol-traj_vol);
vd = var_drift_ef;

% allocate variables
kt = nan(1,nt); % kalman gain
vt = nan(1,nt); % posterior variance
mt = nan(1,nt); % estimated mean
rt = nan(1,nt); % KF responses

resp_up = false;

% filter
for it = 1:nt
    if ismember(it,epistart)
        resp_up = ~resp_up;
    end
    
    if it == 1
        mt(1) = 0.5; % take mean of latent trajectory
        vt(1) = 1e3; % change to the variance of latent trajectory
        kt(1) = 1;
    else
        mt(it) = mt(it-1);
        vt(it) = vt(it-1);
        kt(it) = kt(it-1);
        
        if resp_up
            rt(it) = mt(it) >= .5;
        else
            rt(it) = mt(it) < .5;
        end
    end
    kt(it) = vt(it)/(vt(it)+vs);
    mt(it) = mt(it) + kt(it)*(traj_vol(it)-mt(it));
    vt(it) = (1-kt(it))*vt(it)+vd;
end

figure(2);
clf
hold on
plot(1:nt,mt,'b','LineWidth',2)
plot(1:nt,mt+sqrt(vt),'b--','HandleVisibility','off')
plot(1:nt,mt-sqrt(vt),'b--','HandleVisibility','off')
plot(1:nt,epi_vol,'r')
scatter(1:nt,traj_vol,'r','LineWidth',3)
yline(.5,':','HandleVisibility','off');
for i = 1:numel(epistart)
    xline(epistart(i));
end
legend({'Kalman mean','True mean','Sampled value'})
hold off


