% EASY5  computes vector components of a baseline. With given C/A code
%	     and phase observations we estimate the ambiguities using the
%	     Lambda method and next estimate the baseline components by a
%	     least-squares procedure. The code does not handle
%	     1. cycle slips, and
%	     2. outliers.
%	     The present code is no real RTK code as all computational steps
%	     do not happen on an epoch-by-epoch basis

addpath('../lib/easy');

% Initial computations of constants
v_light = 299792458;	     % vacuum speed of light m/s
f1 = 154 * 10.23E6;		     % L1 frequency Hz
f2 = 120 * 10.23E6;			 % L2 frequency Hz
lambda1 = v_light / f1;	     % wavelength on L1:  .19029367  m
lambda2 = v_light / f2;	     % wavelength on L2:  .244210213 m

% Read RINEX ephemerides file and convert to internal Matlab format
rinex.eph2mat('../data/RS_matv_50mm_01.nav', '../data/eph.dat');
Eph = get_eph('../data/eph.dat');

% We identify the master observation file and open it
ofile1 = '../data/RS_matv_50mm_01.obs'; 
fid1 = fopen(ofile1, 'rt');
[Obs_types1, ~, ~, ~] = anheader(ofile1);
NoObs_types1 = size(Obs_types1, 2) / 2;

% We start by estimating the master position
[time1, dt1, sats1, eof1] = rinex.findNextValidEpoch(fid1);
NoSv1 = size(sats1, 1);
m = NoSv1;
obs1raw = grabdata(fid1, NoSv1, NoObs_types1);
i = fobs_typ(Obs_types1, 'C1'); % We use C/A pseudoranges
[X_i, el] = recpo_ls(obs1raw(:, i), sats1, time1, Eph);
[phi_i, lambda_i, h_i] = togeod(6378137, 298.257223563, X_i(1), X_i(2), X_i(3));

% We close all files to ensure that the next reading starts
% at the top of the observation files
fclose all;

% Finding columns in Eph for each SV
for t = 1:m
	col_Eph(t) = find_eph(Eph, sats1(t), time1);
end

% Computation of elevation angle to all SVs.
all_sats1 = sats1;

% Delete Sv with elevation smaller than 10 degrees
sats1(el < 10) = [];
del_sat = setdiff(all_sats1, sats1);

no_del_sat = [];

for t = 1:length(del_sat)
    no_dels = find(del_sat(t) == all_sats1);
    no_del_sat = [no_del_sat; no_dels];
end

No_del_sat = length(no_del_sat);

% The SV with largest elevation is taken as reference SV
[y,ind] = max(el);
rearr = sort(all_sats1);
refsv = rearr(ind);
ofile1 = '../data/RS_matv_50mm_01.obs'; 
fid1 = fopen(ofile1,'rt');
ofile2 = '../data/RS_matv_50mm_02.obs'; 
fid2 = fopen(ofile2,'rt');

% We start reading both observation files
[Obs_types1, ant_delta1, ifound_types1, eof11] = anheader(ofile1);
NoObs_types1 = size(Obs_types1,2)/2;
obsstr(1, 1:2) = 'C1'; 
obsstr(2, 1:2) = 'L1';
match = zeros(1, 2);

for t = 1:2
    for ii = 1:NoObs_types1
        mat = strmatch(obsstr(t, 1:2), Obs_types1(1, 2 * ii - 1:2 * ii), 'exact');
        if isempty(mat) == 0
            match(1, t) = ii; 
        end
    end
end

Oc = match(match > 0);
[Obs_types2, ant_delta2, ifound_types2, eof12] = anheader(ofile2);
NoObs_types2 = size(Obs_types2, 2) / 2;

m1 = m - No_del_sat; % original number of SVs - deleted SVs due to low elevations
X_a = [];
X_j = X_i(1:3, 1);
X = zeros(3 + m1 - 1, 1);

% We process three epochs for estimating ambiguities; the present data evidently
% need three or more epochs for getting reliable estimates of the float ambiguities
for q = 1:5
    X_j = X_i(1:3, 1) + X(1:3, 1);
    [time1, dt1, sats1, eof1] = rinex.findNextValidEpoch(fid1);
    [time2, dt2, sats2, eof2] = rinex.findNextValidEpoch(fid2);
    
    if time1 ~= time2
        disp('Epochs do not correspond in time')
        break
    end;
    
    time = time1;
    NoSv1 = size(sats1, 1);
    NoSv2 = size(sats2, 1);
    obsm = grabdata(fid1, NoSv1, NoObs_types1);
    obsr = grabdata(fid2, NoSv2, NoObs_types2);
    
    % Deleting SVs that are only observed at one receiver
    if NoSv1 ~= NoSv2
        kk = intersect(sats1, sats2); 
    else
        kk = sats1;
    end
    
    if q ==1
        X = zeros(3 + length(kk) - length(no_del_sat), 1);
    end;  % coord.diff., N1, N2
    
    refrow = find(refsv == kk);
    
    % Reordering of rows in master and rover observations corresponding to
    % increasing SV numbers and deletion of non-used observation columns
    for s = 1:length(kk)
        j1 = find(kk(s) == sats1);
        j2 = find(kk(s) == sats2);
        obs1(s, 1:length(Oc)) = obsm(j1, Oc);
        obs2(s, 1:length(Oc)) = obsr(j2, Oc);
    end

    tt = 0;
    A1 = [];
    t0 = 1:length(kk);
    t1 = setdiff(t0, no_del_sat); % we delete the low satellites

    % Computing rho for refsv
    [~, rhok_j, ~] = get_rho(time, obs2(refrow, 1), Eph(:, col_Eph(refrow)), X_j);
    [tcorr, rhok_i, Xk_ECF] = get_rho(time, obs1(refrow, 1), Eph(:, col_Eph(refrow)), X_i);

    for t = t1
        tt = tt + 1;
        
        [~, rhol_j, ~] = get_rho(time, obs2(t, 1), Eph(:, col_Eph(t)), X_j);
        [tcorr, rhol_i, Xl_ECF] = get_rho(time, obs1(t, 1), Eph(:, col_Eph(t)), X_i);
        
        A0 = [
            (Xk_ECF(1) - X_j(1))/rhok_j - (Xl_ECF(1) - X_j(1))/rhol_j ...
            (Xk_ECF(2) - X_j(2))/rhok_j - (Xl_ECF(2) - X_j(2))/rhol_j ...
            (Xk_ECF(3) - X_j(3))/rhok_j - (Xl_ECF(3) - X_j(3))/rhol_j
        ];
        A1 = [A1; A0];
        
        Phi1 = (obs1(refrow, 2) - obs1(t, 2) - obs2(refrow, 2) + obs2(t, 2)) * lambda1;
        b(tt, :) = Phi1 - lambda1 * X(3 + tt, 1);
        bk(tt, :) = rhok_i - rhok_j - rhol_i + rhol_j;
    end;
    
    m1 = length(t1); % New m1: we have deleted non-common and low satellites
    N = zeros(3 + m1, 3 + m1);	  % initialization of normals
    rs = zeros(3 + m1, 1);	      % initialization of right side
    
    % Computation of covariance matrix Sigma for double differenced observations
    D = [ones(m1, 1) -eye(m1) -ones(m1, 1) eye(m1)];
    Sigma = D * D';
    A_modi = eye(m1);	    	  % modified coefficient matrix
    col = find(refsv == sats1);   % find column for reference PRN
    A_modi(:, col) = -ones(m1, 1);
    A_aug = [A1 lambda1*A_modi];
    N = N + A_aug'*Sigma*A_aug;
    rs = rs + A_aug'*Sigma*(b - bk);
end %q

PP = pinv(N);

% X contains the three preliminary baseline components and the float ambiguities
X = PP * rs %;

% Estimation of ambiguities by means of the Lambda method
[a, sqnorm, Sigma_afixed, Z] = lambda(X(4:4 + m1 - 1, 1), PP(4:4 + m1 - 1, 4:4 + m1 - 1));

% Correcting to baseline vector as consequence of changing float ambiguities to fixed ones
X(1:3, 1) = X(1:3, 1) - PP(1:3, 4:4 + m1 - 1) * inv(PP(4:4 + m1 - 1, 4:4 + m1 - 1)) * ...
    (X(4:4 + m1 - 1, 1) - a(:, 1)); %select first set of candidates
X(4:4 + m1 - 1, 1) = a(:, 1);

fprintf('\n N1 for PRN %3.0f: %3.0f',[sats1(t1)'; a(1:m1,1)'])
fprintf('\n')
% fprintf('\n N2 for PRN %3.0f: %3.0f',[sats1(t1)';a(m1+1:m1,1)'])

% We close and reopen all files in order to start reading at a known position
fclose all;
ofile1 = '../data/RS_matv_50mm_01.obs';
fid1 = fopen(ofile1, 'rt');
ofile2 = '../data/RS_matv_50mm_02.obs';
fid2 = fopen(ofile2, 'rt');

% At end of ofile2 we overwrite empty observations with NaN's to obtain 22 valid epochs
qend = 175;
X_jacc = [];
base = [];

for q = 1:qend
    X_j = X_i(1:3, 1) + X(1:3, 1);
    [phi_j, lambda_j, h_j] = togeod(6378137, 298.257223563, X_j(1), X_j(2), X_j(3));
    [time1, dt1, sats1, eof1] = rinex.findNextValidEpoch(fid1);
    [time2, dt2, sats2, eof2] = rinex.findNextValidEpoch(fid2);
    
    if time1 ~= time2
        disp('Epochs do not correspond in time')
        break
    end;
    
    time = time1;
    NoSv1 = size(sats1, 1);
    NoSv2 = size(sats2, 1);
    obsm = grabdata(fid1, NoSv1, NoObs_types1);
    obsr = grabdata(fid2, NoSv2, NoObs_types2);
    obs1 = obsm(:, Oc); % P1 P2 Phi1 Phi2
    
    % Reordering of rows in obsr to correspond to obsm
    for s = 1:m
        Ind = find(sats1(s) == sats2(:));
        obs2(s, :) = obsr(Ind, Oc);
    end
    
    % Computing rho for refsv
    [~, rhok_j, ~] = get_rho(time, obs2(1, 1), Eph(:, col_Eph(1)), X_j);
    [tcorr, rhok_i, Xk_ECF] = get_rho(time, obs1(1, 1), Eph(:, col_Eph(1)), X_i);
    
    tt = 0;
    A1 = [];
    
    for t = t1
        tt = tt + 1;
        
        [~, rhol_j, ~] = get_rho(time, obs2(t, 1), Eph(:, col_Eph(t)), X_j);
        [tcorr, rhol_i, Xl_ECF] = get_rho(time, obs1(t, 1), Eph(:, col_Eph(t)), X_i);
        
        A0 = [
            (Xk_ECF(1) - X_j(1))/rhok_j - (Xl_ECF(1) - X_j(1))/rhol_j ...
            (Xk_ECF(2) - X_j(2))/rhok_j - (Xl_ECF(2) - X_j(2))/rhol_j ...
            (Xk_ECF(3) - X_j(3))/rhok_j - (Xl_ECF(3) - X_j(3))/rhol_j
        ];
        A1 = [A1; A0];
        
        Phi1 = (obs1(refrow, 2) - obs1(t, 2) - obs2(refrow, 2) + obs2(t, 2)) * lambda1; %-t_corr;
        b(tt, :) = Phi1 - lambda1 * a(tt, 1);
        bk(tt, :) =  rhok_i - rhok_j - rhol_i + rhol_j;
    end; % t
    
    N = A1'*Sigma*A1;
    rs = A1'*Sigma*(b - bk);
    x = inv(N) * rs;
    X_j = X_j + x;
    base = [base X_j - X_i(1:3)];
    X_jacc = [X_jacc X_j];
end %q

X = X_j - X_i(1:3, 1);

% Transformation of geocentric baseline coordinates into topocentric coordinates
for i = 1:qend
    [e(i), n(i), u(i)] = xyz2enu(phi_j, lambda_j, base(1, i), base(2, i), base(3, i));
end

fprintf('\n\nBaseline Components\n')
fprintf('\nX: %8.3f m,  Y: %8.3f m,  Z: %8.3f m\n',X(1),X(2),X(3))
fprintf('\nE: %8.3f m,  N: %8.3f m,  U: %8.3f m\n',mean(e),mean(n),mean(u))

figure(1);
plot(1:qend,[(e-e(1))' (n-n(1))' (u-u(1))']*1000,'linewidth',2)
title('Differential Position Estimates From Phase Observations','fontsize',16)
ylabel('Corrections to Initial Position [mm]','fontsize',16)
xlabel('Epochs [2 s interval]','fontsize',16)
legend('East','North','Up')
set(gca,'fontsize',16)
legend

% print -deps easy5
%%%%%%%%%%%%%%%%%%%%%% end easy5.m  %%%%%%%%%%%%%%%%%%%