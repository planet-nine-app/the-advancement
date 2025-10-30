import { IResponse, IContext } from '../../types';
import { IDatabaseClusterReadOnlyReplica } from '..';
export interface IGetReadOnlyReplicaApiResponse {
    replica: IDatabaseClusterReadOnlyReplica;
}
export interface IGetReadOnlyReplicaApiRequest {
    database_cluster_id: string;
    read_only_replica_name: string;
}
export type GetReadOnlyReplicaResponse = IResponse<IGetReadOnlyReplicaApiResponse>;
export declare const getReadOnlyReplica: ({ httpClient, }: IContext) => ({ database_cluster_id, read_only_replica_name, }: IGetReadOnlyReplicaApiRequest) => Promise<Readonly<GetReadOnlyReplicaResponse>>;
