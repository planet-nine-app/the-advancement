import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IShutdownDropletApiResponse {
    action: IAction;
}
export interface IShutdownDropletApiRequest {
    droplet_id: number;
}
export type ShutdownDropletResponse = IResponse<IShutdownDropletApiResponse>;
export declare const shutdownDroplet: ({ httpClient, }: IContext) => ({ droplet_id, }: IShutdownDropletApiRequest) => Promise<Readonly<ShutdownDropletResponse>>;
