import { IResponse, IContext } from '../../types';
export interface IDeleteAppApiRequest {
    app_id: string;
}
export type DeleteAppResponse = IResponse<void>;
export declare const deleteApp: ({ httpClient, }: IContext) => ({ app_id, }: IDeleteAppApiRequest) => Promise<Readonly<DeleteAppResponse>>;
