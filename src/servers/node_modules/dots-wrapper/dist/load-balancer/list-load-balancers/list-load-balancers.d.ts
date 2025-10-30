import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ILoadBalancer } from '..';
export interface IListLoadBalancersApiResponse extends IListResponse {
    load_balancers: ILoadBalancer[];
}
export type ListLoadBalancersResponse = IResponse<IListLoadBalancersApiResponse>;
export declare const listLoadBalancers: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListLoadBalancersResponse>>;
