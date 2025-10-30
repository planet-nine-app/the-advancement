import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IDroplet } from '..';
export interface IListDropletNeighborsApiResponse extends IListResponse {
    droplets: IDroplet[];
}
export interface IListDropletNeighborsApiRequest extends IListRequest {
    droplet_id: number;
}
export type ListDropletNeighborsResponse = IResponse<IListDropletNeighborsApiResponse>;
export declare const listDropletNeighbors: ({ httpClient, }: IContext) => ({ droplet_id, page, per_page, }: IListDropletNeighborsApiRequest) => Promise<Readonly<ListDropletNeighborsResponse>>;
