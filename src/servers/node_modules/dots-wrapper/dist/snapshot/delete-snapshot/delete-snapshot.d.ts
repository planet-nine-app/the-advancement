import { IResponse, IContext } from '../../types';
export interface IDeleteSnapshotApiRequest {
    snapshot_id: string | number;
}
export type DeleteSnapshotRes = IResponse<void>;
export declare const deleteSnapshot: ({ httpClient, }: IContext) => ({ snapshot_id, }: IDeleteSnapshotApiRequest) => Promise<Readonly<DeleteSnapshotRes>>;
