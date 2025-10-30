import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IAction } from '../../action';
export interface IListDropletActionsApiResponse extends IListResponse {
    actions: IAction[];
}
export interface IListDropletActionsApiRequest extends IListRequest {
    droplet_id: number;
}
export type ListDropletActionsResponse = IResponse<IListDropletActionsApiResponse>;
export declare const listDropletActions: ({ httpClient, }: IContext) => ({ droplet_id, page, per_page, }: IListDropletActionsApiRequest) => Promise<Readonly<ListDropletActionsResponse>>;
