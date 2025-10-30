import { IResponse, IContext } from '../../types';
export interface IResizeDatabaseClusterApiRequest {
    database_cluster_id: string;
    num_nodes: number;
    size: string;
}
export type ResizeDatabaseClusterResponse = IResponse<void>;
export declare const resizeDatabaseCluster: ({ httpClient, }: IContext) => ({ database_cluster_id, num_nodes, size, }: IResizeDatabaseClusterApiRequest) => Promise<Readonly<ResizeDatabaseClusterResponse>>;
