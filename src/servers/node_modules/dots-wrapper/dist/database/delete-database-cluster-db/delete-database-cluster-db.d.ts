import { IResponse, IContext } from '../../types';
export interface IDeleteDatabaseClusterDbApiRequest {
    database_cluster_id: string;
    db_name: string;
}
export type DeleteDatabaseClusterDbResponse = IResponse<void>;
export declare const deleteDatabaseClusterDb: ({ httpClient, }: IContext) => ({ database_cluster_id, db_name, }: IDeleteDatabaseClusterDbApiRequest) => Promise<Readonly<DeleteDatabaseClusterDbResponse>>;
