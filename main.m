% 海岛微电网双层规划主程序
clear all; clc; close all;

% 加载系统参数
params = load_system_params();

% 加载环境数据（8760小时）
[solar_data, wind_data, load_data] = load_environmental_data(params);

% 显示负荷曲线
hours = 8760;  % 定义总小时数

% 创建负荷曲线分析图
figure('Name', '负荷曲线分析');

% 典型日负荷曲线（夏季）
subplot(2,1,1);
typical_day = 180*24+1:180*24+24;  % 选择第180天
plot(1:24, load_data(typical_day), 'b-', 'LineWidth', 1.5);
title('典型夏季日负荷曲线');
xlabel('时间 (h)');
ylabel('负荷 (kW)');
grid on;

% 年度负荷曲线
subplot(2,1,2);
plot((1:hours)', load_data, 'b-', 'LineWidth', 1);
title('年度负荷曲线');
xlabel('时间 (h)');
ylabel('负荷 (kW)');
grid on;

% 定义上层优化变量边界
% [PV容量(kW), 风机容量(kW), 柴油机容量(kW), 锂电池容量(kWh), 
%  电解槽容量(kW), 燃料电池容量(kW), 储氢容量(kg)]
lb_upper = [2800, 2200, 600, 3500, 800, 800, 300];   % 最小容量
ub_upper = [5500, 4500, 1200, 6000, 1800, 1800, 900]; % 最大容量

% 定义PSO参数
options = struct(...
    'SwarmSize', 100, ...       % 增加种群大小
    'MaxIterations', 200, ...   % 增加迭代次数
    'FunctionTolerance', 1e-8, ... % 提高收敛精度
    'w', 0.7, ...              % 惯性权重
    'c1', 1.5, ...             % 个体学习因子
    'c2', 1.5);                % 群体学习因子子

% 运行优化
tic;
[x_opt, fval] = fast_pso(@(x)upper_objective(x, params, solar_data, wind_data, load_data),...
    7, lb_upper, ub_upper, options);

% 获取最优解的详细结果
[reliability, power_output] = lower_optimization(x_opt, params, solar_data, wind_data, load_data);

% 结果分析和可视化
analyze_results(x_opt, power_output, reliability, params);

optimization_time = toc;
fprintf('优化总耗时: %.2f秒\n', optimization_time);

% 打印负荷特征
fprintf('\n负荷特征分析：\n');
fprintf('平均负荷：%.2f kW\n', mean(load_data));
fprintf('最大负荷：%.2f kW\n', max(load_data));
fprintf('最小负荷：%.2f kW\n', min(load_data));
fprintf('负荷标准差：%.2f kW\n', std(load_data));
fprintf('峰谷比：%.2f\n', max(load_data)/min(load_data));