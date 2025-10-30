import { IResponse, IContext } from '../../types';
import { IKubernetesClusterNodePool, IKubernetesClusterNodePoolLabels, IKubernetesClusterNodePoolTaint } from '../';
export interface IUpdateNodePoolApiRequest {
    auto_scale?: boolean;
    count: number;
    kubernetes_cluster_id: string;
    labels?: IKubernetesClusterNodePoolLabels;
    max_nodes?: number;
    min_nodes?: number;
    name: string;
    node_pool_id: string;
    tags?: string[];
    taints?: IKubernetesClusterNodePoolTaint[];
}
export interface IUpdateNodePoolApiResponse {
    node_pool: IKubernetesClusterNodePool;
}
export type UpdateNodePoolResponse = IResponse<IUpdateNodePoolApiResponse>;
export declare const updateNodePool: ({ httpClient, }: IContext) => ({ auto_scale, count, kubernetes_cluster_id, labels, max_nodes, min_nodes, name, node_pool_id, tags, taints, }: IUpdateNodePoolApiRequest) => Promise<Readonly<UpdateNodePoolResponse>>;
