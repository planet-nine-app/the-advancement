import { IResponse, IContext } from '../../types';
export interface IMigrateDatabaseClusterApiRequest {
    database_cluster_id: string;
    region: string;
}
export type MigrateDatabaseClusterResponse = IResponse<void>;
export declare const migrateDatabaseCluster: ({ httpClient, }: IContext) => ({ database_cluster_id, region, }: IMigrateDatabaseClusterApiRequest) => Promise<Readonly<MigrateDatabaseClusterResponse>>;
