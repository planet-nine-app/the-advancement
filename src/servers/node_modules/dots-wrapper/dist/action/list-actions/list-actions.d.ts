import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IAction } from '..';
export interface IListActionApiResponse extends IListResponse {
    actions: IAction[];
}
export type ListActionsResponse = IResponse<IListActionApiResponse>;
export declare const listActions: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListActionsResponse>>;
