import { IResponse, IContext } from '../../types';
import { IAction } from '..';
export interface IGetActionApiRequest {
    action_id: number;
}
export interface IGetActionApiResponse {
    action: IAction;
}
export type GetActionResponse = IResponse<IGetActionApiResponse>;
export declare const getAction: ({ httpClient, }: IContext) => ({ action_id, }: IGetActionApiRequest) => Promise<Readonly<GetActionResponse>>;
