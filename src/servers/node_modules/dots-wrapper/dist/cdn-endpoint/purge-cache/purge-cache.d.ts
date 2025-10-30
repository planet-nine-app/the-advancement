import { IResponse, IContext } from '../../types';
export interface IPurgeCacheApiRequest {
    cdn_endpoint_id: string;
    files: string[];
}
export type PurgeCacheResponse = IResponse<void>;
export declare const purgeCache: ({ httpClient, }: IContext) => ({ cdn_endpoint_id, files, }: IPurgeCacheApiRequest) => Promise<Readonly<PurgeCacheResponse>>;
