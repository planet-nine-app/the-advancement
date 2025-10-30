import { IResponse, IContext } from '../../types';
export interface IRemoveDropletsFromFirewallApiRequest {
    droplet_ids: number[];
    firewall_id: string;
}
export type RemoveDropletsFromFirewallResponse = IResponse<void>;
export declare const removeDropletsFromFirewall: ({ httpClient, }: IContext) => ({ droplet_ids, firewall_id, }: IRemoveDropletsFromFirewallApiRequest) => Promise<Readonly<RemoveDropletsFromFirewallResponse>>;
