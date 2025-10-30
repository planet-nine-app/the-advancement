import { IResponse, IContext } from '../../types';
import { IApp, IAppSpec } from '..';
export interface IUpdateAppApiResponse {
    app: IApp;
}
export interface IUpdateAppApiRequest {
    app_id: string;
    spec: Partial<IAppSpec>;
}
export type UpdateAppResponse = IResponse<IUpdateAppApiResponse>;
export declare const updateApp: ({ httpClient, }: IContext) => ({ app_id, spec, }: IUpdateAppApiRequest) => Promise<Readonly<UpdateAppResponse>>;
