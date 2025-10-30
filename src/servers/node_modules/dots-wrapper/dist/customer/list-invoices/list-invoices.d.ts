import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IInvoice, IInvoicePreview } from '../types';
export interface IListInvoicesApiResponse extends IListResponse {
    invoices: IInvoice[];
    invoice_preview: IInvoicePreview;
}
export type ListInvoicesResponse = IResponse<IListInvoicesApiResponse>;
export declare const listInvoices: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListInvoicesResponse>>;
