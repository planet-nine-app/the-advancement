import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IBillingHistory } from '..';
export interface IListBillingHistoryApiResponse extends IListResponse {
    billing_history: IBillingHistory[];
}
export type ListBillingHistoryResponse = IResponse<IListBillingHistoryApiResponse>;
export declare const listBillingHistory: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListBillingHistoryResponse>>;
