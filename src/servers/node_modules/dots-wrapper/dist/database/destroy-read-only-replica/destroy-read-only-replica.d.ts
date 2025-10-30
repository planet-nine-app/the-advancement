import { IResponse, IContext } from '../../types';
export interface IDestroyReadOnlyReplicaApiRequest {
    database_cluster_id: string;
    read_only_replica_name: string;
}
export type DestroyReadOnlyReplicaResponse = IResponse<void>;
export declare const destroyReadOnlyReplica: ({ httpClient, }: IContext) => ({ database_cluster_id, read_only_replica_name, }: IDestroyReadOnlyReplicaApiRequest) => Promise<Readonly<DestroyReadOnlyReplicaResponse>>;
