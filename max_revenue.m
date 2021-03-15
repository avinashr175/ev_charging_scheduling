function [y,soc_ev,obj,baseline_revenue] = max_revenue(EV_count,T,cs_del_capacity,reg_price,elec_price,efficiency,cost_upper_bound,start_time,end_time,soc_initial,soc_final,upper_charging_limit,lower_charging_limit,M,battery_capacities)
h = zeros(EV_count,T);
for i=1:EV_count
    for t=1:T
        if(t>floor(start_time(i)) && t<floor(end_time(i)) )
            h(i,t) = 1;
        elseif(t==floor(start_time(i)) && start_time(i)==floor(start_time(i)) )
            h(i,t) = 1;
        elseif(t==floor(start_time(i)) && start_time(i)~=floor(start_time(i)))
            h(i,t) = ceil(start_time(i)) - start_time(i);
        elseif(t==floor(end_time(i)) && end_time(i)~=floor(end_time(i)))
            h(i,t) = end_time(i) - floor(end_time(i));
        else
            h(i,t) = 0;
        end
    end
end

cvx_begin
    variable charging_rate(EV_count,T);
    variable regulation_capacity(EV_count,T);
    variable soc_ev(EV_count,T);
    variable u(EV_count,T);
    variable d(EV_count,T);
    variable delta binary;
    
    obj = 0;
    for t=1:T
        x = 0;
        for i=1:EV_count
            obj = obj + M*charging_rate(i,t)*h(i,t);
            x = x+regulation_capacity(i,t);
        end
        %obj = obj + reg_price(t)*x;
    end
    cost_to_cust = 0;
    maximize(obj)
    subject to
    for i=1:EV_count
        soc_ev(i,min(ceil(end_time(i)),T)) == soc_final(i);
    end
    
    for t=1:T
        
        for i=1:EV_count
            charging_rate(i,t)>=0;
            charging_rate(i,t)<=upper_charging_limit(i);
            cost_to_cust = cost_to_cust + charging_rate(i,t)*h(i,t);
            if(h(i,t)==1)
                u(i,t) == charging_rate(i,t)-lower_charging_limit(i);
                %d(i,t) == min((soc_final(i)-soc_ev(i,t))*battery_capacities(i)/efficiency(i),upper_charging_limit(i))-charging_rate(i,t);
                d(i,t) == upper_charging_limit(i)-charging_rate(i,t); 
            else
                u(i,t) == 0;
                d(i,t) == 0;
            end
            regulation_capacity(i,t) == u(i,t)+d(i,t);
            %soc_ev(i,t) <= soc_final(i);
            if(t==floor(start_time(i)))
                soc_ev(i,t) == soc_initial(i);
            elseif(t<floor(start_time(i)))
                soc_ev(i,t)==0;
                %charging_rate(i,t)==0;
            else
                if(t>1)
                    soc_ev(i,t) == soc_ev(i,t-1)+efficiency(i)*h(i,t-1)*charging_rate(i,t-1)/battery_capacities(i);
                    
                end
                
%                 soc_ev(i,t)>=soc_final(i)-1.2*(1-delta);
%                 soc_ev(i,t)<=soc_final(i)+1.2*delta;
%                 -1.2*(1-delta)<=h(i,t)<=1.2*delta;
            
            end
            soc_ev(i,t) <= soc_final(i);
        end
        cost_to_cust = cost_to_cust*(M+elec_price(t));
        sum(charging_rate(:,t).*h(:,t)) <= cs_del_capacity;
    end
    cost_to_cust<=cost_upper_bound;
    
        
cvx_end

y = charging_rate.*sign(h);
% 
% 
% %%%%%%%% unregulated charging scheme (first come first serve)
charging_rates2 = zeros(EV_count,T);
charging_lim = 4.4;
soc_ev2 = zeros(EV_count,T);
[out,idx] = sort(start_time);
for t=1:T
    c = 0;
    for i=idx
        if(c>=cs_del_capacity)
            break
        end
        
        if(t==floor(start_time(i)))
            soc_ev2(i,t) = soc_initial(i);
            charging_rates2(i,t) = min(charging_lim,cs_del_capacity-c);
            c = c + charging_rates2(i,t);
        else
            if(t>1 && t>floor(start_time(i)))
                soc_ev2(i,t) = min(soc_final(i),soc_ev2(i,t-1)+efficiency(i)*h(i,t-1)*charging_rates2(i,t-1)/battery_capacities(i));
                if(soc_ev2(i,t)>=soc_final(i))
                    charging_rates2(i,t)=0;
                    continue
                end
                charging_rates2(i,t) = min(charging_lim,cs_del_capacity-c);
                c = c + charging_rates2(i,t);
            end
        end
    end
end

baseline_revenue = sum(sum(M*charging_rates2.*elec_price'));
end


