% Clear windows and workspace
clear
clc
close all

%% Problem Definition
% Population
n = 2695598; % Total population

% Known initial conditions
i0 = 99; % Infected
h0 = 44; % Hospitalized
d0 = 2; % Deceased

% Initial Ratios
e0i0 = 1; % Exposed/Infected
a0i0 = 0.5; % Asymptomatic/Infected

% Calculate initial conditions for other compartments
e0 = e0i0 * i0; % Exposed
a0 = a0i0 * i0; % Asymptomatic

ar0 = 0; % Asymptomatic recovered
r0 = 0; % Recovered

s0 = n - (e0 + a0 + ar0 + i0 + h0 + r0 + d0); % Susceptible

% Initial conditions vector
y0 = [s0, e0, a0, ar0, i0, h0, r0, d0];

%% Observed Data
% Load time, total cases, and total deaths
[t, Cobs, Dobs] = loadData();

% Convert to a single vector
Yobs = [Cobs(:); Dobs(:)];

%% Model Solution
% Define optimization iterations
iters = 10;

% Initialize estimate vectors
beta_is = rndSample([0,1],iters); % Transmission rate, S -> I
beta_as = rndSample([0,1],iters); % Transmission rate, S -> A
sigma_a = 1./rndSample([2,7],iters); % Latent period, E -> A
sigma_i = 1./rndSample([2,7],iters); % Incubation period, E -> A
m = 1./rndSample([5,12],iters); % Infectivity period
m_ar = 1./rndSample([5,12],iters); % Recovery period, A -> AR
chi = 1./rndSample([5,20],iters); % Recovery period, H -> R
psi = 1./rndSample([5,20],iters); % Period to deseased, H -> D
gamma = rndSample([0.25,0.75],iters); % Conversion fraction, I -> H, I -> D
omega = rndSample([0.1,0.5],iters); % Conversion fraction, H -> D, H -> R

e0i0 = rndSample([1,6],iters); % Initial Exposed/Infected
a0i0 = rndSample([1,6],iters); % Initial Asymptotic/Infected

% Fixed Parameters
mu = 5.79e-07;

% Divide beta by n for ODE model
beta_is = beta_is./n;
beta_as = beta_as./n;

% Initialize estimate vectors
[beta_as_est, beta_is_est, sigma_a_est, sigma_i_est, m_ar_est, m_est, gamma_est, omega_est, chi_est, psi_est] = deal(zeros(1,iters));

% Sample each initial condition
for i=1:iters
    % Initial parameter guess vector
    p0 = [beta_as(i), beta_is(i), sigma_a(i), sigma_i(i), m_ar(i), m(i), gamma(i), omega(i), chi(i), psi(i)];

    % Generate parameter estimate
    options = optimset('MaxFunEvals',80,'PlotFcns',@optimplotfval);
    [pEst,fminres] = fminsearch(@(p)objfun(t,Yobs,p,mu,y0),p0,options);

    % Assign parameter estimates to vectors
    beta_as_est(i) = pEst(1);
    beta_is_est(i) = pEst(2);
    sigma_a_est(i) = pEst(3);
    sigma_i_est(i) = pEst(4);
    m_ar_est(i) = pEst(5);
    m_est(i) = pEst(6);
    gamma_est(i) = pEst(7);
    omega_est(i) = pEst(8);
    chi_est(i) = pEst(9);
    psi_est(i) = pEst(10);
end

% Calculate median values
beta_as_med = median(beta_as_est);
beta_is_med = median(beta_is_est);
sigma_a_med = median(sigma_a_est);
sigma_i_med = median(sigma_i_est);
m_ar_med = median(m_ar_est);
m_med = median(m_est);
gamma_med = median(gamma_est);
omega_med = median(omega_est);
chi_med = median(chi_est);
psi_med = median(psi_est);

%% Present Results
% Create parameter vector
p = [beta_as_med, beta_is_med, mu, sigma_a_med, sigma_i_med, m_ar_med, m_med, gamma_med, omega_med, chi_med, psi_med];

% Solve with median estimated parameters
[~,Y] = ode45(@(t,y)sir(t,y,p),t,y0);

% Convert to system vectors
s = Y(:,1);
e = Y(:,2);
a = Y(:,3);
ar = Y(:,4);
i = Y(:,5);
h = Y(:,6);
r = Y(:,7);
d = Y(:,8);

% Define total cases and deaths
Cnum = i + h + r + d;
Dnum = d;

%% Plot results
figure() %total cases plot
plot(t,Cobs,'k.',t,Cnum,'b-')
legend('$C_{obs}(t)$','$C_{num}(t)$','Interpreter','latex','Location','southeast')
xlabel('$t$ (days from March 17)','interpreter','latex')
ylabel('$C(t)$','interpreter','latex')
set(gca, 'TickLabelInterpreter','latex')

figure() %total deaths plot
plot(t,Dobs,'k.',t,Dnum,'b-') %total deaths plot
legend('$D_{obs}(t)$','$D_{num}(t)$','Interpreter','latex','Location','southeast')
xlabel('$t$ (days from March 17)','interpreter','latex')
ylabel('$D(t)$','interpreter','latex')
set(gca, 'TickLabelInterpreter','latex')

%% Functions
% Model
function dydt = sir(~,y,p)
    % Derivatives with respect to time
    s = y(1);
    e = y(2);
    a = y(3);
    i = y(5);
    h = y(6);

    % System parameters
    beta_sa = p(1);
    beta_si = p(2);
    sigma_a = p(3);
    sigma_i = p(4);
    m_ar = p(5);
    m = p(6);
    gamma = p(7);
    omega = p(8);
    chi = p(9);
    psi = p(10);
    mu = p(11);
    
    % Define system
    dydt = [
        -beta_sa * s * a - beta_si * s * i - mu * s;
        beta_sa * s * a + beta_si * s * i - (sigma_a + sigma_i) * e;
        sigma_a * e - m_ar * a;
        m_ar * a;
        sigma_i * e - m * i;
        gamma * m * i - (1 - omega) * chi * h - omega * psi * h;
        (1 - gamma) * m * i + (1 - omega) * chi * h;
        omega * psi * h;
        ];
end

% Objective function
function obj = objfun(trange,Yobs,p,mu,y0)
    % Attach mu to paramter vector
    p = [p, mu];
    % Compute solution vector
    [~,y] = ode45(@(t,y)sir(t,y,p),trange,y0);
   
    % Convert to system vectors
    i = y(:,5);
    h = y(:,6);
    r = y(:,7);
    d = y(:,8);

    % Define numerical cases and deaths
    Cnum = i + h + r + d;
    Dnum = d;

    % Convert to a single vector
    Ynum = [Cnum(:); Dnum(:)];

    % Compute objective function
    obj = norm(Ynum - Yobs);
end

% Import time series data
function [time, cases, deceased] = loadData()
    % Import the time series csv file
    series = load('local-model/time_series.csv');

    % Redefine the variables for readability
    cases = series(:,1)';
    deceased = series(:,2)';

    % Create time steps
    time = 1:length(cases);
end

% Initial values sampling
function r = rndSample(range,n)
    a = range(1);
    b = range(2);
    r = (b-a).*rand(n,1) + a;
end