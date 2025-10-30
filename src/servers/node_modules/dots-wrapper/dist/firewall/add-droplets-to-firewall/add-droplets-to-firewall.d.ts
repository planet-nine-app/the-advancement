import { IResponse, IContext } from '../../types';
export interface IAddDropletsToFirewallApiRequest {
    droplet_ids: number[];
    firewall_id: string;
}
export type AddDropletsToFirewallResponse = IResponse<void>;
export declare const addDropletsToFirewall: ({ httpClient, }: IContext) => ({ droplet_ids, firewall_id, }: IAddDropletsToFirewallApiRequest) => Promise<Readonly<AddDropletsToFirewallResponse>>;
