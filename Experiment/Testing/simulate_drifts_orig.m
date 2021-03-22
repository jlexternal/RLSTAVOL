
clear all
close all
clc

ngen = 1e3; % number of episodes to be generated
tau_fluc  = 3; % drifting coherence
epimin    = 8; % minimum episode length
epimax    = 24; % maximum episode length


var_drift = 0.05^2;

avgmin    = 0.65;
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

% get_pr = @(p,t)betarnd(1+p*exp(t),1+(1-p)*exp(t));

get_pr = @(m,v)betasmp(m,v);

pr_all = cell(ngen,1);
pr = zeros(1,epimax+2);
for i = 1:ngen
    i
    while true
        pr(:) = 0;
        pr(1) = get_pr(0.5,var_drift);
%         pr(1) = get_pr(0.5,tau_fluc);
        if pr(1) < 0.5
            pr(1) = 1-pr(1);
        end
        for j = 2:epimax+2
            pr(j) = get_pr(pr(j-1),var_drift);
%             pr(j) = get_pr(pr(j-1),tau_fluc);
            if pr(j) < 0.5
                break
            end
        end
        epilen = j-1;
        epiavg = mean(pr(1:j-1));
        if epilen >= epimin && epilen <= epimax && epiavg >= avgmin && epiavg <= avgmax && max(pr(1:j-1)) <= 0.90 && max(abs(diff(pr(1:j)))) <= 0.10
            break
        end
    end
    pr_all{i} = pr(1:j-1);
end

xmax = cellfun(@max,pr_all);
xavg = cellfun(@median,pr_all);

i = xavg >= 0.65 & xavg <= 0.75;
pr_all = pr_all(i);

figure;
plot(cat(2,pr_all{3},1-pr_all{10},pr_all{40},1-pr_all{50}))