% PURPOSE:
%        Restricted likelihood for use in the DCC_MVGARCH estimation and
%        returns the likelihood of the 2SQMLE estimates of the DCC parameters
% 
% USAGE:
%        [logL, Rt, likelihoods]=dcc_mvgarch_likelihood(params, stdresid, P, Q)
% 
% INPUTS:
%    params      = A Q+P by 1 vector of parameters of the form [dccPparameters;dccQparameters]
%    stdresid    = A matrix, t x k of residuals standardized by their conditional standard deviation
%    Q           = The innovation order of the DCC Garch process
%    P           = The AR order of the DCC estimator
% 
% OUTPUTS:
%    logL        = The calculate Quasi-Likelihood
%    Rt          = a k x k x t a 3 dimensional array of conditional correlations
%    likelihoods = a t by 1 vector of quasi likelihoods
%    Qt          = a k x k x t a 3 dimensional array of conditional correlations on stdresid
% 
% 
% COMMENTS:
% 
% Modifications: Sylvain Benoit    Date Revision: 17/09/2014
% Initial codes Author: Kevin Sheppard
% kevin.sheppard@economics.ox.ac.uk
% Revision: 3    Date: 4/1/2004

function [logL, Rt, likelihoods, Qt]=dcc_mvgarch_likelihood(params, stdresid, Q, P)

[t,k]=size(stdresid);   %t renvoie le nb de lignes de stdresid et k le nb de colonnes;
a=params(1:Q);          %r�cup�re l'initialisation de la composante DCC_ARCH;
b=params(Q+1:Q+P);      %r�cup�re l'initialisation de la composante DCC_GARCH;
sumA=sum(a);            %il fait la somme pour ne pas estimer le alpha0 de l'�qua du DCC;
sumB=sum(b);            %il fait la somme pour ne pas estimer le alpha0 de l'�qua du DCC;

% First compute Qbar, the Unconditional Correlation Matrix
Qbar=cov(stdresid);

% Next compute Qt
m=max(Q,P);                             %r�cup�re le nb de retard maximum pour avoir exactement t observations

Qt=zeros(k,k,t+m);                      %initialisation de Qt avec que des 0 [k by k by t+m];
Rt=zeros(k,k,t+m);                      %initialisation de Rt avec que des 0 [k by k by t+m];
Qt(:,:,1:m)=repmat(Qbar,[1 1 m]);       %seulement la premi�re matrice de Qt qui est initialiser par Qbar
Rt(:,:,1:m)=repmat(Qbar,[1 1 m]);       %seulement la premi�re matrice de Rt qui est initialiser par Qbar

logL=0;                                 %initialisation de la logL � 0
likelihoods=zeros(1,t+m);               %initialisation des t+m lignes de likelihoods � 0

%The stdresid have expected value 1 maybe but in the variances
stdresid=[zeros(m,k);stdresid];         %avec le ; �a nous donne une concat�nation verticale des deux matrices, sans le ; ce serait une concat�nation horizontale;

for j=(m+1):t+m
     Qt(:,:,j)=Qbar*(1-sumA-sumB);   
   for i=1:Q
     Qt(:,:,j)=Qt(:,:,j) + a(i)*(stdresid(j-i,:)'*stdresid(j-i,:));
   end
   for i=1:P
     Qt(:,:,j)=Qt(:,:,j) + b(i)*Qt(:,:,j-i);
   end
     Rt(:,:,j)=Qt(:,:,j)./(sqrt(diag(Qt(:,:,j)))*sqrt(diag(Qt(:,:,j)))'); %pourquoi le prime? ne sert � pas grand chose!;
     likelihoods(j)=log(det(Rt(:,:,j))) + stdresid(j,:)*inv(Rt(:,:,j))*stdresid(j,:)'; %calcul de la vraisemblance sur chaque observation du N-�chantillons, c'est que la vraismeblance du DCC
     logL=logL + likelihoods(j);            %somme au fur et � mesure pour avoir la log-vraisemblance;
end;

Qt=Qt(:,:,(m+1:t+m));                   %output de Qt matrix [k by k by t]
Rt=Rt(:,:,(m+1:t+m));                   %output de Rt matrix [k by k by t]
logL=(1/2)*logL;                        %c'est �a l'objectif, c'est ce que l'on veut minimiser, Attention, on cherche le minimun car Max(LL)=Min(-LL)!!!
likelihoods=(1/2)*likelihoods(m+1:t+m); %on calcule la vrai forme r�duite avec le 1/2