import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IPowerOffDropletApiResponse {
    action: IAction;
}
export interface IPowerOffDropletApiRequest {
    droplet_id: number;
}
export type PowerOffDropletResponse = IResponse<IPowerOffDropletApiResponse>;
export declare const powerOffDroplet: ({ httpClient, }: IContext) => ({ droplet_id, }: IPowerOffDropletApiRequest) => Promise<Readonly<PowerOffDropletResponse>>;
