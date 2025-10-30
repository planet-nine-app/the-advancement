import { IResponse, IContext } from '../../types';
export interface IGetKubernetesClusterKubeconfigApiRequest {
    kubernetes_cluster_id: string;
    expiration_in_seconds?: number;
}
export type GetKubernetesClusterKubeconfigResponse = IResponse<string>;
export declare const getKubernetesClusterKubeconfig: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, expiration_in_seconds, }: IGetKubernetesClusterKubeconfigApiRequest) => Promise<Readonly<GetKubernetesClusterKubeconfigResponse>>;
