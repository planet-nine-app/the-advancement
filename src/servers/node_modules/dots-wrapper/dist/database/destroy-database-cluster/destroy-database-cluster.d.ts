import { IResponse, IContext } from '../../types';
export interface IDestroyDatabaseClusterApiRequest {
    database_cluster_id: string;
}
export type DestroyDatabaseClusterResponse = IResponse<void>;
export declare const destroyDatabaseCluster: ({ httpClient, }: IContext) => ({ database_cluster_id, }: IDestroyDatabaseClusterApiRequest) => Promise<Readonly<DestroyDatabaseClusterResponse>>;
