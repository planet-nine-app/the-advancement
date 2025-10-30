import { IResponse, IContext } from '../../types';
import { IForwardingRule } from '..';
export interface IRemoveRulesFromLoadBalancerApiRequest {
    forwarding_rules: IForwardingRule[];
    load_balancer_id: string;
}
export type RemoveRulesFromLoadBalancerResponse = IResponse<void>;
export declare const removeRulesFromLoadBalancer: ({ httpClient, }: IContext) => ({ forwarding_rules, load_balancer_id, }: IRemoveRulesFromLoadBalancerApiRequest) => Promise<Readonly<RemoveRulesFromLoadBalancerResponse>>;
