import { IResponse, IContext } from '../../types';
import { IDatabaseClusterConnectionPool } from '..';
export interface IGetConnectionPoolApiResponse {
    pool: IDatabaseClusterConnectionPool;
}
export interface IGetConnectionPoolApiRequest {
    database_cluster_id: string;
    pool_name: string;
}
export type GetConnectionPoolResponse = IResponse<IGetConnectionPoolApiResponse>;
export declare const getConnectionPool: ({ httpClient, }: IContext) => ({ database_cluster_id, pool_name, }: IGetConnectionPoolApiRequest) => Promise<Readonly<GetConnectionPoolResponse>>;
