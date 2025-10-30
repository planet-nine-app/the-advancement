import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IProjectResource } from '../types';
export interface IListDefaultProjectResourcesApiResponse extends IListResponse {
    resources: IProjectResource[];
}
export type ListDefaultProjectResourcesResponse = IResponse<IListDefaultProjectResourcesApiResponse>;
export declare const listDefaultProjectResources: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListDefaultProjectResourcesResponse>>;
