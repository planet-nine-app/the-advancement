import { IResponse, IContext } from '../../types';
export interface IDeleteNodeApiRequest {
    kubernetes_cluster_id: string;
    node_pool_id: string;
    node_id: string;
    drain_node?: boolean;
    replace_node?: boolean;
}
export type DeleteNodeResponse = IResponse<void>;
export declare const deleteNode: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, node_pool_id, node_id, drain_node, replace_node, }: IDeleteNodeApiRequest) => Promise<Readonly<DeleteNodeResponse>>;
