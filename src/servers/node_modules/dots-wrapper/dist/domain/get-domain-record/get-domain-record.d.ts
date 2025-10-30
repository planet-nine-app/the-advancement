import { IResponse, IContext } from '../../types';
import { IDomainRecord } from '..';
export interface IGetDomainRecordApiResponse {
    domain_record: IDomainRecord;
}
export interface IGetDomainRecordApiRequest {
    domain_name: string;
    domain_record_id: number;
}
export type GetDomainRecordResponse = IResponse<IGetDomainRecordApiResponse>;
export declare const getDomainRecord: ({ httpClient, }: IContext) => ({ domain_name, domain_record_id, }: IGetDomainRecordApiRequest) => Promise<Readonly<GetDomainRecordResponse>>;
