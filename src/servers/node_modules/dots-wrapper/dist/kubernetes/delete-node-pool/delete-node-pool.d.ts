import { IResponse, IContext } from '../../types';
export interface IDeleteNodePoolApiRequest {
    kubernetes_cluster_id: string;
    node_pool_id: string;
}
export type DeleteNodePoolResponse = IResponse<void>;
export declare const deleteNodePool: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, node_pool_id, }: IDeleteNodePoolApiRequest) => Promise<Readonly<DeleteNodePoolResponse>>;
