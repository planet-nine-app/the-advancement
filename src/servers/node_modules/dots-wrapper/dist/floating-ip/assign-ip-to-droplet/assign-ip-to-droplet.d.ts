import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IAssignIpToDropletApiResponse {
    action: IAction;
}
export interface IAssignIpToDropletApiRequest {
    droplet_id: number;
    ip: string;
}
export type AssignIpToDropletResponse = IResponse<IAssignIpToDropletApiResponse>;
export declare const assignIpToDroplet: ({ httpClient, }: IContext) => ({ droplet_id, ip, }: IAssignIpToDropletApiRequest) => Promise<Readonly<AssignIpToDropletResponse>>;
