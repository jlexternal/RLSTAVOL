% script TEST_GEN_SESSION

cfg = struct;


% required input arguments (temporarily hard coded)
cfg.var_drift   = 0.05^2;
cfg.avgmin      = 
cfg.avgmax      = 
cfg.fnr         = .2;   % desired false negative rate for REF 


var_drift   = cfg.var_drift; % drift variance / process noise

fnr         = cfg.fnr;

f           = @(sig)fnr-normcdf(.5,mean,sig);
var_smpl    = fzero(f,abs(rand)*mean); % sampling variance / measurement uncertainty




% 1/ Generate episodes for VOL

% a. generate mean drifts for VOL condition
% b. calculate mean values for episodes and use them as means for REF condition
% c. calculate the sampling variance based on the desired false negative rate around the
%       mean values in REF
% d. generate trajectories for REF and VOL
% e. calculate effective measurement uncertainty (vs) for REF
% f. calculate mean accuracy for VOL based on KF
% g. simulate UNP episodes to determine spread value that matches difficulty to VOL
% h. 







%% old code

% episode generation parameters
ngen        = 2e3;  % number of episodes to be generated
nepis       = 1e3;  % number of episodes desired
epimin      = 8;    % minimum episode length
epimax      = 24;   % maximum episode length
avgmin      = 0.55;
avgmax      = 0.75;


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