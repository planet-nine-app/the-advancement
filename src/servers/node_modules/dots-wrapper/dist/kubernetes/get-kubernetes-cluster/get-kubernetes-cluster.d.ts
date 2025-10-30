import { IResponse, IContext } from '../../types';
import { IKubernetesCluster } from '..';
export interface IGetKubernetesClusterApiResponse {
    kubernetes_cluster: IKubernetesCluster;
}
export interface IGetKubernetesClusterApiRequest {
    kubernetes_cluster_id: string;
}
export type GetKubernetesClusterResponse = IResponse<IGetKubernetesClusterApiResponse>;
export declare const getKubernetesCluster: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, }: IGetKubernetesClusterApiRequest) => Promise<Readonly<GetKubernetesClusterResponse>>;
