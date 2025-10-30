import { IResponse, IContext } from '../../types';
export interface IDeleteLoadBalancerApiRequest {
    load_balancer_id: string;
}
export type DeleteLoadBalancerResponse = IResponse<void>;
export declare const deleteLoadBalancer: ({ httpClient, }: IContext) => ({ load_balancer_id, }: IDeleteLoadBalancerApiRequest) => Promise<Readonly<DeleteLoadBalancerResponse>>;
