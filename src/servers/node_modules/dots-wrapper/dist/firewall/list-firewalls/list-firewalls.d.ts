import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IFirewall } from '..';
export interface IListFirewallsApiResponse extends IListResponse {
    firewalls: IFirewall[];
}
export type ListFirewallsResponse = IResponse<IListFirewallsApiResponse>;
export declare const listFirewalls: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListFirewallsResponse>>;
