import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IDatabaseClusterReadOnlyReplica } from '../types';
export interface IListReadOnlyReplicasApiResponse extends IListResponse {
    replicas: IDatabaseClusterReadOnlyReplica[];
}
export interface IListReadOnlyReplicasApiRequest extends IListRequest {
    database_cluster_id: string;
}
export type ListReadOnlyReplicasResponse = IResponse<IListReadOnlyReplicasApiResponse>;
export declare const listReadOnlyReplicas: ({ httpClient, }: IContext) => ({ page, per_page, database_cluster_id, }: IListReadOnlyReplicasApiRequest) => Promise<Readonly<ListReadOnlyReplicasResponse>>;
