import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IUnassignIpFromDropletApiResponse {
    action: IAction;
}
export interface IUnassignIpFromDropletApiRequest {
    ip: string;
}
export type UnassignIpFromDropletResponse = IResponse<IUnassignIpFromDropletApiResponse>;
export declare const unassignIpFromDroplet: ({ httpClient, }: IContext) => ({ ip, }: IUnassignIpFromDropletApiRequest) => Promise<Readonly<UnassignIpFromDropletResponse>>;
