function [blck] = gen_ranked_blck_rlstavol(cfg)
%
%  Usage: [blck] = GEN_RANKED_BLCK_RLSTAVOL(cfg)
%
%  where cfg is a configuration structure
%        blck is/are the generated block(s)
%
%  The configuration structure cfg contains the following fields:
%   * ntrls     - number of trials per block
%   * mgen      - mean of generative distribution
%   * ngen      - number of blocks to sample from initial distribution
%   * nbgen     - number of blocks to output from initial sampling
%   * nbout     - number of blocks to output after difficulty ranking
%   * fnr       - false negative rate of higher distribution
%   * sgen      - standard devation of generative distribution
%
%   Potentially change these below:
%    * m_crit    - max distance of sampling mean from true mean
%    * s_crit    - max difference of sampling spread from true spread
%
% This function samples from a true generative distribution, and outputs a set of
% samples given some criteria. 
%
% Note: There is no consideration of the condition structure.
%       It simply outputs the most "average" set of sampled 
%       feedback values from the generative distribution.
% 
% Jun Seok Lee - Oct 2020

% Configuration structure checks
if ~isfield(cfg,{'ntrls','mgen','nbgen','nbout'})
    error('Incomplete configuration structure!');
end
% Check for spread value configuration
if ~xor(isfield(cfg,'sgen'),isfield(cfg,'fnr'))
    % function will exclusively take 'sgen' or 'fnr' but not both
    error('Function requires either field ''sgen'' XOR ''fnr''!');
end
% calculate sd of generative distribution from false negative rate
if isfield(cfg,'fnr')
    f    = @(sig)cfg.fnr-normcdf(.5,cfg.mgen,sig);
    for itry = 1:1000
        cfg.sgen = fzero(f,abs(rand)*cfg.mgen);
        if ~isnan(cfg.sgen)
            break
        elseif itry == 1000
            error('An s.d. corresponding to the specified FNR was not found after 1000 tries...\nVerify the value of your FNR.');
        else
            warning('Ignore previous message about fzero...')
            continue
        end
    end
end
nbgen = cfg.nbgen;
nbout = cfg.nbout;

% Generate experimental block candidates
cfg.nbout = nbgen;
for itry = 1:1000
    blcks = gen_blck_rlstavol(cfg); % outputs nbgen amount of blocks
    % ensure sufficient number of block samples
    if size(blcks,1) < cfg.nbout
        continue
    else
        break
    end
end

% Round to nearest 2nd decimal place
blcks = round(blcks,2);
% Enforce min/max boundaries
blcks(blcks > .99) = .99;
blcks(blcks < .01) = .01;

% Calculate evidence at each trial
ls    = log(normpdf(blcks,cfg.mgen,cfg.sgen))-log(normpdf(blcks,1-cfg.mgen,cfg.sgen)); % log odds ratio of high vs low option
l_sum = sum(ls(:,1:cfg.ntrls-1),2); % sum up to the penultimate trial

% Rank block candidates by difficulty measured as sum of log-odds ratios over the block trajectory
[~,ipos] = sort(l_sum,1,'ascend'); % rank from most difficult to least

blck = nan(nbout,cfg.ntrls);
% choose from various difficulties 
for i = 1:nbout
    idx = floor(nbgen/nbout)*(i-1) + randi(nbgen/nbout);
    blck(i,:,:) = blcks(ipos(idx),:,:);
end

end