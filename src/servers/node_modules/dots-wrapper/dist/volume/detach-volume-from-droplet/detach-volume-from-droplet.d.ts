import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IDetachVolumeToDropletApiResponse {
    action: IAction;
}
export interface IDetachVolumeToDropletApiRequest {
    droplet_id: number;
    region?: string;
    volume_id: string;
}
export type DetachVolumeToDropletResponse = IResponse<IDetachVolumeToDropletApiResponse>;
export declare const detachVolumeFromDroplet: ({ httpClient, }: IContext) => ({ droplet_id, region, volume_id, }: IDetachVolumeToDropletApiRequest) => Promise<Readonly<DetachVolumeToDropletResponse>>;
