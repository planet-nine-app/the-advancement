import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IDroplet } from '..';
export interface IListDropletsApiResponse extends IListResponse {
    droplets: IDroplet[];
}
export interface IListDropletsApiRequest extends IListRequest {
    tag_name?: string;
}
export type ListDropletsResponse = IResponse<IListDropletsApiResponse>;
export declare const listDroplets: ({ httpClient, }: IContext) => ({ page, per_page, tag_name, }: IListDropletsApiRequest) => Promise<Readonly<ListDropletsResponse>>;
