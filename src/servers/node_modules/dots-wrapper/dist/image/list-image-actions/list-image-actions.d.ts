import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IAction } from '../../action';
export interface IListImageActionsApiResponse extends IListResponse {
    actions: IAction[];
}
export interface IListImageActionsApiRequest extends IListRequest {
    image_id: number;
}
export type ListImageActionsResponse = IResponse<IListImageActionsApiResponse>;
export declare const listImageActions: ({ httpClient, }: IContext) => ({ page, per_page, image_id, }: IListImageActionsApiRequest) => Promise<Readonly<ListImageActionsResponse>>;
