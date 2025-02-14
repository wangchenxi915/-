function analyze_results(x_opt, power_output, reliability, params)
    % 创建图形窗口
    figure('Name', '海岛微电网优化结果', 'Position', [100, 100, 1200, 800]);
    
    % 1. 容量配置结果
    subplot(3,2,1);
    capacities = [x_opt(1), x_opt(2), x_opt(3), x_opt(4), x_opt(5), x_opt(6), x_opt(7)];
    bar(capacities);
    title('系统容量配置');
    set(gca, 'XTickLabel', {'光伏','风电','柴油','锂电池','电解槽','燃料电池','储氢'});
    ylabel('容量 (kW/kWh)');
    grid on;
    
    % 2. 典型夏季日出力曲线（选择7月15日）
    summer_day = 4345:4368;  % 7月15日
    subplot(3,2,2);
    plot(1:24, power_output.pv(summer_day), 'r-', ...
         1:24, power_output.wind(summer_day), 'b-', ...
         1:24, power_output.diesel(summer_day), 'k-', ...
         1:24, power_output.grid(summer_day), 'm-', 'LineWidth', 1.5);
    hold on;
    % 分别显示储能充放电
    battery_discharge = max(0, power_output.battery(summer_day));
    battery_charge = min(0, power_output.battery(summer_day));
    h2_discharge = power_output.h2_out(summer_day);
    h2_charge = -power_output.h2_in(summer_day);
    
    plot(1:24, battery_discharge, 'g-', 'LineWidth', 1.5);
    plot(1:24, battery_charge, 'g--', 'LineWidth', 1.5);
    plot(1:24, h2_discharge, 'c-', 'LineWidth', 1.5);
    plot(1:24, h2_charge, 'c--', 'LineWidth', 1.5);
    
    title('典型夏季日出力曲线');
    xlabel('时间 (h)');
    ylabel('功率 (kW)');
    legend('光伏','风电','柴油','电网','锂电池放电','锂电池充电',...
           '氢燃料电池放电','制氢充电','Location','eastoutside');
    grid on;
    
    % 3. 储能SOC变化
    subplot(3,2,3);
    plot(1:24, power_output.battery_soc(summer_day)/x_opt(4), 'g-', ...
         1:24, power_output.h2_soc(summer_day)/x_opt(7), 'c-', 'LineWidth', 1.5);
    title('储能SOC变化');
    xlabel('时间 (h)');
    ylabel('SOC');
    legend('锂电池SOC', '储氢SOC');
    grid on;
    ylim([0 1]);
    
    % 4. 负荷分析
    subplot(3,2,4);
    % 数据中心负荷和岛内常规负荷
    plot(1:24, params.dc_total_load * ones(24,1), 'r-', ...
         1:24, params.island_base_load * ones(24,1), 'b-', ...
         1:24, params.dc_total_load * ones(24,1) + params.island_base_load * ones(24,1), 'k--', ...
         'LineWidth', 1.5);
    title('系统负荷构成');
    xlabel('时间 (h)');
    ylabel('功率 (kW)');
    legend('数据中心负荷', '岛内常规负荷', '总负荷');
    grid on;
    
    % 5. 月度能量分析
    subplot(3,2,[5,6]);
    monthly_energy = calculate_monthly_energy(power_output);
    bar(monthly_energy/1000, 'stacked');  % 转换为MWh
    title('月度能量分析');
    xlabel('月份');
    ylabel('能量 (MWh)');
    legend('光伏','风电','柴油','电网购入','锂电池放电','氢燃料电池放电',...
           'Location','northoutside','Orientation','horizontal');
    grid on;
    
 % 输出关键指标
    fprintf('\n====== 系统优化结果 ======\n');
    fprintf('1. 容量配置：\n');
    fprintf('   光伏容量: %.2f kW\n', x_opt(1));
    fprintf('   风电容量: %.2f kW\n', x_opt(2));
    fprintf('   柴油机容量: %.2f kW\n', x_opt(3));
    fprintf('   锂电池容量: %.2f kWh\n', x_opt(4));
    fprintf('   电解槽容量: %.2f kW\n', x_opt(5));
    fprintf('   燃料电池容量: %.2f kW\n', x_opt(6));
    fprintf('   储氢容量: %.2f kg\n', x_opt(7));
    % 容量配置可视化
    subplot(3,2,1);
    capacities = [x_opt(1), x_opt(2), x_opt(3), x_opt(4), x_opt(5), x_opt(6), x_opt(7)];
    bar_h = bar(capacities);
    % 在柱状图上添加具体数值
    for i = 1:length(capacities)
        text(i, capacities(i), sprintf('%.2f', capacities(i)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
    title('系统容量配置');
    set(gca, 'XTickLabel', {'光伏','风电','柴油','锂电池','电解槽','燃料电池','储氢'});
    ylabel('容量 (kW/kWh/kg)');
    grid on;
    xtickangle(45);  % 倾斜x轴标签以防重叠

    fprintf('\n2. 系统性能指标：\n');
    fprintf('   供电可靠性: %.4f\n', reliability);
    renewable_gen = sum(power_output.pv + power_output.wind);
    total_gen = sum(power_output.pv + power_output.wind + power_output.diesel + ...
                   power_output.grid + power_output.h2_out);
    fprintf('   可再生能源渗透率: %.2f%%\n', 100*renewable_gen/total_gen);
    
   function analyze_results(x_opt, power_output, reliability, params)
    % ... 其他代码保持不变 ...
    
    fprintf('\n3. 年度能量分析：\n');
    fprintf('   光伏发电量: %.2f MWh\n', sum(power_output.pv)/1000);
    fprintf('   风电发电量: %.2f MWh\n', sum(power_output.wind)/1000);
    fprintf('   柴油发电量: %.2f MWh\n', sum(power_output.diesel)/1000);
    fprintf('   电网购电量: %.2f MWh\n', sum(power_output.grid)/1000);
    fprintf('   锂电池充电量: %.2f MWh\n', sum(abs(min(0,power_output.battery)))/1000);
    fprintf('   锂电池放电量: %.2f MWh\n', sum(max(0,power_output.battery))/1000);
    
    % 氢能系统分析
    total_h2_production = sum(power_output.h2_in) * params.electrolyzer_h2_rate;  % kg
    total_h2_consumption = sum(power_output.h2_out) * params.fc_h2_consumption;   % kg
    h2_to_power = sum(power_output.h2_out);  % kWh
    
    fprintf('   制氢量: %.2f kg\n', total_h2_production);
    fprintf('   耗氢量: %.2f kg\n', total_h2_consumption);
    fprintf('   氢燃料电池发电量: %.2f MWh\n', h2_to_power/1000);
    
    % 氢能系统效率分析
    fprintf('\n4. 氢能系统效率分析：\n');
    fprintf('   电解槽效率: %.2f%%\n', params.electrolyzer_efficiency * 100);
    fprintf('   燃料电池效率: %.2f%%\n', params.fc_efficiency * 100);
    fprintf('   系统往返效率: %.2f%%\n', params.h2_efficiency * 100);
    h2_energy_stored = total_h2_production * params.h2_energy_density;  % kWh
    fprintf('   储氢能量密度: %.2f kWh/kg\n', params.h2_energy_density);
    fprintf('   氢储能系统能量转换效率: %.2f%%\n', (h2_to_power/sum(power_output.h2_in))*100);
    
    % ... 其他代码保持不变 ...
end
    
    fprintf('\n4. 经济性分析：\n');
    annual_cost = calculate_annual_cost(x_opt, power_output, params);
    fprintf('   年化总成本: %.2f万元\n', annual_cost/10000);
    fprintf('   度电成本: %.2f元/kWh\n', annual_cost/sum(power_output.pv + power_output.wind + ...
            power_output.diesel + power_output.grid + power_output.h2_out));
end

function monthly_energy = calculate_monthly_energy(power_output)
    % 计算月度能量
    days_per_month = [31,28,31,30,31,30,31,31,30,31,30,31];
    monthly_energy = zeros(12, 6);  % [PV, Wind, Diesel, Grid, Battery, H2]
    hour_start = 1;
    
    for month = 1:12
        hours_in_month = days_per_month(month) * 24;
        hour_end = min(hour_start + hours_in_month - 1, 8760);
        hour_range = hour_start:hour_end;
        
        monthly_energy(month,1) = sum(power_output.pv(hour_range));
        monthly_energy(month,2) = sum(power_output.wind(hour_range));
        monthly_energy(month,3) = sum(power_output.diesel(hour_range));
        monthly_energy(month,4) = sum(power_output.grid(hour_range));
        monthly_energy(month,5) = sum(max(0,power_output.battery(hour_range)));
        monthly_energy(month,6) = sum(power_output.h2_out(hour_range));
        
        hour_start = hour_end + 1;
    end
end

function annual_cost = calculate_annual_cost(x_opt, power_output, params)
    % 投资成本
    investment_cost = x_opt(1)*params.pv_cost + x_opt(2)*params.wind_cost + ...
                     x_opt(3)*params.diesel_cost + x_opt(4)*params.battery_cost + ...
                     x_opt(5)*params.h2_cost + x_opt(6)*params.fc_cost + ...
                     x_opt(7)*params.h2_tank_cost;
    
    % 年化投资成本
    r = params.interest_rate;
    n = params.lifetime;
    crf = r*(1+r)^n/((1+r)^n-1);
    annual_investment = investment_cost * crf;
    
    % 运维成本
    annual_om = investment_cost * 0.02;
    
    % 燃料成本
    annual_fuel = sum(power_output.diesel) * params.diesel_price/3;
    
    % 电网购电成本
    grid_cost = sum(power_output.grid) * 0.8;  % 假设平均电价0.8元/kWh
    
    annual_cost = annual_investment + annual_om + annual_fuel + grid_cost;
end