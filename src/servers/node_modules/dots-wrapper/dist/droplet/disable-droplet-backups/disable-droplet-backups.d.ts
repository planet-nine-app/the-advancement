import { IResponse, IContext } from '../../types';
import { IAction } from '../../action';
export interface IDisableDropletBackupsApiResponse {
    action: IAction;
}
export interface IDisableDropletBackupsApiRequest {
    droplet_id: number;
}
export type DisableDropletBackupsResponse = IResponse<IDisableDropletBackupsApiResponse>;
export declare const disableDropletBackups: ({ httpClient, }: IContext) => ({ droplet_id, }: IDisableDropletBackupsApiRequest) => Promise<Readonly<DisableDropletBackupsResponse>>;
