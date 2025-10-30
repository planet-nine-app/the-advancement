import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IApp } from '..';
export interface IListAppsApiResponse extends IListResponse {
    apps: IApp[];
}
export interface IListAppApiRequest extends IListRequest {
    with_projects?: boolean;
}
export type ListAppsResponse = IResponse<IListAppsApiResponse>;
export declare const listApps: ({ httpClient, }: IContext) => ({ page, per_page, with_projects, }: IListAppApiRequest) => Promise<Readonly<ListAppsResponse>>;
