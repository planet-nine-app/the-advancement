import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ITag } from '..';
export interface IListTagsApiResponse extends IListResponse {
    tags: ITag[];
}
export type ListTagsResponse = IResponse<IListTagsApiResponse>;
export declare const listTags: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListTagsResponse>>;
