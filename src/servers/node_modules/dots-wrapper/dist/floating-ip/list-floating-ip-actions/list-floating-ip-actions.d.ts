import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IAction } from '../../action';
export interface IListFloatingIpActionsApiResponse extends IListResponse {
    actions: IAction[];
}
export interface IListFloatingIpActionsApiRequest extends IListRequest {
    ip: string;
}
export type ListFloatingIpActionssResponse = IResponse<IListFloatingIpActionsApiResponse>;
export declare const listFloatingIpActions: ({ httpClient, }: IContext) => ({ ip, page, per_page, }: IListFloatingIpActionsApiRequest) => Promise<Readonly<ListFloatingIpActionssResponse>>;
