import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IDomain } from '..';
export interface IListDomainsApiResponse extends IListResponse {
    domains: IDomain[];
}
export type ListDomainsResponse = IResponse<IListDomainsApiResponse>;
export declare const listDomains: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListDomainsResponse>>;
