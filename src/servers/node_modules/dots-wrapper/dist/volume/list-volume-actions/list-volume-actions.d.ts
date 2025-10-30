import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IAction } from '../../action';
export interface IListVolumeActionsApiResponse extends IListResponse {
    actions: IAction[];
}
export interface IListVolumeActionsApiRequest extends IListRequest {
    volume_id: string;
}
export type ListVolumeActionssResponse = IResponse<IListVolumeActionsApiResponse>;
export declare const listVolumeActions: ({ httpClient, }: IContext) => ({ page, per_page, volume_id, }: IListVolumeActionsApiRequest) => Promise<Readonly<ListVolumeActionssResponse>>;
