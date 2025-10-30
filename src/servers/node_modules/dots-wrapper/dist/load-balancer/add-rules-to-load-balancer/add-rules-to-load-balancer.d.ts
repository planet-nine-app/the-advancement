import { IResponse, IContext } from '../../types';
import { IForwardingRule } from '..';
export interface IAddRulesToLoadBalancerApiRequest {
    forwarding_rules: IForwardingRule[];
    load_balancer_id: string;
}
export type AddRulesToLoadBalancerResponse = IResponse<void>;
export declare const addRulesToLoadBalancer: ({ httpClient, }: IContext) => ({ forwarding_rules, load_balancer_id, }: IAddRulesToLoadBalancerApiRequest) => Promise<Readonly<AddRulesToLoadBalancerResponse>>;
