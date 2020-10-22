function [blck] = gen_blck_rlstavol(cfg)
%
%  Usage: [blck] = GEN_BLCK_RLSTAVOL(cfg)
%
%  where cfg is a configuration structure
%        blck is/are the generated block(s)
%
%  The configuration structure cfg contains the following fields:
%   * ntrls     - number of trials per block
%   * mgen      - mean of generative distribution
%   * sgen      - standard devation of generative distribution
%   * ngen      - number of blocks to be selected from
%   * nbout     - number of blocks to output
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

% check configuration structure
if ~all(isfield(cfg,{'ntrls','mgen','sgen','nbout'}))
    error('Incomplete configuration structure!');
end
if ~isfield(cfg,'ngen')
    cfg.ngen = 1e4;
end
if ~isfield(cfg,'mcrit')
    cfg.mcrit = .1;
end
if ~isfield(cfg,'scrit')
    cfg.scrit = .1;
end

% Localize configuration parameters
ntrls   = cfg.ntrls;
mgen    = cfg.mgen;
sgen    = cfg.sgen;
ngen    = cfg.ngen;
nbout   = cfg.nbout;
mcrit  = cfg.mcrit;
scrit  = cfg.scrit;

blck = [];

% Initialize random number generator
RandStream.setGlobalStream(RandStream('mt19937ar','Seed','shuffle'));
blocks = normrnd(mgen, sgen, [ngen ntrls]); % sample from distribution

% find means of blocks
m_blocks = mean(blocks,2);

% calculate spread of blocks
s_blocks = std(blocks,0,2);

% calculate distance measures for each block
m_blocks = abs(m_blocks - mgen);
s_blocks = abs(s_blocks - sgen);

% keep blocks within acceptable criteria
ind_crit = intersect(find(m_blocks<=mcrit*mgen),find(s_blocks<=scrit*sgen));


blocks = blocks(ind_crit,:);
m_blocks = m_blocks(ind_crit);
s_blocks = s_blocks(ind_crit);

% rank them
[~,imeans]      = sort(m_blocks,'ascend'); 
[~,istds]       = sort(s_blocks,'ascend');
m_rank          = 1:length(m_blocks);
s_rank          = 1:length(s_blocks);
m_rank(imeans)  = m_rank;
s_rank(istds)   = s_rank;
[~,iblocks]     = sort(m_rank+s_rank,'ascend');
iblocks         = iblocks(1:nbout);
blocks          = blocks(iblocks,:);

blck = blocks;



