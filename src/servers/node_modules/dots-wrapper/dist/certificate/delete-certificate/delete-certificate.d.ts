import { IResponse, IContext } from '../../types';
export interface IDeleteCertificateApiRequest {
    certificate_id: string;
}
export type DeleteCertificateResponse = IResponse<void>;
export declare const deleteCertificate: ({ httpClient, }: IContext) => ({ certificate_id, }: IDeleteCertificateApiRequest) => Promise<Readonly<DeleteCertificateResponse>>;
