function params = load_system_params()
    % 数据中心参数
    params.num_racks = 1000;            % 机柜数量
    params.rack_power = 5;              % 单机柜额定功率(kW)
    params.dc_total_load = params.num_racks * params.rack_power;  % 总负载
    params.important_load_ratio = 0.6;   % 重要负载比例
    params.dc_interactive_ratio = 0.7;   % 交互性负载比例
    params.dc_delay_ratio = 0.3;        % 延时性负载比例
    params.pue = 1.2;                   % 数据中心PUE
    params.bits_per_watt = 5;           % 比特-瓦特转换率
    params.island_base_load = 500;      % 岛内基础负载(kW)
    
    % 经济参数
    params.lifetime = 20;               % 项目寿命(年)
    params.interest_rate = 0.08;        % 利率
    params.pv_cost = 3800;             % 光伏单位投资成本(元/kW)
    params.wind_cost = 7500;           % 风机单位投资成本(元/kW)
    params.battery_cost = 1200;        % 储能单位投资成本(元/kWh)
    params.diesel_cost = 2500;         % 柴油机单位投资成本(元/kW)
    params.diesel_price = 8.5;         % 柴油价格(元/L)
    params.diesel_efficiency = 0.38;    % 柴油机效率
    params.diesel_fuel_rate = 0.22;    % 柴油机耗油率(L/kWh)
    
    % 锂电池储能参数
    params.battery_efficiency = 0.92;   % 储能充放电效率（单次）
    params.battery_min_soc = 0.15;     % 最小SOC
    params.battery_max_soc = 0.95;     % 最大SOC
    params.battery_lifetime = 10;       % 电池寿命(年)
    params.battery_om_ratio = 0.02;    % 电池年运维成本率
    params.battery_cycle_life = 4000;  % 循环寿命
    params.battery_depth_discharge = 0.8; % 放电深度
    
    % 氢能系统参数
    params.h2_cost = 12000;            % 电解槽投资成本(元/kW)
    params.fc_cost = 10000;            % 燃料电池投资成本(元/kW)
    params.h2_tank_cost = 600;         % 储氢罐投资成本(元/kg)
    params.h2_efficiency = 0.65;       % 氢储能系统往返效率
    params.electrolyzer_efficiency = 0.75;  % 电解槽效率
    params.fc_efficiency = 0.52;       % 燃料电池效率
    params.h2_min_soc = 0.15;         % 储氢系统最小储量比例
    params.h2_max_soc = 0.95;         % 储氢系统最大储量比例
    params.h2_lifetime = 15;           % 氢储能系统寿命(年)
    params.h2_om_ratio = 0.025;        % 氢储能年运维成本率
    params.h2_price = 35;              % 氢气价格(元/kg)
    
    % 氢能转换参数
     params.h2_energy_density = 33.33;   % 氢气能量密度(kWh/kg)
    params.electrolyzer_h2_rate = 0.0182;  % 电解槽制氢率(kg/kWh)
    params.fc_h2_consumption = 0.0312;   % 燃料电池耗氢率(kg/kWh)
    
    % 系统约束参数
    params.renewable_min_ratio = 0.75;  % 最小可再生能源渗透率
    params.reliability_target = 0.9999; % 目标供电可靠性
    params.max_outage_hours = 0.876;   % 最大年停电小时数(8760*0.0001)
    params.grid_max_power = 1200;      % 最大接入功率（kW）
    
    % 电网价格参数（海南电价）
    params.grid_price_peak = 1.2772;   % 峰时电价（元/kWh）
    params.grid_price_flat = 0.8008;   % 平时电价（元/kWh）
    params.grid_price_valley = 0.4004; % 谷时电价（元/kWh）
    params.feed_in_tariff = 0.4;       % 上网电价（元/kWh）
    
    % 分时电价时段
    params.peak_period = [8,9,10,11,12,13,14,15,16,17,18,19,20,21];  % 峰时段
    params.valley_period = [23,24,1,2,3,4,5,6];                      % 谷时段
    params.flat_period = [7,22];                                      % 平时段
    
    % 碳排放因子
    params.carbon_factor_grid = 0.8794;    % 电网碳排放因子(kg/kWh)
    params.carbon_factor_diesel = 2.778;   % 柴油碳排放因子(kg/kWh)
end