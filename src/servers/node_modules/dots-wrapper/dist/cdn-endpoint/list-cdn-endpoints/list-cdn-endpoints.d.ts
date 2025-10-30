import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ICdnEndpoint } from '..';
export interface IListCdnEndpointsApiResponse extends IListResponse {
    endpoints: ICdnEndpoint[];
}
export type ListCdnEndpointsResponse = IResponse<IListCdnEndpointsApiResponse>;
export declare const listCdnEndpoints: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListCdnEndpointsResponse>>;
