import { IResponse, IContext } from '../../types';
export interface IdestroyDropletAndAllAssociatedResourcesApiRequest {
    acknowledge: boolean;
    droplet_id: number;
}
export type destroyDropletAndAllAssociatedResourcesResponse = IResponse<void>;
export declare const destroyDropletAndAllAssociatedResources: ({ httpClient, }: IContext) => ({ acknowledge, droplet_id, }: IdestroyDropletAndAllAssociatedResourcesApiRequest) => Promise<Readonly<destroyDropletAndAllAssociatedResourcesResponse>>;
