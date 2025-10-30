import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IDomainRecord } from '..';
export interface IListDomainRecordsApiResponse extends IListResponse {
    domain_records: IDomainRecord[];
}
export type ListDomainRecordsResponse = IResponse<IListDomainRecordsApiResponse>;
export interface IListDomainRecordsRequest extends IListRequest {
    domain_name: string;
    name?: string;
    type?: string;
}
export declare const listDomainRecords: ({ httpClient, }: IContext) => ({ domain_name, name, page, per_page, type, }: IListDomainRecordsRequest) => Promise<Readonly<ListDomainRecordsResponse>>;
