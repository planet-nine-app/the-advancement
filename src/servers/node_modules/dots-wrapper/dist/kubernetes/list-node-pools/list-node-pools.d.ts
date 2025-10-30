import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IKubernetesClusterNodePool } from '..';
export interface IListNodePoolsApiResponse extends IListResponse {
    node_pools: IKubernetesClusterNodePool[];
}
export interface IListNodePoolsApiRequest extends IListRequest {
    kubernetes_cluster_id: string;
}
export type ListNodePoolsResponse = IResponse<IListNodePoolsApiResponse>;
export declare const listNodePools: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, page, per_page, }: IListNodePoolsApiRequest) => Promise<Readonly<ListNodePoolsResponse>>;
