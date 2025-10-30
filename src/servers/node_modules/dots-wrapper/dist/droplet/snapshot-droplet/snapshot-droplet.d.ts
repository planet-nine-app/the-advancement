import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface ISnapshotDropletApiResponse {
    action: IAction;
}
export interface ISnapshotDropletApiRequest {
    droplet_id: number;
    name?: string;
}
export type SnapshotDropletResponse = IResponse<ISnapshotDropletApiResponse>;
export declare const snapshotDroplet: ({ httpClient, }: IContext) => ({ droplet_id, name, }: ISnapshotDropletApiRequest) => Promise<Readonly<SnapshotDropletResponse>>;
