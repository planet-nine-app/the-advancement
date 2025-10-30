import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IRebuildDropletApiResponse {
    action: IAction;
}
export interface IRebuildDropletApiRequest {
    droplet_id: number;
    image: string | number;
}
export type RebuildDropletResponse = IResponse<IRebuildDropletApiResponse>;
export declare const rebuildDroplet: ({ httpClient, }: IContext) => ({ droplet_id, image, }: IRebuildDropletApiRequest) => Promise<Readonly<RebuildDropletResponse>>;
