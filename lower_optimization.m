function [reliability, power_output] = lower_optimization(x, params, solar_data, wind_data, load_data)
    hours = length(solar_data);
    
    % 初始化输出
    power_output = struct('pv', zeros(hours,1), ...
                         'wind', zeros(hours,1), ...
                         'diesel', zeros(hours,1), ...
                         'battery', zeros(hours,1), ...
                         'grid', zeros(hours,1), ...
                         'h2_in', zeros(hours,1), ...
                         'h2_out', zeros(hours,1), ...
                         'battery_soc', zeros(hours,1), ...  % 添加SOC输出
                         'h2_soc', zeros(hours,1));         % 添加氢储能SOC输出
    
    % 提取容量参数
    pv_cap = x(1);
    wind_cap = x(2);
    diesel_cap = x(3);
    battery_cap = x(4);
    electrolyzer_cap = x(5);
    fc_cap = x(6);
    h2_cap = x(7);
    
    % 初始化储能状态
    battery_soc = 0.5 * battery_cap;
    h2_soc = 0.5 * h2_cap;
   
    % 计算可用可再生能源
    pv_available = pv_cap * solar_data;
    wind_available = wind_cap * wind_data;
    
    % 优化每个时段
    for t = 1:hours
        % 记录当前SOC
        power_output.battery_soc(t) = battery_soc;
        power_output.h2_soc(t) = h2_soc;
        
        % 计算当前负载
        current_load = load_data(t);
        
        % 优先使用可再生能源
        power_output.pv(t) = min(pv_available(t), current_load);
        remaining_load = current_load - power_output.pv(t);
        
        power_output.wind(t) = min(wind_available(t), remaining_load);
        remaining_load = remaining_load - power_output.wind(t);
        
        % 计算多余可再生能源
        excess_power = max(0, pv_available(t) + wind_available(t) - current_load);
        
        % 储能策略
        if remaining_load > 0
            % 放电策略：优先使用锂电池，然后是氢储能
            if battery_soc > params.battery_min_soc * battery_cap
                max_battery_discharge = (battery_soc - params.battery_min_soc * battery_cap) * params.battery_efficiency;
                battery_discharge = min(remaining_load, max_battery_discharge);
                power_output.battery(t) = battery_discharge;
                battery_soc = battery_soc - battery_discharge/params.battery_efficiency;
                remaining_load = remaining_load - battery_discharge;
            end
            
            if remaining_load > 0 && h2_soc > params.h2_min_soc * h2_cap
                max_h2_discharge = min(fc_cap, (h2_soc - params.h2_min_soc * h2_cap) * params.fc_efficiency);
                h2_discharge = min(remaining_load, max_h2_discharge);
                power_output.h2_out(t) = h2_discharge;
                h2_soc = h2_soc - h2_discharge/params.fc_efficiency;
                remaining_load = remaining_load - h2_discharge;
            end
        elseif excess_power > 0
            % 充电策略：优先充锂电池，多余电量用于制氢
            if battery_soc < params.battery_max_soc * battery_cap
                max_battery_charge = (params.battery_max_soc * battery_cap - battery_soc)/params.battery_efficiency;
                battery_charge = min(excess_power, max_battery_charge);
                power_output.battery(t) = -battery_charge;
                battery_soc = battery_soc + battery_charge * params.battery_efficiency;
                excess_power = excess_power - battery_charge;
            end
            
            if excess_power > 0 && h2_soc < params.h2_max_soc * h2_cap
                max_h2_charge = min(electrolyzer_cap, (params.h2_max_soc * h2_cap - h2_soc)/params.electrolyzer_efficiency);
                h2_charge = min(excess_power, max_h2_charge);
                power_output.h2_in(t) = h2_charge;
                h2_soc = h2_soc + h2_charge * params.electrolyzer_efficiency;
            end
        end
        
        % 电网和柴油机补充
        if remaining_load > 0
            power_output.grid(t) = min(remaining_load, params.grid_max_power);
            remaining_load = remaining_load - power_output.grid(t);
            power_output.diesel(t) = remaining_load;
        end
    end
    
    % 计算可靠性
    total_supply = sum(power_output.pv + power_output.wind + power_output.diesel + ...
                      abs(power_output.battery) + power_output.grid + ...
                      power_output.h2_out - power_output.h2_in);
    total_demand = sum(load_data);
    reliability = min(1, total_supply/total_demand);
end