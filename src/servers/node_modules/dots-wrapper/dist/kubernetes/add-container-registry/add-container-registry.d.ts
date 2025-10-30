import { IResponse, IContext } from '../../types';
export interface IAddContainerRegistryApiRequest {
    cluster_uuids: string[];
}
export type AddContainerRegistryResponse = IResponse<void>;
export declare const addContainerRegistry: ({ httpClient, }: IContext) => ({ cluster_uuids, }: IAddContainerRegistryApiRequest) => Promise<Readonly<AddContainerRegistryResponse>>;
