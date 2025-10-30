import { IResponse, IContext } from '../../types';
export interface IAddTagsToFirewallApiRequest {
    firewall_id: string;
    tags: string[];
}
export type AddTagsToFirewallResponse = IResponse<void>;
export declare const addTagsToFirewall: ({ httpClient, }: IContext) => ({ firewall_id, tags, }: IAddTagsToFirewallApiRequest) => Promise<Readonly<AddTagsToFirewallResponse>>;
