clc;
clear;
base_algo = [];
min_algo = [];
for EV_count=[10 20 30 40 50]
    base_avg = 0;
    min_avg = 0;
    for itr=1:3
        T = 24;
        cs_del_capacity = 100 ; %R
        reg_price = rand(1,T); %at
        elec_price = [0.04921741;
        0.06635104;
        0.05469124;
        0.04867549;
        0.04361576;
        0.03636411;
        0.03338169;
        0.03001837;
        0.02966395;
        0.02925406;
        0.02952074;
        0.03153413;
        0.03627351;
        0.05047265;
        0.03441526;
        0.02829829;
        0.02567869;
        0.02133562;
        0.01965296;
        0.01343761;
        0.01209589;
        0.01430528;
        0.0197348;
        0.03304057]; %gt
        %elec_price = rand(1,T);
        efficiency = 0.8*ones(1,EV_count); %Ei


        start_time = 2*randn(1,EV_count)+6; %si
        end_time = 2*randn(1,EV_count)+19; %fi
        soc_initial = 0.6*rand(1,EV_count)+0.3; %ei
        soc_final = 0.9*ones(1,EV_count); %ei_dash
        upper_charging_limit = 4.4*ones(1,EV_count); % in kW
        lower_charging_limit = 3.3*ones(1,EV_count); % in kW
        M = 0.05;
        battery_capacities = 16.5*ones(1,EV_count); % in kWh (Ci)
        [y,soc_ev,cost,baseline_price] = min_cost(EV_count,T,cs_del_capacity,reg_price,elec_price,efficiency,start_time,end_time,soc_initial,soc_final,upper_charging_limit,lower_charging_limit,M,battery_capacities);
        base_avg = base_avg + baseline_price;
        min_avg = min_avg + cost;
    end
    base_algo(end+1) = base_avg/3;
    min_algo(end+1) = min_avg/3;
end
bar([10 20 30 40 50],[base_algo;min_algo])
legend('Baseline','Cost minimization algo','Location','Northwest')
xlabel('Number of EVs')
ylabel('Total cost to all customers (in $)')
title('Cost to customer comparison')