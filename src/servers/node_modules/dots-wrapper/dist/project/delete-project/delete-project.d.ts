import { IResponse, IContext } from '../../types';
export interface IDeleteProjectApiRequest {
    project_id: string;
}
export type DeleteProjectResponse = IResponse<void>;
export declare const deleteProject: ({ httpClient, }: IContext) => ({ project_id, }: IDeleteProjectApiRequest) => Promise<Readonly<DeleteProjectResponse>>;
