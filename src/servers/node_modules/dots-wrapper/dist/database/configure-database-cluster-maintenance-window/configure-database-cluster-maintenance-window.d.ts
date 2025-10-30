import { IResponse, IContext } from '../../types';
export interface IConfigureDatabaseClusterMaintenanceWindowApiRequest {
    database_cluster_id: string;
    day: string;
    hour: string;
}
export type ConfigureDatabaseClusterMaintenanceWindowResponse = IResponse<void>;
export declare const configureDatabaseClusterMaintenanceWindow: ({ httpClient, }: IContext) => ({ database_cluster_id, day, hour, }: IConfigureDatabaseClusterMaintenanceWindowApiRequest) => Promise<Readonly<ConfigureDatabaseClusterMaintenanceWindowResponse>>;
