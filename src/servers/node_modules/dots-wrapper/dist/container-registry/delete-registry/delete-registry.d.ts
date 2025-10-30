import { IResponse, IContext } from '../../types';
export type DeleteRegistryResponse = IResponse<void>;
export declare const deleteRegistry: ({ httpClient, }: IContext) => () => Promise<Readonly<DeleteRegistryResponse>>;
