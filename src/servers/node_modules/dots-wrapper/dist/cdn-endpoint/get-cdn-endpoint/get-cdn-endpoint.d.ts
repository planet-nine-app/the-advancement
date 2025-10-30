import { IResponse, IContext } from '../../types';
import { ICdnEndpoint } from '..';
export interface IGetCdnEndpointApiResponse {
    endpoint: ICdnEndpoint;
}
export interface IGetCdnEndpointApiRequest {
    cdn_endpoint_id: string;
}
export type GetCdnEndpointResponse = IResponse<IGetCdnEndpointApiResponse>;
export declare const getCdnEndpoint: ({ httpClient, }: IContext) => ({ cdn_endpoint_id, }: IGetCdnEndpointApiRequest) => Promise<Readonly<GetCdnEndpointResponse>>;
