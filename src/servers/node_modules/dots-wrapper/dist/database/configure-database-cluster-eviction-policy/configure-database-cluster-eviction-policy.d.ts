import { IResponse, IContext } from '../../types';
import { DatabaseClusterEvictionPolicy } from '..';
export interface IConfigureDatabaseClusterEvictionPolicyApiRequest {
    database_cluster_id: string;
    eviction_policy: DatabaseClusterEvictionPolicy;
}
export type ConfigureDatabaseClusterEvictionPolicyResponse = IResponse<void>;
export declare const configureDatabaseClusterEvictionPolicy: ({ httpClient, }: IContext) => ({ database_cluster_id, eviction_policy, }: IConfigureDatabaseClusterEvictionPolicyApiRequest) => Promise<Readonly<ConfigureDatabaseClusterEvictionPolicyResponse>>;
