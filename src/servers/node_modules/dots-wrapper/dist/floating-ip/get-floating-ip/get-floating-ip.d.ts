import { IResponse, IContext } from '../../types';
import { IFloatingIP } from '..';
export interface IGetFloatingIpApiResponse {
    floating_ip: IFloatingIP;
}
export interface IGetFloatingIpApiRequest {
    ip: string;
}
export type GetFloatingIpResponse = IResponse<IGetFloatingIpApiResponse>;
export declare const getFloatingIp: ({ httpClient, }: IContext) => ({ ip, }: IGetFloatingIpApiRequest) => Promise<Readonly<GetFloatingIpResponse>>;
