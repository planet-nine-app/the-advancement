import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IVolume } from '..';
export interface IListVolumesApiResponse extends IListResponse {
    volumes: IVolume[];
}
export interface IListVolumesApiRequest extends IListRequest {
    name?: string;
}
export type ListVolumesResponse = IResponse<IListVolumesApiResponse>;
export declare const listVolumes: ({ httpClient, }: IContext) => ({ name, page, per_page, }: IListVolumesApiRequest) => Promise<Readonly<ListVolumesResponse>>;
