function p0 = sampleparams(lb,ub,n)
    % Transmission rates
    beta_si = unifrnd(lb(1),ub(1)); % S -> I [per day]
    beta_sa = unifrnd(lb(2),ub(2)); % S -> A [per day]
    
    % Lockdown effects
    eta_si = unifrnd(lb(3),ub(3)); % S -> I
    eta_sa = unifrnd(lb(4),ub(4)); % S -> A
    
    % Incubation period
    sigma_i = 1 / unifrnd(lb(5),ub(5)); % E -> I [days]
    
    % Latent period
    sigma_a = 1 / unifrnd(lb(6),ub(6)); % E -> I [days]
    
    % Infectivity period
    m = 1 / unifrnd(lb(7),ub(7)); % [days]
    
    % Recovery periods
    m_ar = 1 / unifrnd(lb(8),ub(8)); % A -> AR [days]
    chi = 1 / unifrnd(lb(9),ub(9)); % H -> R [days]
    
    % Period to deceased
    psi = 1 / unifrnd(lb(10),ub(10)); % H -> D [days]
    
    % Conversion fractions
    gamma = unifrnd(lb(11),ub(11)); % I -> H, I -> R
    omega = unifrnd(lb(12),ub(12)); % H -> D, H -> R
    
    % Initial population fractions
    e0i0 = unifrnd(lb(13),ub(13)); % Exposed/Infected
    a0i0 = unifrnd(lb(13),ub(13)); % Asymptomatic/Infected

    if 0 < omega && omega <= 1
        %disp('Condition 1 stable')
    elseif 1 < omega && chi < (psi * omega) / (omega - 1)
        %disp('Conditon 2 stable')
    else
        disp('Unstable')
    end

    p0 = [sigma_a, sigma_i, m_ar, m, gamma, omega, chi, psi, beta_sa / n, beta_si / n, eta_sa, eta_si, e0i0, a0i0];
end