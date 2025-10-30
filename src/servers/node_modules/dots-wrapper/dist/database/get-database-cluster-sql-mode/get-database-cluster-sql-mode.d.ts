import { IResponse, IContext } from '../../types';
export interface IGetDatabaseClusterSqlModeApiResponse {
    sql_mode: string;
}
export interface IGetDatabaseClusterSqlModeApiRequest {
    database_cluster_id: string;
}
export type GetDatabaseClusterSqlModeResponse = IResponse<IGetDatabaseClusterSqlModeApiResponse>;
export declare const getDatabaseClusterSqlMode: ({ httpClient, }: IContext) => ({ database_cluster_id, }: IGetDatabaseClusterSqlModeApiRequest) => Promise<Readonly<GetDatabaseClusterSqlModeResponse>>;
