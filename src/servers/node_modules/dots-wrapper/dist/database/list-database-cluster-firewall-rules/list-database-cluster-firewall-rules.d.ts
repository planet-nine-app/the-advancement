import { IResponse, IContext, IListRequest, IListResponse } from '../../types';
import { DatabaseClusterFirewallRuleType } from '..';
export interface IDatabaseClusterFirewallRule {
    type: DatabaseClusterFirewallRuleType;
    value: string;
    uuid: string;
    cluster_uuid: string;
    created_at: string;
}
export interface IListDatabaseClusterFirewallRulesApiResponse extends IListResponse {
    rules: IDatabaseClusterFirewallRule[];
}
export interface IListDatabaseClusterFirewallRulesApiRequest extends IListRequest {
    database_cluster_id: string;
}
export type ListDatabaseClusterFirewallRulesResponse = IResponse<IListDatabaseClusterFirewallRulesApiResponse>;
export declare const listDatabaseClusterFirewallRules: ({ httpClient, }: IContext) => ({ page, per_page, database_cluster_id, }: IListDatabaseClusterFirewallRulesApiRequest) => Promise<Readonly<ListDatabaseClusterFirewallRulesResponse>>;
