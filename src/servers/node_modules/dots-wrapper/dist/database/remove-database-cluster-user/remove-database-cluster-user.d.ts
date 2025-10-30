import { IResponse, IContext } from '../../types';
export interface IRemoveDatabaseClusterUserApiRequest {
    database_cluster_id: string;
    user_name: string;
}
export type RemoveDatabaseClusterUserResponse = IResponse<void>;
export declare const removeDatabaseClusterUser: ({ httpClient, }: IContext) => ({ database_cluster_id, user_name, }: IRemoveDatabaseClusterUserApiRequest) => Promise<Readonly<RemoveDatabaseClusterUserResponse>>;
