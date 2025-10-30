import { IResponse, IContext } from '../../types';
import { IDatabaseCluster } from '..';
export interface IGetDatabaseClusterApiResponse {
    database: IDatabaseCluster;
}
export interface IGetDatabaseClusterApiRequest {
    database_cluster_id: string;
}
export type GetDatabaseClusterResponse = IResponse<IGetDatabaseClusterApiResponse>;
export declare const getDatabaseCluster: ({ httpClient, }: IContext) => ({ database_cluster_id, }: IGetDatabaseClusterApiRequest) => Promise<Readonly<GetDatabaseClusterResponse>>;
