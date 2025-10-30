import { IResponse, IContext } from '../../types';
import { ISnapshot } from '../../snapshot';
export interface ICreateVolumeSnapshotApiResponse {
    snapshot: ISnapshot;
}
export interface ICreateVolumeSnapshotApiRequest {
    name: string;
    tags?: string[];
    volume_id: string;
}
export type CreateVolumeSnapshotRes = IResponse<ICreateVolumeSnapshotApiResponse>;
export declare const createVolumeSnapshot: ({ httpClient, }: IContext) => ({ name, tags, volume_id, }: ICreateVolumeSnapshotApiRequest) => Promise<Readonly<CreateVolumeSnapshotRes>>;
