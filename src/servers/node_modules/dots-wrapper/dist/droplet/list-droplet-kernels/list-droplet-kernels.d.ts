import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IKernel } from '..';
export interface IListDropletKernelsApiResponse extends IListResponse {
    kernels: IKernel[];
}
export interface IListDropletKernelsApiRequest extends IListRequest {
    droplet_id: number;
}
export type ListDropletKernelsResponse = IResponse<IListDropletKernelsApiResponse>;
export declare const listDropletKernels: ({ httpClient, }: IContext) => ({ droplet_id, page, per_page, }: IListDropletKernelsApiRequest) => Promise<Readonly<ListDropletKernelsResponse>>;
