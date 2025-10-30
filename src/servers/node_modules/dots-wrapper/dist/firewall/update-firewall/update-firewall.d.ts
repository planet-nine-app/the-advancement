import { IResponse, IContext } from '../../types';
import { IFirewall } from '..';
export interface IUpdateFirewallApiResponse {
    firewall: IFirewall;
}
export type UpdateFirewallResponse = IResponse<IUpdateFirewallApiResponse>;
export declare const updateFirewall: ({ httpClient, }: IContext) => ({ droplet_ids, id, inbound_rules, name, outbound_rules, tags, }: IFirewall) => Promise<Readonly<UpdateFirewallResponse>>;
