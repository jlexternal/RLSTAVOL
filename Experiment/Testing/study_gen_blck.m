% study block/trial generation for RLSTAVOL

clear all
clc
addpath('..');
cfg = struct;
cfg.ntrls   = 300;   
cfg.mgen    = .6;

fnr_trn     = 0.25;
if fnr_trn > 0
    f           = @(sig)fnr_trn-normcdf(.5,cfg.mgen,sig);
    cfg.sgen    = fzero(f,abs(rand)*cfg.mgen);  
else
    cfg.sgen    = .1;
end
cfg.nbout   = 1;    
cfg.ngen    = 10000;
cfg.nbgen   = 1000;

if fnr_trn == 0
    blck(1,:) = gen_blck_rlstavol(cfg);
else 
    blck(1,:) = gen_ranked_blck_rlstavol(cfg);
end

blck(blck>.99) = .99;
blck(blck<.01) = .01;

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
m_k = nan(size(blck)); % KF tracked mean of rewards
w_k = nan(size(blck)); % KF posterior variance
k_k = nan(size(blck)); % Kalman gain

% volatile Kalman filter
m_vk = nan(size(blck)); % VKF tracked mean of rewards
w_vk = nan(size(blck)); % VKF posterior variance
k_vk = nan(size(blck)); % VKF Kalman gain
v_vk = nan(size(blck)); % VKF volatility
c_vk = nan(size(blck)); % VKF covariance
lmbd = .9; % lambda parameter for VKF
vini = .1; % initial volatility

ls = nan(size(blck,1),cfg.ntrls);
lini = [0 0];
for it = 1:cfg.ntrls
    
    sig_pr = cfg.sgen; %cfg.sgen; % process uncertainty (s.d. of process noise)
    sig_ob = cfg.sgen; % observation uncertainty (s.d around hidden state)
    
    for ibt = 1:size(blck,1)
        % evidence accumulation for the two types of blocks
        ls(ibt,it)  = l(blck(ibt,it),lini(ibt));
        lini(ibt)	= ls(ibt,it);
    
        o  = blck(ibt,it); % outcome
        
        % Standard KF
        if it == 1
            % initalize
            kt = 1;     % kgain
            mt = .5;    % prior estimate
            w  = 1;     % posterior variance
        else
            kt = k_k(ibt,it-1);    
            mt = m_k(ibt,it-1);    
            w  = w_k(ibt,it-1);
        end
        k_k(ibt,it) = (w+sig_pr^2)/(w+sig_pr^2+sig_ob^2);
        m_k(ibt,it) = mt+kt*(o-mt);
        w_k(ibt,it) = (1-kt)*(w+sig_pr^2);
        
        % Volatile KF
        if it == 1
            kt = 1;     % kgain
            mt = .5;    % prior estimate
            w  = 1;     % posterior variance
            v  = vini;  % volatility 
        else
            kt = k_vk(ibt,it-1);
            mt = m_vk(ibt,it-1);
            w  = w_vk(ibt,it-1);
            v  = v_vk(ibt,it-1);
        end
        
        k_vk(ibt,it) = (w+v)/(w+v+sig_ob^2);    % kalman gain
        m_vk(ibt,it) = mt+k_vk(ibt,it)*(o-mt);  % tracking mean
        w_vk(ibt,it) = (1-kt)*(w+v);            % posterior variance
        c_vk(ibt,it) = (1-k_vk(ibt,it))*w;      % covariance
        v_vk(ibt,it) = v+lmbd*((m_vk(ibt,it)-mt)^2+w+w_vk(ibt,it)-2*c_vk(ibt,it)-v); % volatility update

    end
    
    
end

%%
nsp = 4;
clf
% evid. acc.
subplot(nsp,1,1);
hold on;
for i = 1:numel(v_it)-1
    if mod(i,2) == 1
        X = [v_it(i) v_it(i) v_it(i+1) v_it(i+1)];
        Y = [-1000 1000 1000 -1000];
        patch(X,Y,[.2 .2 .2],'FaceAlpha',.2,'EdgeColor','none','HandleVisibility','off');
    end
end
plot(ls');
yline(0);
ylim([min(ls)-50 max(ls)+50]);
title('Standard evidence accumulation','FontSize',12)

% kf
subplot(nsp,1,2);
hold on;
for i = 1:numel(v_it)-1
    if mod(i,2) == 1
        X = [v_it(i) v_it(i) v_it(i+1) v_it(i+1)];
        Y = [-1000 1000 1000 -1000];
        patch(X,Y,[.2 .2 .2],'FaceAlpha',.2,'EdgeColor','none','HandleVisibility','off');
    end
end
plot(m_k','LineWidth',2);
plot(m_vk','--','LineWidth',2);
scatter(1:cfg.ntrls,blck,'.k');
yline(.5,':');
ylim([0 1]);
legend({'KF','VKF','Feedback'});
title('Tracked means and feedback','FontSize',12)

% kalman gain
subplot(nsp,1,3);
hold on
for i = 1:numel(v_it)-1
    if mod(i,2) == 1
        X = [v_it(i) v_it(i) v_it(i+1) v_it(i+1)];
        Y = [-1000 1000 1000 -1000];
        patch(X,Y,[.2 .2 .2],'FaceAlpha',.2,'EdgeColor','none','HandleVisibility','off');
    end
end
plot(k_k);
plot(k_vk);
ylim([max([min(k_k)-.1 min(k_vk)-.1 0]) 1]);
title('Kalman gain','FontSize',12);
legend({'Kalman gain (KF)','Kalman gain (VKF)'})

% KF variables
subplot(nsp,1,4);
hold on
for i = 1:numel(v_it)-1
    if mod(i,2) == 1
        X = [v_it(i) v_it(i) v_it(i+1) v_it(i+1)];
        Y = [-1000 1000 1000 -1000];
        patch(X,Y,[.2 .2 .2],'FaceAlpha',.2,'EdgeColor','none','HandleVisibility','off');
    end
end
plot(2:cfg.ntrls,v_vk(2:end));
plot(w_k);
plot(w_vk);
ylim([0 min([max([max(w_k)+.2 max(w_vk)+.2]) 1])]);
title(sprintf('VKF Parameters: lambda=%.02f, vini=%.02f',lmbd,vini));
legend({'Tracked volatility (VKF)','Posterior var. (KF)','Posterior var. (VKF)'})
