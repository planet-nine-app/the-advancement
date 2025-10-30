import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { IDatabaseCluster } from '..';
export interface IListDatabaseClusterApiResponse extends IListResponse {
    databases: IDatabaseCluster[];
}
export type ListDatabaseClusterResponse = IResponse<IListDatabaseClusterApiResponse>;
export declare const listDatabaseClusters: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListDatabaseClusterResponse>>;
