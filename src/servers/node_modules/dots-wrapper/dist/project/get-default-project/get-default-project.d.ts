import { IResponse, IContext } from '../../types';
import { IProject } from '..';
export interface IGetDefaultProjectApiResponse {
    project: IProject;
}
export type GetDefaultProjectResponse = IResponse<IGetDefaultProjectApiResponse>;
export declare const getDefaultProject: ({ httpClient, }: IContext) => () => Promise<Readonly<GetDefaultProjectResponse>>;
