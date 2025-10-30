import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IGetImageActionApiRequest {
    image_id: number;
    action_id: number;
}
export interface IGetImageActionApiResponse {
    action: IAction;
}
export type GetImageActionResponse = IResponse<IGetImageActionApiResponse>;
export declare const getImageAction: ({ httpClient, }: IContext) => ({ image_id, action_id, }: IGetImageActionApiRequest) => Promise<Readonly<GetImageActionResponse>>;
