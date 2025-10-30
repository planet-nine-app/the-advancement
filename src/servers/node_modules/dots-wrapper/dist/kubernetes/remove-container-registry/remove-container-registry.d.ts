import { IResponse, IContext } from '../../types';
export interface IRemoveContainerRegistryApiRequest {
    cluster_uuids: string[];
}
export type RemoveContainerRegistryResponse = IResponse<void>;
export declare const removeContainerRegistry: ({ httpClient, }: IContext) => ({ cluster_uuids, }: IRemoveContainerRegistryApiRequest) => Promise<Readonly<RemoveContainerRegistryResponse>>;
