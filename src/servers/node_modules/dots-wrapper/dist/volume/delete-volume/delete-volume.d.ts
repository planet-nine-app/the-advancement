import { IResponse, IContext } from '../../types';
export interface IDeleteVolumeApiRequest {
    volume_id: string;
}
export type DeleteVolumeResponse = IResponse<void>;
export declare const deleteVolume: ({ httpClient, }: IContext) => ({ volume_id, }: IDeleteVolumeApiRequest) => Promise<Readonly<DeleteVolumeResponse>>;
