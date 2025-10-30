import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { ISnapshot } from '../../snapshot';
export interface IListVolumeSnapshotsApiResponse extends IListResponse {
    snapshots: ISnapshot[];
}
export interface IListVolumeSnapshotsApiRequest extends IListRequest {
    volume_id: string;
}
export type ListVolumeSnapshotsRes = IResponse<IListVolumeSnapshotsApiResponse>;
export declare const listVolumeSnapshots: ({ httpClient, }: IContext) => ({ page, per_page, volume_id, }: IListVolumeSnapshotsApiRequest) => Promise<Readonly<ListVolumeSnapshotsRes>>;
