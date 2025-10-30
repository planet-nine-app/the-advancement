import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IResetDropletPasswordApiResponse {
    action: IAction;
}
export interface IResetDropletPasswordApiRequest {
    droplet_id: number;
}
export type ResetDropletPasswordResponse = IResponse<IResetDropletPasswordApiResponse>;
export declare const resetDropletPassword: ({ httpClient, }: IContext) => ({ droplet_id, }: IResetDropletPasswordApiRequest) => Promise<Readonly<ResetDropletPasswordResponse>>;
