function [out] = gen_session(cfg)


% localize configuration variables
var_drift   = cfg.var_drift;    % drifting variance (for VOLATILE sessions)
avgmin      = cfg.avgmin;       % minimum average value
avgmax      = cfg.avgmax;       % maximum average value

ngen        = 1e3;  % number of episodes to be generated
epimin      = 8;    % minimum episode length
epimax      = 24;   % maximum episode length

% set global random number stream
rngseed = 'shuffle';
rng = RandStream('mt19937ar','Seed',rngseed);
RandStream.setGlobalStream(rng);

% FIRST STEP OF TASK GENERATION
% generate episodes
fprintf('generating episodes\n');

get_pr = @(m,v)betasmp(m,v); % sample from beta distr. w/ mean m and variance v

pr_all = cell(ngen,1);
pr = zeros(1,epimax+2);

% Generate mean-drift episodes (VOL)
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

% Filter through episodes whose median lies within some range, somewhere inside the avg min/max range
xavg = cellfun(@median,pr_all);
i = xavg >= 0.55 & xavg <= 0.65;
pr_all = pr_all(i);

% The function should create all 3 sessions at the same time, as they rely on each
% other to be formed.

% Configuration:
%{

Number of episodes that difficulty will be measured by

Drifting variance for VOL
FNR for REF




%}


% 1/ Get drifting episodes for VOL
% 2/ Calculate means over each episode
% 3/ Get necessary spread for difficulty for REF
% 4/ Apply spread on the drifting episodes for VOL
% 5/ Calculate difficulty for VOL

% 6/ Need criteria for choosing the different conditions

%  Generate UNP episodes based on static means and matched difficulty from VOL







end