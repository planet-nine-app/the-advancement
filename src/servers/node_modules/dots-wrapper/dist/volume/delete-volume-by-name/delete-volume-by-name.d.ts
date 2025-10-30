import { IResponse, IContext } from '../../types';
export interface IDeleteVolumeByNameApiRequest {
    region: string;
    volume_name: string;
}
export type DeleteVolumeByNameResponse = IResponse<void>;
export declare const deleteVolumeByName: ({ httpClient, }: IContext) => ({ region, volume_name, }: IDeleteVolumeByNameApiRequest) => Promise<Readonly<DeleteVolumeByNameResponse>>;
