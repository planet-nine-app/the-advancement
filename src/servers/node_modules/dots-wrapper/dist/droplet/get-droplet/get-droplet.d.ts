import { IResponse, IContext } from '../../types';
import { IDroplet } from '..';
export interface IGetDropletApiResponse {
    droplet: IDroplet;
}
export interface IGetDropletApiRequest {
    droplet_id: number;
}
export type GetDropletResponse = IResponse<IGetDropletApiResponse>;
export declare const getDroplet: ({ httpClient, }: IContext) => ({ droplet_id, }: IGetDropletApiRequest) => Promise<Readonly<GetDropletResponse>>;
