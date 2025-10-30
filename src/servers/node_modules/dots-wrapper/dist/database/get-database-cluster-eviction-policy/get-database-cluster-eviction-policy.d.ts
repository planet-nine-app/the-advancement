import { IResponse, IContext } from '../../types';
import { DatabaseClusterEvictionPolicy } from '..';
export interface IGetDatabaseClusterEvictionPolicyApiResponse {
    eviction_policy: DatabaseClusterEvictionPolicy;
}
export interface IGetDatabaseClusterEvictionPolicyApiRequest {
    database_cluster_id: string;
}
export type GetDatabaseClusterEvictionPolicyResponse = IResponse<IGetDatabaseClusterEvictionPolicyApiResponse>;
export declare const getDatabaseClusterEvictionPolicy: ({ httpClient, }: IContext) => ({ database_cluster_id, }: IGetDatabaseClusterEvictionPolicyApiRequest) => Promise<Readonly<GetDatabaseClusterEvictionPolicyResponse>>;
