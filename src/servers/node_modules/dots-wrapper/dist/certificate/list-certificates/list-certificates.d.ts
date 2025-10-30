import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ICertificate } from '..';
export interface IListCertificatesApiResponse extends IListResponse {
    certificates: ICertificate[];
}
export type ListCertificatesResponse = IResponse<IListCertificatesApiResponse>;
export declare const listCertificates: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListCertificatesResponse>>;
