import { IResponse, IContext } from '../../types';
import { IDatabaseClusterReadOnlyReplica } from '..';
export interface ICreateReadOnlyReplicaApiResponse {
    replica: Partial<IDatabaseClusterReadOnlyReplica>;
}
export interface ICreateReadOnlyReplicaApiRequest {
    database_cluster_id: string;
    name: string;
    region: string;
    size: string;
    tags?: string[];
}
export type CreateReadOnlyReplicaResponse = IResponse<ICreateReadOnlyReplicaApiResponse>;
export declare const createReadOnlyReplica: ({ httpClient, }: IContext) => ({ database_cluster_id, name, region, size, tags, }: ICreateReadOnlyReplicaApiRequest) => Promise<Readonly<CreateReadOnlyReplicaResponse>>;
