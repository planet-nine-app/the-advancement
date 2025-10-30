import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IFloatingIP } from '..';
export interface IListFloatingIpsApiResponse extends IListResponse {
    floating_ips: IFloatingIP[];
}
export type ListFloatingIpssResponse = IResponse<IListFloatingIpsApiResponse>;
export declare const listFloatingIps: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListFloatingIpssResponse>>;
