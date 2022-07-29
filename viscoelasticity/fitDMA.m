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
