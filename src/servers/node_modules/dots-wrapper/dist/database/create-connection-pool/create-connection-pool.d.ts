import { IResponse, IContext } from '../../types';
import { IDatabaseClusterConnectionPool } from '../types';
export interface ICreateConnectionPoolApiResponse {
    pool: IDatabaseClusterConnectionPool;
}
export interface ICreateConnectionPoolApiRequest {
    database_cluster_id: string;
    db_name: string;
    mode: string;
    pool_name: string;
    size: number;
    user_name: string;
}
export type CreateConnectionPoolResponse = IResponse<ICreateConnectionPoolApiResponse>;
export declare const createConnectionPool: ({ httpClient, }: IContext) => ({ database_cluster_id, db_name, mode, pool_name, size, user_name, }: ICreateConnectionPoolApiRequest) => Promise<Readonly<CreateConnectionPoolResponse>>;
