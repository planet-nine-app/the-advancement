import { IResponse, IContext } from '../../types';
export interface IDeleteFloatingIpApiRequest {
    ip: string;
}
export type DeleteFloatingIpResponse = IResponse<void>;
export declare const deleteFloatingIp: ({ httpClient, }: IContext) => ({ ip, }: IDeleteFloatingIpApiRequest) => Promise<Readonly<DeleteFloatingIpResponse>>;
