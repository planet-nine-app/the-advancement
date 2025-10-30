import { IResponse, IContext } from '../../types';
import { ILoadBalancer } from '..';
export interface IGetLoadBalancerApiResponse {
    load_balancer: ILoadBalancer;
}
export interface IGetLoadBalancerApiRequest {
    load_balancer_id: string;
}
export type GetLoadBalancerResponse = IResponse<IGetLoadBalancerApiResponse>;
export declare const getLoadBalancer: ({ httpClient, }: IContext) => ({ load_balancer_id, }: IGetLoadBalancerApiRequest) => Promise<Readonly<GetLoadBalancerResponse>>;
