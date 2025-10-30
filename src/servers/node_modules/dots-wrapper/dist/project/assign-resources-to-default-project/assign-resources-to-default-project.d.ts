import { IResponse, IContext, IListResponse } from '../../types';
import { IProjectResource } from '..';
export interface IAssignResourcesToDefaultProjectApiRequest {
    resources: string[];
}
export interface IAssignResourcesToDefaultProjectApiResponse extends IListResponse {
    resources: IProjectResource[];
}
export type AssignResourcesToDefaultProjectResponse = IResponse<IAssignResourcesToDefaultProjectApiResponse>;
export declare const assignResourcesToDefaultProject: ({ httpClient, }: IContext) => ({ resources, }: IAssignResourcesToDefaultProjectApiRequest) => Promise<Readonly<AssignResourcesToDefaultProjectResponse>>;
