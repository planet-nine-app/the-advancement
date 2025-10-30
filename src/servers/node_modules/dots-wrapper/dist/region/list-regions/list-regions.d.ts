import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IRegion } from '..';
export interface IListRegionsApiResponse extends IListResponse {
    regions: IRegion[];
}
export type ListRegionsResponse = IResponse<IListRegionsApiResponse>;
export declare const listRegions: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListRegionsResponse>>;
