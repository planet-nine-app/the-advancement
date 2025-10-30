import { IResponse, IContext } from '../../types';
import { IDatabaseCluster, DatabaseClusterEngine } from '..';
export interface IRestoreDatabaseClusterBackupApiResponse {
    database: IDatabaseCluster;
}
export interface IDatabaseClusterBackupRestore {
    database_name: string;
    created_at?: string;
}
export interface IRestoreDatabaseClusterBackupApiRequest {
    engine: DatabaseClusterEngine;
    name: string;
    num_nodes: number;
    region: string;
    size: string;
    tags?: string[];
    version?: string;
    backup_restore: IDatabaseClusterBackupRestore;
}
export type RestoreDatabaseClusterBackupResponse = IResponse<IRestoreDatabaseClusterBackupApiResponse>;
export declare const restoreDatabaseClusterBackup: ({ httpClient, }: IContext) => ({ backup_restore, engine, name, num_nodes, region, size, tags, version, }: IRestoreDatabaseClusterBackupApiRequest) => Promise<Readonly<RestoreDatabaseClusterBackupResponse>>;
