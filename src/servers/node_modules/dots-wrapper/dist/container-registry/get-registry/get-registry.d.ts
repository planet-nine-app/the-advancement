import { IResponse, IContext } from '../../types';
import { IContainerRegistry } from '..';
export interface IGetRegistryApiResponse {
    registry: IContainerRegistry;
}
export type GetRegistryResponse = IResponse<IGetRegistryApiResponse>;
export declare const getRegistry: ({ httpClient, }: IContext) => () => Promise<Readonly<GetRegistryResponse>>;
