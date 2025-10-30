import { IResponse, IContext } from '../../types';
export interface IUpgradeKubernetesClusterApiRequest {
    kubernetes_cluster_id: string;
    version: string;
}
export type UpgradeKubernetesClusterResponse = IResponse<void>;
export declare const upgradeKubernetesCluster: ({ httpClient, }: IContext) => ({ kubernetes_cluster_id, version, }: IUpgradeKubernetesClusterApiRequest) => Promise<Readonly<UpgradeKubernetesClusterResponse>>;
