function [total_cost] = upper_objective(x, params, solar_data, wind_data, load_data)
    % 计算投资成本
    investment_cost = x(1)*params.pv_cost + x(2)*params.wind_cost + ...
                     x(3)*params.diesel_cost + x(4)*params.battery_cost + ...
                     x(5)*params.h2_cost + x(6)*params.fc_cost + ...
                     x(7)*params.h2_tank_cost;
    
    % 计算运维成本和系统运行结果
    [reliability, power_output] = lower_optimization(x, params, solar_data, wind_data, load_data);
    
    % 年运维成本（加入氢储能）
    annual_om_cost = x(1)*params.pv_cost*0.02 + x(2)*params.wind_cost*0.02 + ...
                    x(3)*params.diesel_cost*0.03 + x(4)*params.battery_cost*0.02 + ...
                    (x(5)*params.h2_cost + x(6)*params.fc_cost + x(7)*params.h2_tank_cost)*params.h2_om_ratio;
    
    % 燃料成本
    % 燃料成本计算
annual_fuel_cost = sum(power_output.diesel) * params.diesel_fuel_rate * params.diesel_price;
    
    % 电网购电成本
    grid_cost = calculate_grid_cost(power_output.grid, params);
    
    % 计算NPV
    r = params.interest_rate;
    n = params.lifetime;
    crf = r*(1+r)^n/((1+r)^n-1);  % 资金回收系数
    
    annual_cost = annual_om_cost + annual_fuel_cost + grid_cost;
    total_cost = investment_cost + annual_cost/crf;
    
   % 计算约束违反惩罚
    penalty = 0;
    
    % 可再生能源渗透率约束
    renewable_gen = sum(power_output.pv + power_output.wind);
    total_gen = sum(power_output.pv + power_output.wind + power_output.diesel + ...
                   power_output.grid + power_output.h2_out);
    renewable_ratio = renewable_gen/total_gen;
    if renewable_ratio < params.renewable_min_ratio
        penalty = penalty + 1e7 * (params.renewable_min_ratio - renewable_ratio);
    end
    
    % 供电可靠性约束
    if reliability < params.reliability_target
        penalty = penalty + 1e7 * (params.reliability_target - reliability);
    elseif reliability == 1  % 惩罚100%可靠性
        penalty = penalty + 1e5;
    end
    
    % 容量约束
    total_renewable = x(1) + x(2);  % 光伏+风电
    if total_renewable < 1.2 * params.dc_total_load  % 可再生能源总容量应大于负载的1.2倍
        penalty = penalty + 1e6;
    end
    
    % 储能容量约束
    if x(4) < 0.3 * params.dc_total_load * 4  % 锂电池至少支撑4小时30%负载
        penalty = penalty + 1e6;
    end
    
    if x(7) < 0.2 * params.dc_total_load * 8  % 储氢至少支撑8小时20%负载
        penalty = penalty + 1e6;
    end
    
    total_cost = total_cost + penalty;
end

function grid_cost = calculate_grid_cost(grid_power, params)
    hours = length(grid_power);
    grid_cost = 0;
    
    for h = 1:hours
        hour_of_day = mod(h-1, 24) + 1;
        if ismember(hour_of_day, params.peak_period)
            price = params.grid_price_peak;
        elseif ismember(hour_of_day, params.valley_period)
            price = params.grid_price_valley;
        else
            price = params.grid_price_flat;
        end
        grid_cost = grid_cost + grid_power(h) * price;
    end
end