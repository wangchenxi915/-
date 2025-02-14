function [solar_data, wind_data, load_data] = load_environmental_data(params)
    hours = 8760;
    
    % 生成时间序列
    hour_of_day = mod((0:hours-1)', 24) + 1;
    day_of_year = ceil((1:hours)'/24);
    month = ceil(day_of_year/30.44);
    
    % 生成太阳能数据（向量化计算）
    solar_data = zeros(hours, 1);
    daytime = hour_of_day >= 6 & hour_of_day <= 18;
    solar_data(daytime) = sin(pi*(hour_of_day(daytime)-6)/12);
    
    % 季节和天气影响
    season_factor = 1 + 0.2*sin(2*pi*(month-6)/12);
    weather_factor = 0.8 + 0.2*rand(hours, 1);
    solar_data = solar_data .* season_factor .* weather_factor;
    
    % 生成风能数据
    shape = 2.2;  % Weibull分布参数
    scale = 10;
    wind_speeds = wblrnd(scale, shape, hours, 1);
    
    % 风速转换为功率
    wind_data = zeros(hours, 1);
    valid_wind = wind_speeds >= 3 & wind_speeds <= 25;
    wind_data(valid_wind) = (wind_speeds(valid_wind) - 3)/(12 - 3);
    wind_data(wind_speeds > 12 & wind_speeds <= 25) = 1;
    
    % 生成负荷数据（向量化计算以提高速度）
    load_data = generate_load_profile_vectorized(hours, params);
end

function load_data = generate_load_profile_vectorized(hours, params)
    % 生成时间序列
    hour_of_day = mod((0:hours-1)', 24) + 1;
    day_of_year = ceil((1:hours)'/24);
    month = ceil(day_of_year/30.44);
    weekday = mod(day_of_year-1, 7) + 1;  % 1-7表示周一到周日
    
    % 数据中心负荷生成
    % 1. 日内波动
    dc_daily_pattern = 0.15 * sin(2*pi*(hour_of_day-8)/24) + ...
                      0.1 * sin(4*pi*(hour_of_day-12)/24);
    
    % 2. 周内波动
    dc_weekly_pattern = 1 - 0.2 * (weekday >= 6);
    
    % 3. 季节波动
    dc_seasonal_pattern = 0.2 * sin(2*pi*(month-6)/12);
    
    % 4. 随机波动
    dc_random = 0.1 * randn(hours, 1);
    
    % 合成数据中心负载
    dc_base_load = params.dc_total_load * 0.7;  % 基础负载
    dc_variable_load = params.dc_total_load * 0.3;  % 可变负载
    dc_load = dc_base_load + dc_variable_load * (1 + dc_daily_pattern + ...
              dc_seasonal_pattern + dc_random) .* dc_weekly_pattern;
    
    % 岛内常规负荷生成
    % 1. 日内双峰模式
    island_daily_pattern = 0.4 * sin(2*pi*(hour_of_day-8)/24) + ...
                          0.3 * sin(2*pi*(hour_of_day-18)/24);
    
    % 2. 周内波动
    island_weekly_pattern = 1 - 0.15 * (weekday >= 6);
    
    % 3. 季节波动（夏冬负载大）
    island_seasonal_pattern = 0.3 * cos(4*pi*(month-6)/12);
    
    % 4. 随机波动
    island_random = 0.15 * randn(hours, 1);
    
    % 合成岛内负载
    island_load = params.island_base_load * (1 + island_daily_pattern + ...
                 island_seasonal_pattern + island_random) .* island_weekly_pattern;
    
    % 合并总负载并确保非负
    load_data = max(0, dc_load + island_load);
    
    % 添加节假日效应
    holiday_hours = get_holiday_hours();
    load_data(holiday_hours) = load_data(holiday_hours) * 0.8;
    
    % 添加突发性波动（模拟特殊事件）
    num_events = 20;  % 年度特殊事件数量
    min_duration = 4;
    max_duration = 12;
    
    for i = 1:num_events
        start_hour = randi([1, hours - max_duration]);
        duration = randi([min_duration, max_duration]);
        magnitude = 1 + 0.3 * randn();  % 波动幅度
        event_hours = start_hour:min(start_hour+duration-1, hours);
        load_data(event_hours) = load_data(event_hours) * magnitude;
    end
    
    % 确保负载在合理范围内
    min_load = 0.6 * (params.dc_total_load + params.island_base_load);
    max_load = 1.4 * (params.dc_total_load + params.island_base_load);
    load_data = max(min_load, min(max_load, load_data));
end

function holiday_hours = get_holiday_hours()
    % 定义主要节假日的小时索引
    holiday_hours = [];
    
    % 元旦（1月1-3日）
    holiday_hours = [holiday_hours; (1:3*24)'];
    
    % 春节（假设1月20-25日）
    holiday_hours = [holiday_hours; (19*24+1:25*24)'];
    
    % 清明（4月4-6日）
    holiday_hours = [holiday_hours; (93*24+1:96*24)'];
    
    % 劳动节（5月1-3日）
    holiday_hours = [holiday_hours; (120*24+1:123*24)'];
    
    % 端午（假设6月11-13日）
    holiday_hours = [holiday_hours; (161*24+1:164*24)'];
    
    % 中秋（假设9月7-9日）
    holiday_hours = [holiday_hours; (249*24+1:252*24)'];
    
    % 国庆（10月1-7日）
    holiday_hours = [holiday_hours; (273*24+1:280*24)'];
end