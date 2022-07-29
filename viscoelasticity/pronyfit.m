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
