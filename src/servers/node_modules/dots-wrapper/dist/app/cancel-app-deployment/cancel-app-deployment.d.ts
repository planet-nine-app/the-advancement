import { IResponse, IContext } from '../../types';
import { IAppDeployment } from '..';
export interface ICancelAppDeploymentApiResponse {
    deployment: IAppDeployment;
}
export interface ICancelAppDeploymentApiRequest {
    app_id: string;
    deployment_id: string;
}
export type CancelAppDeploymentResponse = IResponse<ICancelAppDeploymentApiResponse>;
export declare const cancelAppDeployment: ({ httpClient, }: IContext) => ({ app_id, deployment_id, }: ICancelAppDeploymentApiRequest) => Promise<Readonly<CancelAppDeploymentResponse>>;
