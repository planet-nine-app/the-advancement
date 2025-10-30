import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IRebootDropletApiResponse {
    action: IAction;
}
export interface IRebootDropletApiRequest {
    droplet_id: number;
}
export type RebootDropletResponse = IResponse<IRebootDropletApiResponse>;
export declare const rebootDroplet: ({ httpClient, }: IContext) => ({ droplet_id, }: IRebootDropletApiRequest) => Promise<Readonly<RebootDropletResponse>>;
