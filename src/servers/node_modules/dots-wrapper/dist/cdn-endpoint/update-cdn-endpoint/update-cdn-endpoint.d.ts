import { IResponse, IContext } from '../../types';
import { ICdnEndpoint } from '..';
export interface IUpdateCdnEndpointApiResponse {
    endpoint: ICdnEndpoint;
}
export interface IUpdateCdnEndpointApiRequest {
    cdn_endpoint_id: string;
    ttl?: number;
    certificate_id?: string;
    custom_domain?: string;
}
export type UpdateCdnEndpointResponse = IResponse<IUpdateCdnEndpointApiResponse>;
export declare const updateCdnEndpoint: ({ httpClient, }: IContext) => ({ cdn_endpoint_id, ttl, certificate_id, custom_domain, }: IUpdateCdnEndpointApiRequest) => Promise<Readonly<UpdateCdnEndpointResponse>>;
