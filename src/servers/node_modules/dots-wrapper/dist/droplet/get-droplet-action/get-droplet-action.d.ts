import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IGetDropletActionApiRequest {
    action_id: string | number;
    droplet_id: number;
}
export interface IGetDropletActionApiResponse {
    action: IAction;
}
export type GetDropletActionResponse = IResponse<IGetDropletActionApiResponse>;
export declare const getDropletAction: ({ httpClient, }: IContext) => ({ action_id, droplet_id, }: IGetDropletActionApiRequest) => Promise<Readonly<GetDropletActionResponse>>;
