%{
minimisePronyErrorNT v1.0 by Alberto Di Bartolo
minimise the error between experimental Master curve and the one
calculated by Prony series in PronyErrorNT
using fmincon. It can use any number of NT (# of n.e. branches)
It will start by Inputting a certain first guess in PronyErrorNT and
fmincon will try to minimise the output (the total error) while respecting
the boundary conditions and the constraint equations (see main body for
more info)
%}
for q = 1:5 % for any q>1 the script will use the last minimum as zero
    % sometimes this is better than changing the fmincon options
    if q==1
        NT = 14; % number of non-eq branches (should be the same as in PronyErrorNT)
        tausmallest = -11; % the smallest value of tau is 10^(tausmallest)
        divdec = 1; % tau values are logspaced but like 10^(1/divdec) 10^(1/divdec + 1/divdec), eg 10^0.5 10^1 10^1.5
        load MC33C_genericTref.mat % load your experimental MC data
        Etot = relmod(1); % the sum of E0 and all other moduli
        E0 = relmod(end); % the equilibrium modulus, modulus at rubbery plateau
        % Build Vector zero (the first try)
        zero(1:NT) = rand(1,NT).*Etot; % moduli zero
        zero(NT+1:NT+NT) = logspace(0,NT-1,NT); % relax times zero
        % equality constr Aeq*x=beq, the sum of all moduli is Etot
        Aeq = zeros(NT+NT);
        Aeq(1,:) = [ones(1,NT) zeros(1,NT)];
        beq = zeros(NT+NT,1); beq(1) = Etot-E0;
        % inequality constr A*x<=b, if desired the moduli values are forced to be in descending
        % order i.e. E(NT)<E(NT-1)<...<E1
        A = zeros(NT+NT); A1=A; A2=A;
        A1(2:NT,1:NT-1)=-eye(NT-1);
        A2(2:NT,2:NT)=eye(NT-1);
        A=A1+A2;
        b = zeros(2*NT,1);
        % boundaries cond
        Elb = zeros(1,NT);
        Eub = ones(1,NT).*(Etot-E0);
        taulb = logspace(tausmallest,NT/divdec+tausmallest-1/divdec,NT);
        tauub = taulb; % set tau values a priori
        % tauub = ones(1,NT).*Inf; % tau values are not set a priori
        lb = [Elb taulb];
        ub = [Eub tauub];
    else
    end
%%%% FMINCON
    options = optimset('MaxFunEvals',5000,'MaxIter',1000,'TolFun',0,'TolX',0);
    if q==1
        minimum = fmincon(@PronyErrorNT,zero,A,b,Aeq,beq,lb,ub,[],options);
    else
        minimum = fmincon(@PronyErrorNT,minimum,A,b,Aeq,beq,lb,ub,[],options);
    end
%%%% Results
    minvalues.E0 = E0;
    minvalues.Ei = minimum(1:NT);
    minvalues.taui = minimum(NT+1:NT+NT);
    PronyErrorNT(minimum);
    figure(q)
    semilogx(redtime,Erel_calc)
    hold on
    semilogx(redtime,relmod)
    xlabel('Reduced time (min)')
    ylabel('Relaxation modulus (MPa)')
    legend('model','experiment')
    hold off
    error = PronyErrorNT(minimum)
    para = minimum(:); % for later use or for saving the optimal result
    % (all results should always be saved with the same kind of name)
end
%end of minimisePronyErrorNT
