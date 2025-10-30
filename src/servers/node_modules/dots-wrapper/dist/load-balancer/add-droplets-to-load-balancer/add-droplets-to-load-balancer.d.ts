import { IResponse, IContext } from '../../types';
export interface IAddDropletsToLoadBalancerApiRequest {
    droplet_ids: number[];
    load_balancer_id: string;
}
export type AddDropletsToLoadBalancerResponse = IResponse<void>;
export declare const addDropletsToLoadBalancer: ({ httpClient, }: IContext) => ({ droplet_ids, load_balancer_id, }: IAddDropletsToLoadBalancerApiRequest) => Promise<Readonly<AddDropletsToLoadBalancerResponse>>;
