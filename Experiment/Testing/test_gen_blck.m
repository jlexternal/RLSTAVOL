% test block/trial generation

clear all
addpath('..');
cfg = struct;
cfg.ntrls   = 150;   
cfg.mgen    = .8;

fnr_trn     = 0.0;
if fnr_trn > 0
    f           = @(sig)fnr_trn-normcdf(.5,cfg.mgen,sig);
    cfg.sgen    = fzero(f,abs(rand)*cfg.mgen);  
else
    cfg.sgen    = .2;
end
cfg.nbout   = 1;    
cfg.ngen    = 10000;
cfg.nbgen   = 1000;

if fnr_trn == 0
    blck(1,:) = gen_blck_rlstavol(cfg);
else 
    blck(1,:) = gen_ranked_blck_rlstavol(cfg);
end

% introduce volatility
v_m = 20; 
v_s = 2;

% change point trial index
v_it = round(normrnd(v_m,v_s,[1 ceil(cfg.ntrls/v_m)]));
v_it = cumsum(v_it);
v_it = intersect(1:cfg.ntrls,v_it);
v_it = [v_it cfg.ntrls+1];

idx_switch = false(size(blck,2));
for i = 1:numel(v_it)
    if mod(i,2) == 1
        idx_switch(v_it(i):v_it(i+1)-1) = true;
    end
end

blck(1,idx_switch) = 1-blck(1,idx_switch);
%blck(2,idx_switch) = 1-blck(2,idx_switch);

% evidence accumulation model
l  = @(x,lpr)lpr + log(normpdf(x,cfg.mgen,cfg.sgen))-log(normpdf(x,1-cfg.mgen,cfg.sgen));

% standard Kalman filter
av_k = nan(size(blck)); % KF tracked mean of rewards
sd_k = nan(size(blck)); % KF posterior sd 

% volatile Kalman filter
av_vk = nan(size(blck)); % VKF tracked mean of rewards
sd_vk = nan(size(blck)); % VKF posterior sd 
v_vk  = nan(size(blck)); % VKF volatility
lmbd  = .9; % lambda parameter for VKF
vini  = .1; % initial volatility

ls = nan(2,cfg.ntrls);
lini = [0 0];
for it = 1:cfg.ntrls
    for ibt = 1:size(blck,1)
        % evidence accumulation for the two types of blocks
        ls(ibt,it)  = l(blck(ibt,it),lini(ibt));
        lini(ibt)	= ls(ibt,it);
    
        % standard KF
        if it == 1
            k            = 1e4/(1e4+cfg.sgen);
            av_k(ibt,it) = .5+k*(blck(ibt,it)-.5);
            sd_k(ibt,it) = sqrt(k/(1-k)*cfg.sgen^2);
        else
            k            = sd_k(ibt,it-1)^2/(sd_k(ibt,it-1)^2+cfg.sgen^2);
            av_k(ibt,it) = av_k(ibt,it-1)+k*(blck(ibt,it)-av_k(ibt,it-1));
            sd_k(ibt,it) = sqrt((1-k)*sd_k(ibt,it-1)^2 + cfg.sgen^2);
        end
        
        % volatile KF
        if it == 1
            k_vk            = (1e4+vini)/(1e4+vini+cfg.sgen^2);    % kalman gain
            av_vk(ibt,it)   = .5+k_vk*(blck(ibt,it)-.5);  % tracked average
            sd_vk(ibt,it)   = sqrt(k_vk/(1-k_vk)*cfg.sgen^2);% posterior variance
            
            w_cov_vk        = (1-k_vk)*1e4; % covariance
            v_vk(ibt,it)    = (1-k_vk)*lmbd*((av_vk(ibt,it)-.5)^2+sd_vk(ibt,it)^2+1e4-2*w_cov_vk-vini); % volatility update
        else
            k_vk            = (sd_k(ibt,it-1)^2+v_vk(ibt,it-1))/(sd_k(ibt,it-1)^2+v_vk(ibt,it-1)+cfg.sgen^2);
            av_vk(ibt,it)   = av_vk(ibt,it-1)+k_vk*(blck(ibt,it)-av_vk(ibt,it-1));
            sd_vk(ibt,it)   = sqrt((1-k_vk)*(sd_vk(ibt,it-1)^2+v_vk(ibt,it-1)));
            
            w_cov_vk        = (1-k_vk)*sd_vk(ibt,it-1)^2; 
            v_vk(ibt,it)    = (1-k_vk)*lmbd*((av_vk(ibt,it)-av_vk(ibt,it-1))^2+sd_vk(ibt,it)^2+sd_vk(ibt,it-1)^2-2*w_cov_vk-v_vk(ibt,it-1)); 
        end
        
        
    end
    
    
end

% evid. acc.
subplot(3,1,1);
plot(ls');
hold on;
yline(0);
for i = 1:numel(v_it)-1
    xline(v_it(i));
    hold on
end
% kf
subplot(3,1,2);
plot(av_k','LineWidth',2);
hold on;
plot(av_vk','--','LineWidth',2);
yline(.5,':');
for i = 1:numel(v_it)-1
    xline(v_it(i));
    hold on
end
ylim([0 1]);
legend({'KF','VKF'});
% rewards
subplot(3,1,3);
plot(1:cfg.ntrls,blck);
hold on;
plot(1:cfg.ntrls,v_vk);
yline(.5,':');
for i = 1:numel(v_it)-1
    xline(v_it(i));
    hold on
end
ylim([0 1]);
legend({'Feedback','Tracked volatility (VKF)'})
