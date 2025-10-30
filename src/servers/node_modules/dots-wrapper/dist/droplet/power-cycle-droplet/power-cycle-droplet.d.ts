import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IPowerCycleDropletApiResponse {
    action: IAction;
}
export interface IPowerCycleDropletApiRequest {
    droplet_id: number;
}
export type PowerCycleDropletResponse = IResponse<IPowerCycleDropletApiResponse>;
export declare const powerCycleDroplet: ({ httpClient, }: IContext) => ({ droplet_id, }: IPowerCycleDropletApiRequest) => Promise<Readonly<PowerCycleDropletResponse>>;
