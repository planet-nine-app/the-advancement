import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IProjectResource } from '../types';
export interface IListProjectResourcesApiResponse extends IListResponse {
    resources: IProjectResource[];
}
export interface IListProjectResourcesApiRequest extends IListRequest {
    project_id: string;
}
export type ListProjectResourcesResponse = IResponse<IListProjectResourcesApiResponse>;
export declare const listProjectResources: ({ httpClient, }: IContext) => ({ page, per_page, project_id, }: IListProjectResourcesApiRequest) => Promise<Readonly<ListProjectResourcesResponse>>;
