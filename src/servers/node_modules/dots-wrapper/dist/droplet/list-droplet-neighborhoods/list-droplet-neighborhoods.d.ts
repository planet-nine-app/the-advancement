import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
export interface IListDropletNeighborhoodsApiResponse extends IListResponse {
    neighbor_ids: Array<number[]>;
}
export type ListDropletNeighborhoodsResponse = IResponse<IListDropletNeighborhoodsApiResponse>;
export declare const listDropletNeighborhoods: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListDropletNeighborhoodsResponse>>;
