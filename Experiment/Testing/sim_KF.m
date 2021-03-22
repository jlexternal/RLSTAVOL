function [out] = sim_KF(cfg)


% configuration input
% epis  : mean drift array
% traj  : sampled trajectory array
% isvol : boolean: volatile condition or not 
% vs    : measurement uncertainty
% vd    : process noise / drift variance

epis    = cfg.epis;
traj    = cfg.traj;
isvol   = cfg.isvol;
vs      = cfg.vs;
vd      = cfg.vd;

nt = numel_traj;

% static parameters
vs = var(epis-traj);
vd = var_drift_ef;

% allocate variables
kt = nan(1,nt); % kalman gain
vt = nan(1,nt); % posterior variance
mt = nan(1,nt); % estimated mean
rt = nan(1,nt); % KF responses
pt = nan(1,nt); % probability of correct KF responses (argmax)

resp_up = false; % whether response is above .5 or below
iepi = 0;
% filter
for it = 1:nt
    
    if it == 1 || (~isvol && epis(it) ~= epis(it-1))
        resp_up = ~resp_up;
        iepi = iepi + 1;
        
        mt(1) = mean(traj); % mean of latent trajectory
        vt(1) = var(traj);  % variance of latent trajectory
        kt(1) = 1;
    else
        mt(it) = mt(it-1);
        vt(it) = vt(it-1);
        kt(it) = kt(it-1);
    end
    
    
    % get responses and correct response probabilities for the KF
    if resp_up
        rt(it) = mt(it) >= .5;
        pt(it) = 1-normcdf(.5,mt(it),vt(it));
    else
        rt(it) = mt(it) < .5;
        pt(it) = normcdf(.5,mt(it),vt(it));
    end
    
    % KF update
    kt(it) = vt(it)/(vt(it)+vs);
    mt(it) = mt(it) + kt(it)*(traj(it)-mt(it));
    vt(it) = (1-kt(it))*vt(it)+vd;
end








end