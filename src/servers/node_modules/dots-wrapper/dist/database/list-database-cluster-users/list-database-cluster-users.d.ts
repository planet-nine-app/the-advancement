import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IDatabaseClusterUser } from '../types';
export interface IListDatabaseClusterUsersApiResponse extends IListResponse {
    users: IDatabaseClusterUser[];
}
export interface IListDatabaseClusterUsersApiRequest extends IListRequest {
    database_cluster_id: string;
}
export type ListDatabaseClusterUsersResponse = IResponse<IListDatabaseClusterUsersApiResponse>;
export declare const listDatabaseClusterUsers: ({ httpClient, }: IContext) => ({ page, per_page, database_cluster_id, }: IListDatabaseClusterUsersApiRequest) => Promise<Readonly<ListDatabaseClusterUsersResponse>>;
