import { IResponse, IContext } from '../../types';
import { IInvoiceSummary } from '..';
export type GetInvoiceSummaryResponse = IResponse<IInvoiceSummary>;
export interface IGetInvoiceSummaryApiRequest {
    invoice_uuid: string;
}
export declare const getInvoiceSummary: ({ httpClient, }: IContext) => ({ invoice_uuid, }: IGetInvoiceSummaryApiRequest) => Promise<Readonly<GetInvoiceSummaryResponse>>;
