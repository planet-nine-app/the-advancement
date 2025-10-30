import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IKubernetesCluster } from '..';
export interface IListKubernetesClusterApiResponse extends IListResponse {
    kubernetes_clusters: IKubernetesCluster[];
}
export type ListKubernetesClusterResponse = IResponse<IListKubernetesClusterApiResponse>;
export declare const listKubernetesClusters: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListKubernetesClusterResponse>>;
