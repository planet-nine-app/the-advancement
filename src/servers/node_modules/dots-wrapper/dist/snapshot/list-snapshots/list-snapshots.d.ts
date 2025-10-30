import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ISnapshot } from '..';
export interface IListSnapshotApiResponse extends IListResponse {
    snapshots: ISnapshot[];
}
export interface IListSnapshotApiRequest extends IListRequest {
    resource_type?: 'droplet' | 'volume';
}
export type ListSnapshotsResponse = IResponse<IListSnapshotApiResponse>;
export declare const listSnapshots: ({ httpClient, }: IContext) => ({ page, per_page, resource_type, }: IListSnapshotApiRequest) => Promise<Readonly<ListSnapshotsResponse>>;
