import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IProject } from '..';
export interface IListProjectsApiResponse extends IListResponse {
    projects: IProject[];
}
export type ListProjectsResponse = IResponse<IListProjectsApiResponse>;
export declare const listProjects: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListProjectsResponse>>;
