import { IResponse, IContext } from '../../types';
import { IProject } from '..';
export interface IUpdateProjectApiResponse {
    project: IProject;
}
export interface IUpdateProjectApiRequest {
    description: string;
    environment: string;
    is_default: boolean;
    name: string;
    project_id: string;
    purpose: string;
}
export type UpdateProjectResponse = IResponse<IUpdateProjectApiResponse>;
export declare const updateProject: ({ httpClient, }: IContext) => ({ description, environment, is_default, name, project_id, purpose, }: IUpdateProjectApiRequest) => Promise<Readonly<UpdateProjectResponse>>;
