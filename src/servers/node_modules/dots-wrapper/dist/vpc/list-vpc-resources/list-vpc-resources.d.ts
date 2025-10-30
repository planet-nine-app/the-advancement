import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IVpcResource } from '../types';
export interface IListVpcResourcesApiResponse extends IListResponse {
    members: IVpcResource[];
}
export interface IListVpcResourcesApiRequest extends IListRequest {
    resource_type?: string;
    vpc_id: string;
}
export type ListVpcResourcesResponse = IResponse<IListVpcResourcesApiResponse>;
export declare const listVpcResources: ({ httpClient, }: IContext) => ({ page, per_page, resource_type, vpc_id, }: IListVpcResourcesApiRequest) => Promise<Readonly<ListVpcResourcesResponse>>;
