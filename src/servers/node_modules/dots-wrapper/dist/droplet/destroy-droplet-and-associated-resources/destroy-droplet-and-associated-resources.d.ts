import { IResponse, IContext } from '../../types';
export interface IdestroyDropletAndAssociatedResourcesApiRequest {
    droplet_id: number;
    snapshots: string[];
    volume_snapshots: string[];
    volumes: string[];
}
export type destroyDropletAndAssociatedResourcesResponse = IResponse<void>;
export declare const destroyDropletAndAssociatedResources: ({ httpClient, }: IContext) => ({ droplet_id, snapshots, volume_snapshots, volumes, }: IdestroyDropletAndAssociatedResourcesApiRequest) => Promise<Readonly<destroyDropletAndAssociatedResourcesResponse>>;
