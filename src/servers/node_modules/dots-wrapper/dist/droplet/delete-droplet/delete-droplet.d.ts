import { IResponse, IContext } from '../../types';
export interface IDeleteDropletApiRequest {
    droplet_id: number;
}
export type DeleteDropletResponse = IResponse<void>;
export declare const deleteDroplet: ({ httpClient, }: IContext) => ({ droplet_id, }: IDeleteDropletApiRequest) => Promise<Readonly<DeleteDropletResponse>>;
