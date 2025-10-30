import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IAppDeployment } from '..';
export interface IListAppDeploymentsApiResponse extends IListResponse {
    deployments: IAppDeployment[];
}
export interface IListAppDeploymentsApiRequest extends IListRequest {
    app_id: string;
}
export type ListAppDeploymentsResponse = IResponse<IListAppDeploymentsApiResponse>;
export declare const listAppDeployments: ({ httpClient, }: IContext) => ({ app_id, page, per_page, }: IListAppDeploymentsApiRequest) => Promise<Readonly<ListAppDeploymentsResponse>>;
