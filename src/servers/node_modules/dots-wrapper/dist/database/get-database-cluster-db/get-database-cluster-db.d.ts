import { IResponse, IContext } from '../../types';
import { IDatabaseClusterDb } from '..';
export interface IGetDatabaseClusterDbApiResponse {
    db: IDatabaseClusterDb;
}
export interface IGetDatabaseClusterDbApiRequest {
    database_cluster_id: string;
    db_name: string;
}
export type GetDatabaseClusterDbResponse = IResponse<IGetDatabaseClusterDbApiResponse>;
export declare const getDatabaseClusterDb: ({ httpClient, }: IContext) => ({ database_cluster_id, db_name, }: IGetDatabaseClusterDbApiRequest) => Promise<Readonly<GetDatabaseClusterDbResponse>>;
