import { IResponse, IContext } from '../../types';
import { IAppDeployment } from '..';
export interface IGetAppDeploymentApiResponse {
    deployment: IAppDeployment;
}
export interface IGetAppDeploymentApiRequest {
    app_id: string;
    deployment_id: string;
}
export type GetAppDeploymentResponse = IResponse<IGetAppDeploymentApiResponse>;
export declare const getAppDeployment: ({ httpClient, }: IContext) => ({ app_id, deployment_id, }: IGetAppDeploymentApiRequest) => Promise<Readonly<GetAppDeploymentResponse>>;
