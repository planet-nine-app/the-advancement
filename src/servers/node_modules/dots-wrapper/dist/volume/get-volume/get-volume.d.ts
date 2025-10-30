import { IResponse, IContext } from '../../types';
import { IVolume } from '..';
export interface IGetVolumeApiResponse {
    volume: IVolume;
}
export interface IGetVolumeApiRequest {
    volume_id: string;
}
export type GetVolumeResponse = IResponse<IGetVolumeApiResponse>;
export declare const getVolume: ({ httpClient, }: IContext) => ({ volume_id, }: IGetVolumeApiRequest) => Promise<Readonly<GetVolumeResponse>>;
