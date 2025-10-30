import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IRestoreDropletApiResponse {
    action: IAction;
}
export interface IRestoreDropletApiRequest {
    droplet_id: number;
    image: string | number;
}
export type RestoreDropletResponse = IResponse<IRestoreDropletApiResponse>;
export declare const restoreDroplet: ({ httpClient, }: IContext) => ({ droplet_id, image, }: IRestoreDropletApiRequest) => Promise<Readonly<RestoreDropletResponse>>;
