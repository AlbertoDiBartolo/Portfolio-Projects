%{
PronyErrorNT v1.1 by Alberto Di Bartolo
This function is used to fit experimental master curves to Prony series
(see Generalised Maxwell Model) primarely for
stress relaxation master curve. It calculates the error between
experimental values of a Master Curve and values calculated from the
multi-branch model with NT non-equi branches. It needs the values of
reduced time and the viscoelastic property as two column vectors properly
named in the workspace, and the number of total n.e. branches NT. It
takes vector var as Input, this is the vector containing the values of
moduli and relaxation times. It outputs the sum of squared errors
calculated at the time points; the error is calcualted as

                  error(i) = Calc_value(i)/Real_value(i) - 1

The function is handled to a fmincon based minimisation script, presently
named minimisePronyErrorNT, which will find the optimal solution for the
fitting
%}
function error_tot = PronyErrorNT(var)
NT = 14; % n.e. branches (user input) (should be the same as in minimisePronyErrorNT)
load MC33C_genericTref.mat % load experimental data to fit. time var  
% should be named "redtime" and modulus should be named "relmod"
E0 = relmod(end); % value of rubbery plateau
Evec = var(1:NT); % elastic moduli in branches
tauvec = var(NT+1:NT+NT); % relax times vector
Eloop=zeros(1,NT); % preallocates a vector used in the loop
Erel_calc = zeros(size(redtime)); % preallocates calculated values
errors = zeros(size(redtime)); % preallocates errors
%{
% Now we calculate the modulus at time(i)
%
%                          NT
%     Erel_calc(i) = E0 + SUM ( Evec(j)*exp( -time(i)/tauvec(j) ) )
%                         j=1
% 
%}
for i=1:numel(redtime)
    for j=1:NT
        Eloop(j) =  Evec(j).*exp(-redtime(i)./tauvec(j)); % for time(i),
        % calculate each Evec*exp(-t/tau) and store the value in the vector
        % Eloop
    end
Erel_calc(i) = E0 + sum(Eloop); % summ all the values in Eloop and add E0
errors(i) = (Erel_calc(i)./relmod(i)-1).^2; % calculate the error at time(i)
end
error_tot = sum(errors);
% make sure the values are in the base workspace by assigning them
assignin('base','redtime',redtime);
assignin('base','relmod',relmod);
assignin('base','Erel_calc',Erel_calc);
end
% end of PronyErrorNT


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


%{
LSQFitNT v1.2 by Alberto Di Bartolo
This function is used to simultaneously fit the Storage Modulus and Tand
curves obtained from DMA temperature sweep to the multi-branch model with
NT number of non equilibrium branches.
The function output is a matrix that contains two column vectors, one of
the Storage modulus error (calculated - experimental) and the other of the
tand errors (cal - exp). The input is var, vector containing the reference
temperature, TTS parameters, moduli and relaxation times for the branches.
There is a correct order for the data in var and it is:
Tref,WLF1,WLF2,ARR,E0,Evec,tauvec
with:

Tref reference temperature (optimised by the script)
WLF1 WLF equation C1 (optimised by script)
WLF2 WLF equation C2 (optimised by script)
ARR AFc/kb the Arrhenius equation slope (optimised by script)
E0 rubbery plateau (script will get it from the data)
Evec vector with NT elements for the NT moduli
tauvec vector with NT elements for the NT relaxation times

This function should be handled to a different script called
minimise_LSQFitNT that will minimise the error in a least square sense.
The experimental data are required in the workspace or there should be a
.mat containing them that can be loaded (see load command later in script).
Also the data should be named: temperature, storage, tandelta. And be in
column vector form
%}
function total_error = LSQFitNT(var)
NT = 14; % # of non-equi branches (should be the same as in minimise_LSQFitNT)
% temperature intervals for (simplistically) weighting the errors if desired
tempLeft = 37; % left of tan delta peak
tempRight = 52; % right of tan delta peak
tempOnset = 27; % onset of tan delta
A = 100; % tand weight
B = 1; % mod weight
C = 1000; % tand weight
D = 1; % mod weight
E = 1000; % tand weight
F = 1; % mod weight
load YuetAl_tempRamp_DATA.mat % load data
temp_data = temperature; Estor_data = storage; tand_data = tandelta;
Tref = var(1); % the reference temperature
WLF1 = var(2); % WLF equation paramter
WLF2 = var(3); % WLF equation paramter
ARR = var(4); % Arrhenius equation parameter
E0 = var(5); % value of rubbery plateau
Evec = var(6:(5+NT)); % vector of NT elastic moduli
tauvec = var((5+NT+1):(5+NT+NT)); % vector of NT relaxation times at Tref
w = 1; % frequency
% Preallocate
at=zeros(size(temperature));
Estor_calc=zeros(size(temperature));
Estor_loop=zeros(1,NT);
Eloss_loop=zeros(1,NT);
Eloss_calc=zeros(size(temperature));
tand_calc=zeros(size(temperature));
errors_tand=zeros(size(temperature));
errors_storage=zeros(size(temperature));
%{
for each value of temperature temp_data(i):
calcualte the shifting factor (at) from WLF or ARR
calculate the storage modulus as:

                   NT
  Estor(i) = E0 + SUM ( Evec(j)*((w*tauvec(j)*at(i))^2)/(1+(w*tauvec(j)*at(i))^2) )
                  j=1

calculate the loss modulus as:

           NT
  Eloss = SUM ( Evec(j)*(w*tauvec(j)*at(i))/(1+(w*tauvec(j)*at(i))^2) )
          j=1 

calculate the tan delta from the ratio
%}
for i = 1:numel(temp_data)
    %calc shift factor at T(i)
    if temp_data(i) >= Tref
        at(i) = 10.^((-WLF1).*(temp_data(i) - Tref)./(WLF2 + temp_data(i) - Tref)); % WLF
    else
        at(i) = exp((-ARR).*(1./(273.15 + temp_data(i))-1./(Tref + 273.15))); % Arrhenius
    end
    %calculate E' and E'' and tandelta at T(i)
    for j=1:NT
        Estor_loop(j)=Evec(j).*((w.*tauvec(j).*at(i)).^2)./(1+(w.*tauvec(j).*at(i)).^2);
        Eloss_loop(j)=Evec(j).*((w.*tauvec(j).*at(i)))./(1+(w.*tauvec(j).*at(i)).^2);
    end
    Estor_calc(i)=sum(Estor_loop)+E0;
    Eloss_calc(i)=sum(Eloss_loop);
    tand_calc(i)=Eloss_calc(i)./Estor_calc(i);
    %calculate error at T(i)
    if 0 < temp_data(i) < tempOnset
%     errors_tand(i) = A.*(tand_calc(i)./tand_data(i) - 1); % in percentage
%     errors_storage(i) = B.*(Estore_calc(i)./Estore_data(i) - 1); % in percentage
    errors_tand(i) = A.*(tand_calc(i) - tand_data(i));
    errors_storage(i) = B.*(Estor_calc(i) - Estor_data(i));
    elseif tempLeft < temp_data(i) < tempRight
%     errors_tand(i) = C.*(tand_calc(i)./tand_data(i) - 1); % in percentage
%     errors_storage(i) = D.*(Estore_calc(i)./Estore_data(i) - 1); % in percentage
    errors_tand(i) = C.*(tand_calc(i) - tand_data(i));
    errors_storage(i) = D.*(Estor_calc(i) - Estor_data(i));
    else
%     errors_tand(i) = E.*(tand_calc(i)./tand_data(i) - 1); % in percentage
%     errors_storage(i) = F.*(Estore_calc(i)./Estore_data(i) - 1); % in percentage
    errors_tand(i) = E.*(tand_calc(i) - tand_data(i));
    errors_storage(i) = F.*(Estor_calc(i) - Estor_data(i));
    end
end
total_error = [errors_tand errors_storage];
assignin('base','temperature',temp_data);
assignin('base','modulusCalculatedValues',Estor_calc);
assignin('base','tandeltaCalculatedValues',tand_calc);
assignin('base','modulusExperimentalValues',Estor_data);
assignin('base','tandeltaExperimentalValues',tand_data);
assignin('base','shift',at);
end
% end of LSQFitNT.m


%{
minimise_LSQFitNT v1.2 by Alberto Di Bartolo
This script is used together with LSQFitNT.m to fit the storage modulus and
tan delta curve obtained from temperature sweep. Using the multi-branch
model with a number of branch equal to NT (user defined).
The data to be provided is experimental values of storage modulus and tan
delta vs temperature. These should be in three column vectors named
storage, temperature, tandelta. They either get automatically loaded from a
file.mat or they should already be in the workspace.
This script doesn't guide the user through each setting, most settings are
changed by commenting out parts of the main body.
PARAMETERS EXPLANATION AND UNITS TO BE USED
  E0 [MPa] the value of modulus in the rubbery plateau froma temperature
  sweep test, it's the elastic modulus in the equilibrium branch of the
  multi-branch model
  w [Hz] frequency used during experiment, this is usually 1 
  WLF1 [N.D.] WLF first parameter (the one at the numerator) usually around
  17.44 for many polymers when reference temperatuer is taken as Tg
  WLF2 [ºC] WLF second parameter (the one at the denominator) usually
  around 51.6 ºC for many polymers when reference temperature is taken as Tg
  ARR [K] is the parameter often shown as A*Fc/kb in the Arrhenius equation
  Tref [ºC] is the reference temperature
  Etot [MPa] is the sum of all Ei and Eeq and can be taken as the storage
  modulus value in the glassy plateau from the temperature sweep test
%}
close all
tic
NT = 14; % number of branches
first_tau = -4; % the smallest value of tau is equal to 10^(first_tau)
divdec = 1; % the decades will be spaced 10^1/divdec, e.g. divdec=2 gives 10^-1 10^-0.5 etc
dataname = 'YuetAl_tempRamp_DATA'; % name of file.mat containing data
load(dataname)

% User is asked some questions
% prevent pop-up figures if requested
answer = questdlg('Disable figures pop-up?');
switch answer
    case 'Yes'
        popup = 'off';
    case 'No'
        popup = 'on';
    case 'Cancel'
        popup = 'on';        
end
repeat = inputdlg('How many repetition would you like to perform?','Repetition number',[1 50],{'10'}); % ask how many rep to do
repeat = str2double(repeat);
for q=1:(repeat) % repeat with different starting point
%% BUILD STARTING POINT (vector called zero)
Trefzero = 27;
WLF1zero = 17;
WLF2zero = 51;
ARRzero = -40000;

% some extra options
% ARRvec = [1000 2500 5000 8000 10000 15000 20000 30000 50000 100000];
% ARRzero = -ARRvec(q);
% Randomise the first 4 zero variables in a certain range
% Trefzero = randi([0 80]);
% WLF1zero = randi([0 200]);
% WLF2zero = randi([0 200]);
% ARRzero = -randi([0 100000]);

E0 = storage(end); % experimental value
Etot = max(storage); % experimental value
zero(1) = Trefzero;
zero(2) = WLF1zero;
zero(3) = WLF2zero;
zero(4) = ARRzero;
zero(5) = E0;
% Preparations to make moduli starting vector
% Comment one out
% #1 log spaced moduli values
% utility=logspace(NT-1,0,NT); utility=utility/sum(utility);
% #2 rand descending moduli values
utility=rand(1,NT); utility=utility/sum(utility); utility=sort(utility,'descend');
zero(6:(5+NT))=utility.*(Etot-E0); % moduli starting vector that adds up to Etot-E0
zero((5+NT+1):(5+NT+NT))= logspace(0,NT-1,NT); % logspaced relax times starting vector
startpoint(q,:) = zero; % save all the different starting points
w = 1; % the experiment frequency is 1 for most cases
%% LOWER AND UPPER BOUNDARIES (vectors lb and ub)
% set VARlb = VARub to lock VAR to a certain value
% Use the following lines when locking some or all of the first 4 variables
% (just to be faster when trying different solutions)
% Treflb = 41.79;
% Trefub = Treflb;
% WLF1lb = 8.93;
% WLF1ub = WLF1lb;
% WLF2lb = 12.14;
% WLF2ub = WLF2lb;
% ARRlb = -21376;
% ARRub = ARRlb;
Treflb = 0;
Trefub = 60;
WLF1lb = 0;
WLF1ub = 200;
WLF2lb = 0;
WLF2ub = 200;
ARRlb = -inf;
ARRub = -0;
E0lb = E0; % always locked
E0ub = E0; % always locked
% lb and ub vectors for moduli
Elb = zeros(1,NT);
Eub = ones(1,NT).*(Etot-E0);
% Elb = (Etot-E0).*[0.0155072589960000,0.0164636583970000,0.0232598285600000,0.0537082505910000,0.0959710010890000,0.00628448746500000,0.0713863758390000,0.0945220830900000,0.219784137749000,0.293955045635000,0.0956485316750000,0.0118989071750000,0.00112735556900000,0.000483078170000000];
% Eub=Elb;
% Eub = ones(1,NT).*Inf;
% lb and ub vectors for relax times
taulb = logspace(first_tau,NT/divdec-1/divdec+first_tau,NT);
% taulb = zeros(1,NT);
% taulb = ones(1,NT).*0.001;
tauub = taulb;
% tauub = ones(1,NT).*1e14;
% compose lower and upper boundaries vectors
lb = [Treflb,WLF1lb,WLF2lb,ARRlb,E0lb,Elb,taulb];
ub = [Trefub,WLF1ub,WLF2ub,ARRub,E0ub,Eub,tauub];
% lb = minimum; ub=minimum;
% lb(4)=-inf; ub(4)=0;
%% Functions: comment out to choose function/options
% options = optimset('MaxFunEvals',3000,'MaxIter',1000); % standard Tolerance
% options = optimset('MaxFunEvals',100000,'MaxIter',5000,'TolFun',0,'TolX',0); % zero tolerance
% minimum = lsqnonlin(@LSQFitNT,zero,lb,ub,options);
[minimum,resnorm] = lsqnonlin(@LSQFitNT,zero,lb,ub);
%% OUTPUT
% this creates a strut called minvalues
optimal(:,q) = minimum;
minvalues.Tref = minimum(1);
minvalues.WLF1 = minimum(2);
minvalues.WLF2 = minimum(3);
minvalues.ARR = minimum(4);
minvalues.E0 = minimum(5);
minvalues.Evec = minimum(6:(5+NT));
minvalues.tauvec = minimum((5+NT+1):(5+NT+NT));
% error = LSQFitStorage(minimum);
disp(minvalues)
disp(q)
disp(resnorm)
% disp(error)
%% PLOTS - the model curves are plotted against the experimental curves
figurename = [dataname,'_OPTIMISED_',num2str(q),'.png'];
f = figure('visible',popup);
% f = figure('visible','off');
plot(temperature,modulusCalculatedValues,'r--');
% semilogy(temperature,modulusCalculatedValues,'k--');
xlabel('Temperature (ºC)'); ylabel('Storage Modulus (MPa)'); ylim([1 storage(1).*1.15]); xlim([0 temperature(end)+10]);
hold on;
plot(temperature,modulusExperimentalValues,'k-');
% semilogy(temperature,modulusExperimentalValues,'k-');
legend('model','experiment');
yyaxis right
plot(temperature,tandeltaCalculatedValues,'r--'); ylabel('tan\delta');
plot(temperature,tandeltaExperimentalValues,'k-');
legend('model','experiment');
%% SAVE FIGURE in .png - DISABLE TO IMPROVE PERFORMANCE
% saveas(f,figurename);
% print('Plot','-dpng');
% % % end
%% RESULTS - disable to save time
% error = ; % funtion(minimum)
% mincol = transpose(minimum);
% start = transpose(zero);
% lower = transpose(lb);
% upper = transpose(ub);
% TgData = temperature(find(tandeltaExperimentalValues==max(tandeltaExperimentalValues)));
% TgCalc = temperature(find(tandeltaCalculatedValues==max(tandeltaCalculatedValues)));
% result(1:5+NT+NT,1) = start; result(1:(5+NT+NT),2) = mincol;
% result(1:(5+NT+NT),3) = lower; result(1:(5+NT+NT),4) = upper;
% result((5+NT+NT+1),2) = NaN; result((5+NT+NT+1),1) = NaN;
% result((5+NT+NT+2),2) = TgCalc;
% result((5+NT+NT+3),2) = TgData;
% result((5+NT+NT+4),2) = TgData-TgCalc;
% result((5+NT+NT+1):(5+NT+NT+4),1) = NaN; result((5+NT+NT+1):(5+NT+NT+4),3:4) = NaN;
%% EXPORT RESULTS TO EXCEL - DISABLE TO IMPROVE PERFORMANCE
%% export results to excel sheet (NT = 7)
% rows = {'Tref';'WLF1';'WLF2';'ARR';'E0';'E1';'E2';'E3';'E4';'E5';'E6';'E7';'tauref1';'tauref2';'tauref3';'tauref4';'tauref5';'tauref6';'tauref7';'error';'TgCalc';'TgData';'Tgerr'};
% LOG = table(rows,result(:,1),result(:,2),result(:,3),result(:,4),'VariableNames',{'name' 'zero' 'min' 'LB' 'UB'});
% filename = [dataname,'_OPTIMISED_',num2str(q),'.xlsx'];
% writetable(LOG,filename);
%% export results to excel sheet (NT = 14)
% rows = {'Tref';'WLF1';'WLF2';'ARR';'E0';'E1';'E2';'E3';'E4';'E5';'E6';'E7';'E8';'E9';'E10';'E11';'E12';'E13';'E14';'tauref1';'tauref2';'tauref3';'tauref4';'tauref5';'tauref6';'tauref7';'tauref8';'tauref9';'tauref10';'tauref11';'tauref12';'tauref13';'tauref14';'error';'TgCalc';'TgData';'Tgerr'};
% LOG = table(rows,result(:,1),result(:,2),result(:,3),result(:,4),'VariableNames',{'name' 'zero' 'min' 'LB' 'UB'});
% filename = [dataname,'_OPTIMISED_',num2str(q),'.xlsx'];
% writetable(LOG,filename);
%
end % of repeat
%
% elapsed time
toc
elapsedTime = toc;
% choose best min
prompt = 'Which solution would you like to use as optimal parameters set? (scroll up to see all possible solutions)';
solnumb = input(prompt);
disp(['You picked solution ',num2str(solnumb)])
para = optimal(:,solnumb);
% would you like to clear all vars except for para ans save as?
if repeat>1
answer = questdlg('Would you like to clear all variables except for para? (dataname and NT cannot be cleared)');
    switch answer
        case 'Yes'
        clearvars -except para dataname NT optimal
        case 'No'
        case 'Cancel'
    end
else
end
answer = questdlg(['Would you like to save as ' dataname,'_OPTIMISED_',num2str(NT),'.mat (if file already exists I will ask you before overwriting)']);
if exist([dataname,'_OPTIMISED_',num2str(NT),'.mat'], 'file') == 0
    switch answer
        case 'Yes'
            save ([dataname,'_OPTIMISED_',num2str(NT)])
        case 'No'
        case 'Cancel'
    end
else
answer = questdlg('File already exists, would you like to overwrite it?');
    switch answer
        case 'Yes'
            save ([dataname,'_OPTIMISED_',num2str(NT)])
        case 'No'
            for ii=2:10
                if  exist([dataname,'_OPTIMISED_',num2str(NT),'_0',num2str(ii),'.mat'],'file')==2
                    
                else
                    save([dataname,'_OPTIMISED_',num2str(NT),'_0',num2str(ii)]);
                    msgbox(['File saved as ',dataname,'_OPTIMISED_',num2str(NT),'_0',num2str(ii),'.mat'])
                    ['File saved as ',dataname,'_OPTIMISED_',num2str(NT),'_0',num2str(ii),'.mat']
                    break
                end
            end
        case 'Cancel'
    end
end
%% END
