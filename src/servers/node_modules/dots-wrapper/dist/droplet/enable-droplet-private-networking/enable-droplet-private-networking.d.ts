import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IEnableDropletPrivateNetworkingApiResponse {
    action: IAction;
}
export interface IEnableDropletPrivateNetworkingApiRequest {
    droplet_id: number;
}
export type EnableDropletPrivateNetworkingResponse = IResponse<IEnableDropletPrivateNetworkingApiResponse>;
export declare const enableDropletPrivateNetworking: ({ httpClient, }: IContext) => ({ droplet_id, }: IEnableDropletPrivateNetworkingApiRequest) => Promise<Readonly<EnableDropletPrivateNetworkingResponse>>;
