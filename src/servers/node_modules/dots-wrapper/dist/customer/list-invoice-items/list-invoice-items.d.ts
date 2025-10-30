import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IInvoiceItem } from '../types';
export interface IListInvoiceItemsApiResponse extends IListResponse {
    invoice_items: IInvoiceItem[];
}
export interface IListInvoiceItemsApiRequest extends IListRequest {
    invoice_uuid: string;
}
export type ListInvoiceItemsResponse = IResponse<IListInvoiceItemsApiResponse>;
export declare const listInvoiceItems: ({ httpClient, }: IContext) => ({ invoice_uuid, page, per_page, }: IListInvoiceItemsApiRequest) => Promise<Readonly<ListInvoiceItemsResponse>>;
