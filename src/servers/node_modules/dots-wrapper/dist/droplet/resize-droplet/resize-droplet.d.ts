import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IResizeDropletApiResponse {
    action: IAction;
}
export interface IResizeDropletApiRequest {
    disk?: boolean;
    droplet_id: number;
    size: string;
}
export type ResizeDropletResponse = IResponse<IResizeDropletApiResponse>;
export declare const resizeDroplet: ({ httpClient, }: IContext) => ({ disk, droplet_id, size, }: IResizeDropletApiRequest) => Promise<Readonly<ResizeDropletResponse>>;
