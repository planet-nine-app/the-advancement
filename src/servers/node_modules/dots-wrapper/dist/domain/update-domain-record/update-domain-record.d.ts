import { IResponse, IContext } from '../../types';
import { IDomainRecord } from '..';
export interface IUpdateDomainRecordApiResponse {
    domain_record: IDomainRecord;
}
export interface IUpdateDomainRecordApiRequest extends Partial<IDomainRecord> {
    domain_name: string;
    domain_record_id: number;
}
export type UpdateDomainRecordResponse = IResponse<IUpdateDomainRecordApiResponse>;
export declare const updateDomainRecord: ({ httpClient, }: IContext) => ({ data, domain_name, domain_record_id, flags, name, port, priority, tag, ttl, type, weight, }: IUpdateDomainRecordApiRequest) => Promise<Readonly<UpdateDomainRecordResponse>>;
