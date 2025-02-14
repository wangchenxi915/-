function [x_opt, fval] = fast_pso(obj_fun, nvars, lb, ub, options)
    % 提取参数
    swarm_size = options.SwarmSize;
    max_iter = options.MaxIterations;
    ftol = options.FunctionTolerance;
    w = options.w;
    c1 = options.c1;
    c2 = options.c2;
    
    % 初始化
    positions = lb + (ub - lb) .* rand(swarm_size, nvars);
    velocities = (ub - lb) .* (rand(swarm_size, nvars) - 0.5) * 0.1;
    
    % 评估初始种群
    fitness = zeros(swarm_size, 1);
    for i = 1:swarm_size
        fitness(i) = obj_fun(positions(i,:));
    end
    
    pbest = positions;
    pbest_fitness = fitness;
    [gbest_fitness, idx] = min(fitness);
    gbest = positions(idx,:);
    
    % 主循环
    w_max = w;
    w_min = 0.4;
    for iter = 1:max_iter
        % 动态惯性权重
        w = w_max - (w_max - w_min) * iter / max_iter;
        
        for i = 1:swarm_size
            % 更新速度
            r1 = rand(1, nvars);
            r2 = rand(1, nvars);
            
            velocities(i,:) = w * velocities(i,:) + ...
                            c1 * r1 .* (pbest(i,:) - positions(i,:)) + ...
                            c2 * r2 .* (gbest - positions(i,:));
            
            % 限制速度
            velocities(i,:) = min(max(velocities(i,:), -0.1*(ub-lb)), 0.1*(ub-lb));
            
            % 更新位置
            positions(i,:) = positions(i,:) + velocities(i,:);
            positions(i,:) = min(max(positions(i,:), lb), ub);
            
            % 评估新位置
            fitness(i) = obj_fun(positions(i,:));
            
            % 更新个体最优
            if fitness(i) < pbest_fitness(i)
                pbest_fitness(i) = fitness(i);
                pbest(i,:) = positions(i,:);
                
                % 更新全局最优
                if fitness(i) < gbest_fitness
                    gbest_fitness = fitness(i);
                    gbest = positions(i,:);
                end
            end
        end
        
        % 显示进度
        if mod(iter, 10) == 0
            fprintf('迭代次数: %d, 最优值: %.2f\n', iter, gbest_fitness);
        end
        
        % 收敛检查
        if iter > 20 && std(fitness) < ftol
            break;
        end
    end
    
    x_opt = gbest;
    fval = gbest_fitness;
end