import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ISize } from '..';
export interface IListSizeApiResponse extends IListResponse {
    sizes: ISize[];
}
export type ListSizesResponse = IResponse<IListSizeApiResponse>;
export declare const listSizes: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListSizesResponse>>;
