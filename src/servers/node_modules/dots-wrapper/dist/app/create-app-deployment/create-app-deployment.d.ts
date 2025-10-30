import { IResponse, IContext } from '../../types';
import { IAppDeployment } from '..';
export interface ICreateAppDeploymentApiResponse {
    deployment: IAppDeployment;
}
export interface ICreateAppDeploymentApiRequest {
    app_id: string;
    force_build?: boolean;
}
export type CreateAppDeploymentResponse = IResponse<ICreateAppDeploymentApiResponse>;
export declare const createAppDeployment: ({ httpClient, }: IContext) => ({ app_id, force_build, }: ICreateAppDeploymentApiRequest) => Promise<Readonly<CreateAppDeploymentResponse>>;
