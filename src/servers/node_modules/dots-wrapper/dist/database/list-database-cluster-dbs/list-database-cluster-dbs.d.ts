import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IDatabaseClusterDb } from '../types';
export interface IListDatabaseClusterDbsApiResponse extends IListResponse {
    dbs: IDatabaseClusterDb[];
}
export interface IListDatabaseClusterDbsApiRequest extends IListRequest {
    database_cluster_id: string;
}
export type ListDatabaseClusterDbsResponse = IResponse<IListDatabaseClusterDbsApiResponse>;
export declare const listDatabaseClusterDbs: ({ httpClient, }: IContext) => ({ page, per_page, database_cluster_id, }: IListDatabaseClusterDbsApiRequest) => Promise<Readonly<ListDatabaseClusterDbsResponse>>;
