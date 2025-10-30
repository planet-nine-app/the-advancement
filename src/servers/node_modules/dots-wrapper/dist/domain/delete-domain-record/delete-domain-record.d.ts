import { IResponse, IContext } from '../../types';
export interface IDeleteDomainRecordApiRequest {
    domain_name: string;
    domain_record_id: number;
}
export type DeleteDomainRecordResponse = IResponse<void>;
export declare const deleteDomainRecord: ({ httpClient, }: IContext) => ({ domain_name, domain_record_id, }: IDeleteDomainRecordApiRequest) => Promise<Readonly<DeleteDomainRecordResponse>>;
