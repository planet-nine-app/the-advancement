import { IResponse, IContext } from '../../types';
export interface IDeleteCdnEndpointApiRequest {
    cdn_endpoint_id: string;
}
export type DeleteCdnEndpointResponse = IResponse<void>;
export declare const deleteCdnEndpoint: ({ httpClient, }: IContext) => ({ cdn_endpoint_id, }: IDeleteCdnEndpointApiRequest) => Promise<Readonly<DeleteCdnEndpointResponse>>;
