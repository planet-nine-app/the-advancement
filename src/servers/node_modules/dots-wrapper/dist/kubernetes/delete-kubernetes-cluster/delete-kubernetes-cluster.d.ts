import { IResponse, IContext } from '../../types';
export interface IDeleteKubernetesClusterApiRequest {
    kubernetes_cluster_id: string;
}
export type DeleteKubernetesClusterResponse = IResponse<void>;
export declare const deleteKubernetesCluster: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, }: IDeleteKubernetesClusterApiRequest) => Promise<Readonly<DeleteKubernetesClusterResponse>>;
