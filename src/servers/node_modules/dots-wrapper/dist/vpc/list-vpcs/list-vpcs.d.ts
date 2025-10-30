import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IVpc } from '..';
export interface IListVpcsApiResponse extends IListResponse {
    vpcs: IVpc[];
}
export type ListVpcsResponse = IResponse<IListVpcsApiResponse>;
export declare const listVpcs: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListVpcsResponse>>;
