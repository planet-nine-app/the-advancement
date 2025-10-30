import { IResponse, IContext } from '../../types';
export interface IRemoveTagsFromFirewallApiRequest {
    firewall_id: string;
    tags: string[];
}
export type RemoveTagsFromFirewallResponse = IResponse<void>;
export declare const removeTagsFromFirewall: ({ httpClient, }: IContext) => ({ firewall_id, tags, }: IRemoveTagsFromFirewallApiRequest) => Promise<Readonly<RemoveTagsFromFirewallResponse>>;
