import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IDatabaseClusterConnectionPool } from '../types';
export interface IListdConnectionPoolsApiResponse extends IListResponse {
    pools: IDatabaseClusterConnectionPool[];
}
export interface IListdConnectionPoolsApiRequest extends IListRequest {
    database_cluster_id: string;
}
export type ListdConnectionPoolsResponse = IResponse<IListdConnectionPoolsApiResponse>;
export declare const listConnectionPools: ({ httpClient, }: IContext) => ({ page, per_page, database_cluster_id, }: IListdConnectionPoolsApiRequest) => Promise<Readonly<ListdConnectionPoolsResponse>>;
