import { IResponse, IContext } from '../../types';
export interface IRemoveDropletsFromLoadBalancerApiRequest {
    droplet_ids: number[];
    load_balancer_id: string;
}
export type RemoveDropletsFromLoadBalancerResponse = IResponse<void>;
export declare const removeDropletsFromLoadBalancer: ({ httpClient, }: IContext) => ({ droplet_ids, load_balancer_id, }: IRemoveDropletsFromLoadBalancerApiRequest) => Promise<Readonly<RemoveDropletsFromLoadBalancerResponse>>;
