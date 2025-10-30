import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ISnapshot } from '../../snapshot';
export interface IListDropletSnapshotsApiResponse extends IListResponse {
    snapshots: ISnapshot[];
}
export interface IListDropletSnapshotsApiRequest extends IListRequest {
    droplet_id: number;
}
export type ListDropletSnapshotsResponse = IResponse<IListDropletSnapshotsApiResponse>;
export declare const listDropletSnapshots: ({ httpClient, }: IContext) => ({ droplet_id, page, per_page, }: IListDropletSnapshotsApiRequest) => Promise<Readonly<ListDropletSnapshotsResponse>>;
