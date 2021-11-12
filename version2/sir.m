function dydt = sir(t,y,p,t_q)
% SIR   SIR model function.

    % Derivatives with respect to time
    s = y(1);
    e = y(2);
    a = y(3);
    i = y(5);
    h = y(6);
    
    % System parameters
    % Optimized parameters (p vector)
    alpha_a = p(1);
    alpha_i = p(2);
    eta_a = p(3);
    eta_i = p(4);
    lambda_a = p(5);
    lambda_i = p(6);
    xi = p(7);
    gamma = p(8);
    omega = p(9);
    theta = p(10);
    kappa = p(11);
    
    % Calculate time dependent betas
    alpha_i_t = betafun([alpha_i,eta_i],t_q,t);
    alpha_a_t = betafun([alpha_a,eta_a],t_q,t);

    % Define system
    dydt = [
        -alpha_a_t .* (s * a) - alpha_i_t .* (s * i); % s_t
        alpha_a_t .* (s * a) + alpha_i_t .* (s * i) - (lambda_a + lambda_i) * e; % e_t
        lambda_a * e - xi * a; % a_t
        xi * a; % ar_t
        lambda_i * e - i; % i_t
        gamma * i - (1 - omega) * theta * h - omega * kappa * h; % h_t
        (1 - gamma) * i + (1 - omega) * theta * h % r_t
        ];
end