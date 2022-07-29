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
