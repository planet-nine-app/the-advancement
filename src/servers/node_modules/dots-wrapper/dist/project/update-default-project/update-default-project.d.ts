import { IResponse, IContext } from '../../types';
import { IProject } from '..';
export interface IUpdateDefaultProjectApiResponse {
    project: IProject;
}
export interface IUpdateDefaultProjectApiRequest {
    description: string;
    environment: string;
    is_default: boolean;
    name: string;
    purpose: string;
}
export type UpdateDefaultProjectResponse = IResponse<IUpdateDefaultProjectApiResponse>;
export declare const updateDefaultProject: ({ httpClient, }: IContext) => ({ description, environment, is_default, name, purpose, }: IUpdateDefaultProjectApiRequest) => Promise<Readonly<UpdateDefaultProjectResponse>>;
