import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ISshKey } from '..';
export interface IListSshKeysApiResponse extends IListResponse {
    ssh_keys: ISshKey[];
}
export type ListSshKeysResponse = IResponse<IListSshKeysApiResponse>;
export declare const listSshKeys: ({ httpClient, }: IContext) => ({ page, per_page, }: IListRequest) => Promise<Readonly<ListSshKeysResponse>>;
