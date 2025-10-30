import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
export interface IDatabaseClusterBackup {
    size_gigabytes: number;
    created_at: string;
}
export interface IListDatabaseClusterBackupsApiResponse extends IListResponse {
    backups: IDatabaseClusterBackup[];
}
export interface IListDatabaseClusterBackupsApiRequest extends IListRequest {
    database_cluster_id: string;
}
export type ListDatabaseClusterBackupsResponse = IResponse<IListDatabaseClusterBackupsApiResponse>;
export declare const listDatabaseClusterBackups: ({ httpClient, }: IContext) => ({ page, per_page, database_cluster_id, }: IListDatabaseClusterBackupsApiRequest) => Promise<Readonly<ListDatabaseClusterBackupsResponse>>;
