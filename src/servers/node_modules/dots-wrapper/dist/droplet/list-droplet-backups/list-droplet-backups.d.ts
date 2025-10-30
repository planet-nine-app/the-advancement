import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ISnapshot } from '../../snapshot';
export interface IListDropletBackupsApiResponse extends IListResponse {
    backups: ISnapshot[];
}
export interface IListDropletBackupsApiRequest extends IListRequest {
    droplet_id: number;
}
export type ListDropletBackupsResponse = IResponse<IListDropletBackupsApiResponse>;
export declare const listDropletBackups: ({ httpClient, }: IContext) => ({ droplet_id, page, per_page, }: IListDropletBackupsApiRequest) => Promise<Readonly<ListDropletBackupsResponse>>;
