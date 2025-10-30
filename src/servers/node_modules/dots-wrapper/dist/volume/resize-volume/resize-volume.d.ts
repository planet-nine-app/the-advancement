import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IResizeVolumeToDropletApiResponse {
    action: IAction;
}
export interface IResizeVolumeToDropletApiRequest {
    region?: string;
    size_gigabytes: number;
    volume_id: string;
}
export type ResizeVolumeToDropletResponse = IResponse<IResizeVolumeToDropletApiResponse>;
export declare const resizeVolume: ({ httpClient, }: IContext) => ({ region, size_gigabytes, volume_id, }: IResizeVolumeToDropletApiRequest) => Promise<Readonly<ResizeVolumeToDropletResponse>>;
