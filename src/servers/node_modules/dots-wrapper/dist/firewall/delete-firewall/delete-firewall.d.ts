import { IResponse, IContext } from '../../types';
export interface IDeleteFirewallApiRequest {
    firewall_id: string;
}
export type DeleteFirewallResponse = IResponse<void>;
export declare const deleteFirewall: ({ httpClient, }: IContext) => ({ firewall_id, }: IDeleteFirewallApiRequest) => Promise<Readonly<DeleteFirewallResponse>>;
